import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/mascot/milestones.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

const _seenKey = 'achievements_seen_levels';

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

/// As conquistas que acabaram de subir de nível (ou de ser ganhas), ainda não
/// mostradas — uma por conquista, no nível mais alto atingido. Na primeira vez
/// só registra os níveis que já estavam ganhos (quem atualiza o app não leva
/// uma enxurrada de comemorações); depois, cada nível novo é devolvido uma vez
/// e anotado como visto, mesmo que depois a contagem volte a cair.
Future<List<Achievement>> takeNewAchievements(List<Achievement> all) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_seenKey);
    final levels = {for (final a in all) a.id.name: a.level};
    if (stored == null) {
      await prefs.setStringList(_seenKey, _encode(levels));
      return const [];
    }
    final seen = <String, int>{};
    for (final entry in stored) {
      final parts = entry.split(':');
      if (parts.length == 2) seen[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    final fresh = [
      for (final a in all)
        if (a.level > (seen[a.id.name] ?? 0)) a,
    ];
    if (fresh.isNotEmpty) {
      final merged = {...seen};
      for (final a in fresh) {
        merged[a.id.name] = a.level;
      }
      await prefs.setStringList(_seenKey, _encode(merged));
    }
    return fresh;
  } catch (_) {
    return const [];
  }
}

List<String> _encode(Map<String, int> levels) =>
    [for (final e in levels.entries) '${e.key}:${e.value}'];
