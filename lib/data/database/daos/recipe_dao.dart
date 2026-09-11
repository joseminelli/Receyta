import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recipe_dao.g.dart';

/// Acesso bruto ao agregado receita (§5: "Service"): a linha em `recipes` e
/// suas listas em `recipe_ingredients` / `recipe_steps` / `recipe_tags`. Só
/// linhas ativas — o soft delete do §RF-01.6 é escondido aqui, não no
/// repositório. O catálogo de tags (getOrCreate por nome) fica na [TagDao].
@DriftAccessor(tables: [Recipes, RecipeIngredients, RecipeSteps, Tags, RecipeTags])
class RecipeDao extends DatabaseAccessor<AppDatabase> with _$RecipeDaoMixin {
  RecipeDao(super.db);

  Stream<List<RecipeRow>> watchActive({
    Set<String> anyOfTagIds = const {},
    bool favoritesOnly = false,
    bool rootOnly = false,
  }) {
    final query = select(recipes)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
    if (rootOnly) {
      query.where((r) => r.folderId.isNull());
    }
    if (favoritesOnly) {
      query.where((r) => r.isFavorite.equals(true));
    }
    if (anyOfTagIds.isNotEmpty) {
      query.where(
        (r) => existsQuery(
          select(recipeTags)
            ..where(
              (rt) =>
                  rt.recipeId.equalsExp(r.id) & rt.tagId.isIn(anyOfTagIds),
            ),
        ),
      );
    }
    return query.watch();
  }

  /// Busca por nome, sobre e notas (FTS5) e por nome de tag (§RF-01.9). Cada
  /// termo vira prefixo (`curry` acha "curry ao forno"). Query vazia → nada.
  Stream<List<RecipeRow>> search(String query) {
    final trimmed = query.trim();
    final terms = trimmed
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll('"', '').trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return Stream.value(const []);

    final match = terms.map((t) => '"$t"*').join(' ');
    final like = '%${trimmed.replaceAll(RegExp(r'[%_\\]'), r'\$0')}%';

    return customSelect(
      'SELECT r.* FROM recipes r '
      'WHERE r.deleted_at IS NULL AND ('
      '  r.rowid IN (SELECT rowid FROM recipes_fts WHERE recipes_fts MATCH ?1)'
      '  OR r.id IN ('
      '    SELECT rt.recipe_id FROM recipe_tags rt '
      '    JOIN tags t ON t.id = rt.tag_id '
      "    WHERE t.name LIKE ?2 ESCAPE '\\'"
      '  )'
      ') ORDER BY r.updated_at DESC',
      variables: [Variable<String>(match), Variable<String>(like)],
      readsFrom: {recipes, recipeTags, tags},
    ).map((row) => recipes.map(row.data)).watch();
  }

  Future<List<TagRow>> tagsOf(String recipeId) {
    final query = select(tags).join([
      innerJoin(recipeTags, recipeTags.tagId.equalsExp(tags.id)),
    ])
      ..where(recipeTags.recipeId.equals(recipeId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.map((row) => row.readTable(tags)).get();
  }

  Stream<RecipeRow?> watchById(String id) {
    return (select(recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .watchSingleOrNull();
  }

  Future<RecipeRow?> findById(String id) {
    return (select(recipes)
          ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<List<RecipeIngredientRow>> ingredientsOf(String recipeId) {
    return (select(recipeIngredients)
          ..where((i) => i.recipeId.equals(recipeId))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
  }

  Future<List<RecipeStepRow>> stepsOf(String recipeId) {
    return (select(recipeSteps)
          ..where((s) => s.recipeId.equals(recipeId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  Future<void> upsert(RecipeRow row) =>
      into(recipes).insertOnConflictUpdate(row);

  /// Grava a receita e substitui suas listas numa transação — a UI edita
  /// ingredientes, passos e tags por reposição total, não por diff. As linhas
  /// de `tags` já têm que existir (a [TagRepository] resolve os nomes antes).
  Future<void> saveWithChildren({
    required RecipeRow recipe,
    required List<RecipeIngredientRow> ingredients,
    required List<RecipeStepRow> steps,
    List<String> tagIds = const [],
  }) {
    return transaction(() async {
      await into(recipes).insertOnConflictUpdate(recipe);
      await (delete(recipeIngredients)
            ..where((i) => i.recipeId.equals(recipe.id)))
          .go();
      await (delete(recipeSteps)..where((s) => s.recipeId.equals(recipe.id)))
          .go();
      await (delete(recipeTags)..where((t) => t.recipeId.equals(recipe.id)))
          .go();
      await batch((b) {
        b.insertAll(recipeIngredients, ingredients);
        b.insertAll(recipeSteps, steps);
        b.insertAll(recipeTags, [
          for (final tagId in tagIds)
            RecipeTagRow(recipeId: recipe.id, tagId: tagId),
        ]);
      });
    });
  }

  /// Receitas ativas de uma pasta (por `folderId`); nulo = as soltas na raiz.
  Stream<List<RecipeRow>> watchInFolder(String? folderId) {
    return (select(recipes)
          ..where((r) =>
              r.deletedAt.isNull() &
              (folderId == null
                  ? r.folderId.isNull()
                  : r.folderId.equals(folderId)))
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
  }

  Future<int> setFolder(String id, String? folderId, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(folderId: Value(folderId), updatedAt: Value(at)),
    );
  }

  Future<int> setFavorite(String id, bool value, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(isFavorite: Value(value), updatedAt: Value(at)),
    );
  }

  /// `color`/`motif` são o `.name` do enum, ou nulo pra voltar ao automático.
  Future<int> setAppearance(
    String id, {
    required String? color,
    required String? motif,
    required DateTime at,
  }) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        tileColor: Value(color),
        tileMotif: Value(motif),
        updatedAt: Value(at),
      ),
    );
  }

  Future<int> setLastOpenedAt(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id)))
        .write(RecipesCompanion(lastOpenedAt: Value(at)));
  }

  /// As 7 mais recentes (criação ou abertura), só as soltas na raiz — as de
  /// dentro de pasta são acessadas por lá, não pela prateleira da home.
  Stream<List<RecipeRow>> watchRecent({int limit = 7}) {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNull() & r.folderId.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.lastOpenedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> softDelete(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }

  /// Linhas na lixeira (RF-01.6), da mais recente pra mais antiga.
  Stream<List<RecipeRow>> watchTrashed() {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNotNull())
          ..orderBy([(r) => OrderingTerm.desc(r.deletedAt)]))
        .watch();
  }

  Future<int> restore(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: const Value(null), updatedAt: Value(at)),
    );
  }

  /// Apaga de verdade — o cascade leva ingredientes, passos e vínculos de tag.
  Future<int> hardDelete(String id) {
    return (delete(recipes)..where((r) => r.id.equals(id))).go();
  }

  /// Esvazia da lixeira tudo que passou do prazo. Roda no boot.
  Future<int> purgeExpired(DateTime cutoff) {
    return (delete(recipes)
          ..where((r) =>
              r.deletedAt.isNotNull() &
              r.deletedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
