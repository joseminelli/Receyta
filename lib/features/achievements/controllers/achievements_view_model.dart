import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/mascot/milestones.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// Lê as contagens do app uma vez ao abrir a tela e monta as conquistas. Não
/// é um stream: a tela é consultada de vez em quando, e reabrir já recarrega.
final achievementsProvider =
    FutureProvider.autoDispose<List<Achievement>>((ref) async {
  final recipes = await ref.read(recipeRepositoryProvider).watchAll().first;
  final cooked = await ref.read(cookLogRepositoryProvider).countAll();
  final meals = await ref
      .read(mealPlanRepositoryProvider)
      .watchRange(DateTime.utc(2000), DateTime.utc(2200))
      .first;
  final lists = await ref.read(shoppingListRepositoryProvider).watchAll().first;
  final prefs = await SharedPreferences.getInstance();

  return buildAchievements(
    AchievementStats(
      recipes: recipes.length,
      favorites: recipes.where((r) => r.isFavorite).length,
      cooked: cooked,
      plannedMeals: meals.length,
      shoppingLists: lists.length,
      hasHouse: ref.read(currentSpaceIdProvider) != null,
      weekPlanned: prefs.getBool(Milestone.firstWeekPlanned.key) ?? false,
    ),
  );
});
