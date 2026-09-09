import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';

/// ViewModel da home de Receitas (§5): expõe o stream de receitas ativas.
/// A criação e a edição são do [RecipeFormViewModel].
class RecipesViewModel {
  RecipesViewModel(this._repo);

  final RecipeRepository _repo;

  Stream<List<Recipe>> watchRecipes() => _repo.watchAll();
}

final recipesViewModelProvider = Provider<RecipesViewModel>(
  (ref) => RecipesViewModel(ref.watch(recipeRepositoryProvider)),
);

final recipesStreamProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipesViewModelProvider).watchRecipes(),
);
