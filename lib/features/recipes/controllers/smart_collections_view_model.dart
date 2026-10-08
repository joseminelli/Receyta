import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';

/// Relógio das coleções ("esquecidas" depende de quanto tempo passou); os
/// testes trocam por um fixo.
final smartCollectionsClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// As coleções que têm receita hoje, recalculadas quando receitas ou
/// histórico mudam.
final smartCollectionsProvider =
    Provider.autoDispose<Map<SmartCollection, List<Recipe>>>((ref) {
  final recipes = ref.watch(allRecipesProvider).valueOrNull;
  if (recipes == null) return const {};
  final logs = ref.watch(allCookLogsProvider).valueOrNull ?? const [];
  return buildSmartCollections(
    recipes,
    logs,
    ref.watch(smartCollectionsClockProvider)(),
  );
});
