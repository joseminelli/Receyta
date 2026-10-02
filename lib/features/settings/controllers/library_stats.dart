import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';

/// "Seu livro em números" (aba Conta): tudo calculado do banco local.
/// [topRecipe] é a receita com mais refeições marcadas como feitas.
typedef LibraryStats = ({
  int recipes,
  int folders,
  int lists,
  int plannedMeals,
  int doneMeals,
  String? topRecipe,
  int topRecipeCount,
});

/// A receita mais cozinhada é a que mais aparece no histórico "cozinhei"
/// (G7); no empate, a que apareceu primeiro. Sem nenhum registro, não há.
({String? name, int count}) topCooked(List<CookLog> logs) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final l in logs) {
    counts[l.recipeId] = (counts[l.recipeId] ?? 0) + 1;
    names.putIfAbsent(l.recipeId, () => l.recipeName);
  }
  String? bestId;
  var best = 0;
  for (final entry in counts.entries) {
    if (entry.value > best) {
      best = entry.value;
      bestId = entry.key;
    }
  }
  return (name: bestId == null ? null : names[bestId], count: best);
}

final _allMealsProvider = StreamProvider.autoDispose<List<MealPlanEntry>>(
  (ref) => ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(DateTime(2000), DateTime(2100)),
);

final _allCookLogsProvider = StreamProvider.autoDispose<List<CookLog>>(
  (ref) => ref.watch(cookLogRepositoryProvider).watchAll(),
);

/// Junta as fontes; só fica pronto quando todas respondem.
final libraryStatsProvider = Provider.autoDispose<AsyncValue<LibraryStats>>((
  ref,
) {
  final recipes = ref.watch(allRecipesProvider);
  final folders = ref.watch(allFoldersProvider);
  final lists = ref.watch(shoppingListsProvider);
  final meals = ref.watch(_allMealsProvider);
  final cooked = ref.watch(_allCookLogsProvider);

  final error = [recipes, folders, lists, meals, cooked]
      .map((a) => a.error)
      .whereType<Object>()
      .firstOrNull;
  if (error != null) return AsyncError(error, StackTrace.current);
  if (!recipes.hasValue ||
      !folders.hasValue ||
      !lists.hasValue ||
      !meals.hasValue ||
      !cooked.hasValue) {
    return const AsyncLoading();
  }

  final entries = meals.value!;
  final top = topCooked(cooked.value!);
  return AsyncData((
    recipes: recipes.value!.length,
    folders: folders.value!.length,
    lists: lists.value!.length,
    plannedMeals: entries.length,
    doneMeals: entries.where((e) => e.done).length,
    topRecipe: top.name,
    topRecipeCount: top.count,
  ));
});
