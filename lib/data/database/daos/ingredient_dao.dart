import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/domain/engine/ingredient_normalizer.dart';

import '../app_database.dart';
import '../tables.dart';

part 'ingredient_dao.g.dart';

/// Catálogo de ingredientes (§8.2). `getOrCreate` resolve por match exato do
/// `normalized_key`, depois por alias confirmado; sem bater nenhum, cria um
/// ingrediente novo. Fuzzy match com confirmação do usuário é o C4.
@DriftAccessor(
  tables: [Ingredients, IngredientAliases, RecipeIngredients, ShoppingListItems],
)
class IngredientDao extends DatabaseAccessor<AppDatabase>
    with _$IngredientDaoMixin {
  IngredientDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  Future<IngredientRow> getOrCreate(String displayName) {
    final key = normalize(displayName);
    return transaction(() async {
      final byKey = await (select(ingredients)
            ..where((i) => i.normalizedKey.equals(key)))
          .getSingleOrNull();
      if (byKey != null) return byKey;

      final aliasRow = await (select(ingredientAliases)
            ..where((a) => a.normalizedAlias.equals(key)))
          .getSingleOrNull();
      if (aliasRow != null) {
        return (select(ingredients)
              ..where((i) => i.id.equals(aliasRow.ingredientId)))
            .getSingle();
      }

      final row = IngredientRow(
        id: _uuid.v4(),
        displayName: displayName.trim(),
        normalizedKey: key,
        usageCount: 0,
      );
      await into(ingredients).insert(row);
      return row;
    });
  }

  Stream<List<IngredientRow>> watchAll() {
    return (select(ingredients)
          ..orderBy([(i) => OrderingTerm.asc(i.displayName)]))
        .watch();
  }

  /// Catálogo inteiro com quantas linhas de receita usam cada ingrediente —
  /// o que a tela de gerenciar (C6) lista.
  Stream<List<({IngredientRow ingredient, int count})>> watchAllWithCounts() {
    final count = recipeIngredients.recipeId.count();
    final query = select(ingredients).join([
      leftOuterJoin(
        recipeIngredients,
        recipeIngredients.ingredientId.equalsExp(ingredients.id),
      ),
    ])
      ..addColumns([count])
      ..groupBy([ingredients.id])
      ..orderBy([OrderingTerm.asc(ingredients.displayName)]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              (
                ingredient: row.readTable(ingredients),
                count: row.read(count) ?? 0,
              ),
          ],
        );
  }

  /// Junta [sourceId] em [targetId] (C6): reaponta as linhas de receita e de
  /// lista de compras que usavam a origem, preserva o nome e os aliases dela
  /// como aliases do destino (nunca perde a capacidade de achar por esse
  /// nome de novo) e apaga a linha de origem. `RecipeIngredients.ingredientId`
  /// é `onDelete: restrict` — por isso reapontar tem que vir antes do apagar.
  Future<void> merge(String sourceId, String targetId) {
    if (sourceId == targetId) return Future.value();
    return transaction(() async {
      final source = await (select(ingredients)
            ..where((i) => i.id.equals(sourceId)))
          .getSingleOrNull();
      if (source == null) return;

      await (update(recipeIngredients)
            ..where((i) => i.ingredientId.equals(sourceId)))
          .write(RecipeIngredientsCompanion(ingredientId: Value(targetId)));
      await (update(shoppingListItems)
            ..where((i) => i.ingredientId.equals(sourceId)))
          .write(ShoppingListItemsCompanion(ingredientId: Value(targetId)));

      final sourceAliases = await (select(ingredientAliases)
            ..where((a) => a.ingredientId.equals(sourceId)))
          .get();
      final keysToKeep = {
        source.normalizedKey,
        for (final a in sourceAliases) a.normalizedAlias,
      };
      for (final key in keysToKeep) {
        final exists = await (select(ingredientAliases)
              ..where((a) => a.normalizedAlias.equals(key)))
            .getSingleOrNull();
        if (exists == null) {
          await into(ingredientAliases).insert(
            IngredientAliasRow(
              id: _uuid.v4(),
              ingredientId: targetId,
              normalizedAlias: key,
            ),
          );
        }
      }

      await (delete(ingredients)..where((i) => i.id.equals(sourceId))).go();
    });
  }

  /// Apaga um ingrediente do catálogo (C6). `RecipeIngredients.ingredientId`
  /// é `onDelete: restrict` — se alguma receita ainda usa esse ingrediente,
  /// o banco recusa (`SqliteException`); quem chama confere a contagem de
  /// uso antes (a UI só mostra o botão de apagar pros que têm uso 0).
  Future<void> deleteIngredient(String id) {
    return (delete(ingredients)..where((i) => i.id.equals(id))).go();
  }

  /// Grava o alias confirmado pelo usuário (§8.2 passo 3) — próxima vez que
  /// esse nome aparecer, bate direto por `normalized_alias`, sem fuzzy.
  Future<void> addAlias(String ingredientId, String normalizedAlias) {
    return transaction(() async {
      final existing = await (select(ingredientAliases)
            ..where((a) => a.normalizedAlias.equals(normalizedAlias)))
          .getSingleOrNull();
      if (existing != null) return;
      await into(ingredientAliases).insert(
        IngredientAliasRow(
          id: _uuid.v4(),
          ingredientId: ingredientId,
          normalizedAlias: normalizedAlias,
        ),
      );
    });
  }
}
