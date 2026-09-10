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
  /// (filtro OU, §RF-01.10). `favoritesOnly` corta o resultado às favoritas.
  Stream<List<Recipe>> watchRecipes({
    Set<String> tagIds = const {},
    bool favoritesOnly = false,
  }) =>
      _repo.watchAll(anyOfTagIds: tagIds, favoritesOnly: favoritesOnly);
}

final recipesViewModelProvider = Provider<RecipesViewModel>(
  (ref) => RecipesViewModel(ref.watch(recipeRepositoryProvider)),
);

/// Ids das tags marcadas no filtro da home. Vazio = filtro de tag desligado.
final selectedTagIdsProvider = StateProvider<Set<String>>((ref) => const {});

/// Chip "Favoritos" do filtro ligado — corta a lista às favoritas.
final favoritesOnlyProvider = StateProvider<bool>((ref) => false);

/// Tags que aparecem na lista horizontal — só as presas a alguma receita ativa.
final inUseTagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchInUse(),
);

/// Todas as tags com contagem de receitas — a tela de gerenciar tags mostra
/// até as não usadas, pra poder apagá-las (§RF-01.10).
final tagsWithCountsProvider = StreamProvider<List<({Tag tag, int count})>>(
  (ref) => ref.watch(tagRepositoryProvider).watchAllWithCounts(),
);

/// Tem alguma favorita? Decide se o chip "Favoritos" entra no filtro.
final hasFavoritesProvider = StreamProvider<bool>(
  (ref) => ref.watch(recipeRepositoryProvider).watchHasFavorites(),
);

final recipesStreamProvider = StreamProvider<List<Recipe>>((ref) {
  final tagIds = ref.watch(selectedTagIdsProvider);
  final favoritesOnly = ref.watch(favoritesOnlyProvider);
  return ref
      .watch(recipesViewModelProvider)
      .watchRecipes(tagIds: tagIds, favoritesOnly: favoritesOnly);
});

/// Receitas na lixeira (RF-01.6), da mais recente pra mais antiga.
final trashedRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchTrashed(),
);

/// Todas as receitas ativas, sem filtro — a tela de busca mostra elas enquanto
/// o campo está vazio.
final allRecipesProvider = StreamProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).watchAll(),
);

/// Texto da busca (§RF-01.9). `autoDispose`: zera ao sair da tela de busca.
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Resultados da busca por nome, sobre, notas e tag. Query vazia → vazio.
final searchResultsProvider = StreamProvider.autoDispose<List<Recipe>>((ref) {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return Stream.value(const []);
  return ref.watch(recipeRepositoryProvider).search(query);
});
