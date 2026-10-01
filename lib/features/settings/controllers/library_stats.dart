import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/meal_plan_repository.dart';
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

/// A receita mais cozinhada é a que mais aparece em refeições marcadas como
/// feitas; no empate, a que apareceu primeiro. Sem nenhuma feita, não há.
({String? name, int count}) topCooked(List<MealPlanEntry> entries) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final e in entries) {
    if (!e.done) continue;
    counts[e.recipe.id] = (counts[e.recipe.id] ?? 0) + 1;
    names.putIfAbsent(e.recipe.id, () => e.recipe.name);
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

/// Junta as quatro fontes; só fica pronto quando todas respondem.
final libraryStatsProvider = Provider.autoDispose<AsyncValue<LibraryStats>>((
  ref,
) {
  final recipes = ref.watch(allRecipesProvider);
  final folders = ref.watch(allFoldersProvider);
  final lists = ref.watch(shoppingListsProvider);
  final meals = ref.watch(_allMealsProvider);

  final error = [recipes, folders, lists, meals]
      .map((a) => a.error)
      .whereType<Object>()
      .firstOrNull;
  if (error != null) return AsyncError(error, StackTrace.current);
  if (!recipes.hasValue ||
      !folders.hasValue ||
      !lists.hasValue ||
      !meals.hasValue) {
    return const AsyncLoading();
  }

  final entries = meals.value!;
  final top = topCooked(entries);
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
