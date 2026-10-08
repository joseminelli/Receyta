import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/recipe_similarity.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';

/// Monta as sugestões do dia (RF-04.4, §8.3): junta o plano ao redor do dia
/// com o catálogo de receitas e roda o motor de similaridade (F4).
///
/// - **Alvo**: ingredientes das refeições ainda por fazer da *semana* do dia
///   — o que você já vai comprar.
/// - **Fora**: receitas que já estão na semana (feitas ou não).
/// - **Penalizadas**: as agendadas por perto, 14 dias pra cada lado.
class PlannerSuggestionService {
  PlannerSuggestionService(this._recipeDao, this._ingredientDao);

  final RecipeDao _recipeDao;
  final IngredientDao _ingredientDao;

  /// [window] são as refeições agendadas ao redor de [day] (pelo menos 14
  /// dias pra cada lado). Vazia quando não há nada pendente na semana.
  Future<List<PlannerSuggestion>> suggestionsFor(
    DateTime day,
    List<MealPlanEntry> window, {
    int limit = 3,
  }) async {
    final monday = mondayOf(day);
    final nextMonday = addDays(monday, 7);
    final week = [
      for (final e in window)
        if (!e.date.isBefore(monday) && e.date.isBefore(nextMonday)) e,
    ];
    final pendingIds = {
      for (final e in week)
        if (!e.done) e.recipeId,
    };
    if (pendingIds.isEmpty) return const [];

    final catalog = await _recipeDao.activeIngredientSets();
    final target = {
      for (final id in pendingIds) ...?catalog[id],
    };
    if (target.isEmpty) return const [];

    final lastScheduled = <String, DateTime>{};
    for (final e in window) {
      lastScheduled.update(
        e.recipeId,
        (d) => e.date.isAfter(d) ? e.date : d,
        ifAbsent: () => e.date,
      );
    }

    final raw = suggestRecipes(
      catalog: catalog,
      target: target,
      excludeRecipeIds: {for (final e in week) e.recipeId},
      lastScheduled: lastScheduled,
      now: day,
      limit: limit,
    );
    return _hydrate(raw);
  }

  /// Outras receitas suas que dividem ingredientes com [recipeId] (a seção
  /// "Parecidas" do detalhe). Exige pelo menos [minShared] em comum, pra não
  /// sugerir só porque as duas levam o mesmo ingrediente corriqueiro.
  Future<List<PlannerSuggestion>> similarTo(
    String recipeId, {
    int limit = 4,
    int minShared = 2,
  }) async {
    final catalog = await _recipeDao.activeIngredientSets();
    final target = catalog[recipeId];
    if (target == null || target.length < minShared) return const [];

    final raw = suggestRecipes(
      catalog: catalog,
      target: target,
      excludeRecipeIds: {recipeId},
      now: DateTime.now(),
      limit: catalog.length,
    );
    return _hydrate([
      for (final s in raw)
        if (s.sharedIngredientIds.length >= minShared) s,
    ].take(limit).toList());
  }

  Future<List<PlannerSuggestion>> _hydrate(List<RecipeSuggestion> raw) async {
    if (raw.isEmpty) return const [];

    final recipes = {
      for (final r in await _recipeDao.findByIds([
        for (final s in raw) s.recipeId,
      ]))
        r.id: recipeFromRow(r),
    };
    final names = {
      for (final i in await _ingredientDao.findByIds([
        for (final s in raw) ...s.sharedIngredientIds,
      ]))
        i.id: i.displayName,
    };

    return [
      for (final s in raw)
        if (recipes[s.recipeId] != null)
          PlannerSuggestion(
            recipe: recipes[s.recipeId]!,
            score: s.score,
            sharedIngredientNames: [
              for (final id in s.sharedIngredientIds)
                if (names[id] != null) names[id]!,
            ],
          ),
    ];
  }
}

final plannerSuggestionServiceProvider = Provider<PlannerSuggestionService>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return PlannerSuggestionService(db.recipeDao, db.ingredientDao);
});
