import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';

/// ViewModel da home de Receitas (§5): expõe o stream de receitas ativas e o
/// comando de criar por nome. Não conhece Flutter — valida a entrada e traduz
/// nome vazio em [ValidationFailure] antes de chamar o repositório.
class RecipesViewModel {
  RecipesViewModel(this._repo);

  final RecipeRepository _repo;

  Stream<List<Recipe>> watchRecipes() => _repo.watchAll();

  Future<Result<Recipe>> createByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Err(ValidationFailure('Dê um nome à receita')));
    }
    return _repo.create(name: trimmed);
  }
}

final recipesViewModelProvider = Provider<RecipesViewModel>(
  (ref) => RecipesViewModel(ref.watch(recipeRepositoryProvider)),
);

final recipesStreamProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipesViewModelProvider).watchRecipes(),
);
