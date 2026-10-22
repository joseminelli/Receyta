import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/mascot/milestones.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

const _seenKey = 'achievements_seen';

/// Lê as contagens do app e monta as conquistas. Recebe o `read` do Riverpod
/// pra servir tanto ao provider quanto ao observador de novas conquistas.
Future<List<Achievement>> loadAchievements(
  T Function<T>(ProviderListenable<T> provider) read,
) async {
  final recipes = await read(recipeRepositoryProvider).watchAll().first;
  final cooked = await read(cookLogRepositoryProvider).countAll();
  final meals = await read(mealPlanRepositoryProvider)
      .watchRange(DateTime.utc(2000), DateTime.utc(2200))
      .first;
  final lists = await read(shoppingListRepositoryProvider).watchAll().first;
  final prefs = await SharedPreferences.getInstance();

  return buildAchievements(
    AchievementStats(
      recipes: recipes.length,
      favorites: recipes.where((r) => r.isFavorite).length,
      cooked: cooked,
      plannedMeals: meals.length,
      shoppingLists: lists.length,
      hasHouse: read(currentSpaceIdProvider) != null,
      weekPlanned: prefs.getBool(Milestone.firstWeekPlanned.key) ?? false,
    ),
  );
}

/// Lê as contagens uma vez ao abrir a tela; reabrir já recarrega.
final achievementsProvider = FutureProvider.autoDispose<List<Achievement>>(
    (ref) => loadAchievements(ref.read));

final _recipesSignal = StreamProvider<String>(
  (ref) => ref
      .watch(recipeRepositoryProvider)
      .watchAll()
      .map((l) => '${l.length}/${l.where((r) => r.isFavorite).length}'),
);

final _cookedSignal = StreamProvider<int>(
  (ref) => ref.watch(cookLogRepositoryProvider).watchAll().map((l) => l.length),
);

final _listsSignal = StreamProvider<int>(
  (ref) =>
      ref.watch(shoppingListRepositoryProvider).watchAll().map((l) => l.length),
);

final _mealsSignal = StreamProvider<int>(
  (ref) => ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(DateTime.utc(2000), DateTime.utc(2200))
      .map((l) => l.length),
);

/// Muda sempre que algo que alimenta as conquistas muda (receitas, favoritas,
/// histórico, agenda, listas, casa) — o observador reavalia quando isso troca.
final achievementSignalProvider = Provider<String>((ref) {
  final recipes = ref.watch(_recipesSignal).valueOrNull;
  final cooked = ref.watch(_cookedSignal).valueOrNull;
  final lists = ref.watch(_listsSignal).valueOrNull;
  final meals = ref.watch(_mealsSignal).valueOrNull;
  final house = ref.watch(currentSpaceIdProvider);
  return '$recipes|$cooked|$lists|$meals|$house';
});

/// As conquistas que acabaram de ser ganhas, ainda não mostradas. Na primeira
/// vez só registra o que já estava ganho (quem atualiza o app não leva uma
/// enxurrada de comemorações); depois, cada conquista nova é devolvida uma vez
/// e anotada como vista, mesmo que depois volte a ficar incompleta.
Future<List<Achievement>> takeNewAchievements(List<Achievement> all) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenKey);
    final unlocked = [
      for (final a in all)
        if (a.unlocked) a
    ];
    if (seen == null) {
      await prefs.setStringList(
        _seenKey,
        [for (final a in unlocked) a.id.name],
      );
      return const [];
    }
    final fresh = [
      for (final a in unlocked)
        if (!seen.contains(a.id.name)) a,
    ];
    if (fresh.isNotEmpty) {
      await prefs.setStringList(
        _seenKey,
        {...seen, for (final a in fresh) a.id.name}.toList(),
      );
    }
    return fresh;
  } catch (_) {
    return const [];
  }
}
