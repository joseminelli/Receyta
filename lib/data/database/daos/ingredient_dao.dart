import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/domain/engine/ingredient_normalizer.dart';

import '../app_database.dart';
import '../tables.dart';

part 'ingredient_dao.g.dart';

/// Catálogo de ingredientes (§8.2). `getOrCreate` resolve por match exato do
/// `normalized_key`, depois por alias confirmado; sem bater nenhum, cria um
/// ingrediente novo. Fuzzy match com confirmação do usuário é o C4.
@DriftAccessor(tables: [Ingredients, IngredientAliases])
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
