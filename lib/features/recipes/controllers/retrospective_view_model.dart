import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';

/// Tags de cada receita, lidas uma vez ao abrir a retrospectiva.
final recipeTagNamesProvider =
    FutureProvider.autoDispose<Map<String, List<String>>>(
  (ref) => ref.watch(tagRepositoryProvider).namesByRecipe(),
);

/// A retrospectiva de um mês ou ano. Pronta quando histórico, receitas e tags
/// chegaram; reage ao registrar um novo "Cozinhei!".
final retrospectiveProvider = Provider.autoDispose
    .family<AsyncValue<Retrospective>, RetroPeriod>((ref, period) {
  final logs = ref.watch(allCookLogsProvider);
  final recipes = ref.watch(allRecipesProvider);
  final tags = ref.watch(recipeTagNamesProvider);

  final error =
      [logs, recipes, tags].map((a) => a.error).whereType<Object>().firstOrNull;
  if (error != null) return AsyncError(error, StackTrace.current);
  if (!logs.hasValue || !recipes.hasValue || !tags.hasValue) {
    return const AsyncLoading();
  }

  final tagNames = tags.value!;
  final byId = {
    for (final r in recipes.value!)
      r.id: RetroRecipe(
        id: r.id,
        name: r.name,
        createdAt: r.createdAt,
        minutes: (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0),
        tags: tagNames[r.id] ?? const [],
        tileColor: r.tileColor,
        tileMotif: r.tileMotif,
      ),
  };
  return AsyncData(
    buildRetrospective(period: period, logs: logs.value!, recipes: byId),
  );
});
