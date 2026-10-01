import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/shopping_list.dart';

/// Listas de compras em que a receita está (tem algum item vindo dela), ao
/// vivo — o cartão "lista de compras" do detalhe da receita.
final recipeShoppingListsProvider = StreamProvider.autoDispose
    .family<List<ShoppingList>, String>((ref, recipeId) {
  return ref
      .watch(shoppingListRepositoryProvider)
      .watchListsWithRecipe(recipeId);
});

/// Próximos agendamentos (ainda por fazer) da receita a partir de [from] —
/// o cartão "agenda". A chave leva o dia: virou o dia, recalcula.
final recipeUpcomingPlanProvider = StreamProvider.autoDispose
    .family<List<MealPlanEntry>, ({String recipeId, DateTime from})>(
        (ref, key) {
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchUpcomingForRecipe(key.recipeId, key.from);
});
