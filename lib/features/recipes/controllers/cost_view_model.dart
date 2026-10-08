import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';

/// Catálogo por id — a conta de custo procura o preço aqui. Reage a qualquer
/// preço informado ou removido.
final ingredientCatalogProvider =
    Provider.autoDispose<Map<String, Ingredient>>((ref) {
  final all = ref.watch(allIngredientsProvider).valueOrNull ?? const [];
  return {for (final i in all) i.id: i};
});

/// Custo da receita como está escrita. Nulo enquanto a receita não chegou.
final recipeCostProvider =
    Provider.autoDispose.family<RecipeCost?, String>((ref, recipeId) {
  final detail = ref.watch(recipeDetailProvider(recipeId)).valueOrNull;
  if (detail == null) return null;
  return costOfRecipe(detail.ingredients, ref.watch(ingredientCatalogProvider));
});

enum CostKind { week, month }

/// Uma semana (segunda a domingo) ou um mês de calendário.
@immutable
class CostPeriod {
  const CostPeriod(this.kind, this.start);

  factory CostPeriod.weekOf(DateTime day) =>
      CostPeriod(CostKind.week, mondayOf(day));

  factory CostPeriod.monthOf(DateTime day) =>
      CostPeriod(CostKind.month, firstOfMonth(day));

  final CostKind kind;

  /// Dia de calendário (UTC) do primeiro dia.
  final DateTime start;

  /// Primeiro dia depois do período.
  DateTime get end => kind == CostKind.week
      ? addDays(start, 7)
      : DateTime.utc(start.year, start.month + 1);

  CostPeriod shift(int n) => kind == CostKind.week
      ? CostPeriod(kind, addDays(start, 7 * n))
      : CostPeriod(kind, addMonths(start, n));

  CostPeriod containing(DateTime day) =>
      kind == CostKind.week ? CostPeriod.weekOf(day) : CostPeriod.monthOf(day);

  @override
  bool operator ==(Object other) =>
      other is CostPeriod && other.kind == kind && other.start == start;

  @override
  int get hashCode => Object.hash(kind, start);
}

/// Quanto custam as refeições planejadas no período. Refeição de outra pessoa
/// da casa fica de fora (a receita não é da biblioteca daqui); porções
/// planejadas diferentes das da receita escalam a conta.
final planCostProvider = FutureProvider.autoDispose
    .family<PlanCost, CostPeriod>((ref, period) async {
  final catalog = ref.watch(ingredientCatalogProvider);
  final entries = await ref
      .read(mealPlanRepositoryProvider)
      .watchRange(period.start, period.end)
      .first;
  final recipes = ref.read(recipeRepositoryProvider);

  final details = <String, RecipeDetail?>{};
  final planned = <PlannedRecipe>[];
  for (final e in entries) {
    if (e.isFromOther) continue;
    if (!details.containsKey(e.recipeId)) {
      details[e.recipeId] = (await recipes.getDetail(e.recipeId)).valueOrNull;
    }
    final detail = details[e.recipeId];
    if (detail == null) continue;
    final servings = e.recipe.servings;
    final override = e.servingsOverride;
    final factor = (override != null && servings != null && servings > 0)
        ? override / servings
        : 1.0;
    planned.add(PlannedRecipe(
      recipeId: e.recipeId,
      name: e.recipeName,
      lines: detail.ingredients,
      factor: factor,
    ));
  }
  return costOfPlan(planned, catalog);
});
