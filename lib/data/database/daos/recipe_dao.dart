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

  Stream<List<RecipeRow>> watchActive({Set<String> anyOfTagIds = const {}}) {
    final query = select(recipes)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]);
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

  Future<int> softDelete(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }
}
