import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/pantry_match.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';

/// Relógio das coleções ("esquecidas" depende de quanto tempo passou); os
/// testes trocam por um fixo.
final smartCollectionsClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Receitas que a despensa quase cobre (id da receita → quanto falta).
/// Recalcula quando receitas ou despensa mudam; despensa vazia = nada.
final pantryMatchesProvider =
    FutureProvider.autoDispose<Map<String, PantryMatch>>((ref) async {
  final recipes = await ref.watch(allRecipesProvider.future);
  final catalog = ref.watch(ingredientCatalogProvider);
  final pantry = {
    for (final i in catalog.values)
      if (i.inPantry) i.id,
  };
  if (pantry.isEmpty || recipes.isEmpty) return const {};

  final lines = await ref
      .read(recipeRepositoryProvider)
      .ingredientsByRecipe([for (final r in recipes) r.id]);
  return matchPantry({
    for (final e in lines.entries)
      e.key: {
        for (final l in e.value)
          if (l.ingredientId != null) l.ingredientId!,
      },
  }, pantry);
});

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
    pantry: ref.watch(pantryMatchesProvider).valueOrNull ?? const {},
  );
});
