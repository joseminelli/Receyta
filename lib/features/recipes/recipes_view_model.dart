import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';

/// ViewModel da home de Receitas (§5): expõe o stream de receitas ativas,
/// opcionalmente filtrado pelas tags escolhidas na lista horizontal. A criação
/// e a edição são do [RecipeFormViewModel].
class RecipesViewModel {
  RecipesViewModel(this._repo);

  final RecipeRepository _repo;

  /// Sem tags → todas as receitas. Com tags → as que têm pelo menos uma delas
  /// (filtro OU, §RF-01.10).
  Stream<List<Recipe>> watchRecipes({Set<String> tagIds = const {}}) =>
      _repo.watchAll(anyOfTagIds: tagIds);
}

final recipesViewModelProvider = Provider<RecipesViewModel>(
  (ref) => RecipesViewModel(ref.watch(recipeRepositoryProvider)),
);

/// Ids das tags marcadas no filtro da home. Vazio = filtro desligado.
final selectedTagIdsProvider = StateProvider<Set<String>>((ref) => const {});

/// Tags que aparecem na lista horizontal — só as presas a alguma receita ativa.
final inUseTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchInUse(),
);

final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final tagIds = ref.watch(selectedTagIdsProvider);
  return ref.watch(recipesViewModelProvider).watchRecipes(tagIds: tagIds);
});
