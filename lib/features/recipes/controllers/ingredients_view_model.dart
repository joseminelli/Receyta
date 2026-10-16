import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/ingredient.dart';

/// Catálogo inteiro com contagem de uso — a tela de gerenciar ingredientes
/// (C6) lista daqui.
final ingredientsWithCountsProvider = StreamProvider<List<IngredientWithCount>>(
  (ref) => ref.watch(ingredientRepositoryProvider).watchAllWithCounts(),
);

/// As receitas que usam um ingrediente — a folha "ver receitas" da tela de
/// gerenciar.
final recipesUsingIngredientProvider = FutureProvider.autoDispose
    .family<List<({String id, String name, bool inTrash})>, String>(
  (ref, ingredientId) async {
    final result = await ref
        .read(recipeRepositoryProvider)
        .recipesUsingIngredient(ingredientId);
    return result.when(ok: (rows) => rows, err: (f) => throw f);
  },
);
