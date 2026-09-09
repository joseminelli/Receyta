import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'recipe_dao.g.dart';

/// Acesso bruto ao agregado receita (§5: "Service"): a linha em `recipes` e
/// suas listas em `recipe_ingredients` / `recipe_steps`. Só linhas ativas — o
/// soft delete do §RF-01.6 é escondido aqui, não no repositório.
@DriftAccessor(tables: [Recipes, RecipeIngredients, RecipeSteps])
class RecipeDao extends DatabaseAccessor<AppDatabase> with _$RecipeDaoMixin {
  RecipeDao(super.db);

  Stream<List<RecipeRow>> watchActive() {
    return (select(recipes)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
        .watch();
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
  /// ingredientes e passos por reposição total, não por diff.
  Future<void> saveWithChildren({
    required RecipeRow recipe,
    required List<RecipeIngredientRow> ingredients,
    required List<RecipeStepRow> steps,
  }) {
    return transaction(() async {
      await into(recipes).insertOnConflictUpdate(recipe);
      await (delete(recipeIngredients)
            ..where((i) => i.recipeId.equals(recipe.id)))
          .go();
      await (delete(recipeSteps)..where((s) => s.recipeId.equals(recipe.id)))
          .go();
      await batch((b) {
        b.insertAll(recipeIngredients, ingredients);
        b.insertAll(recipeSteps, steps);
      });
    });
  }

  Future<int> softDelete(String id, DateTime at) {
    return (update(recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(deletedAt: Value(at), updatedAt: Value(at)),
    );
  }
}
