import 'package:receyta/domain/models/recipe.dart';

/// Dados falsos só para o B2 (lista, layout). **O B3 apaga este arquivo** e
/// liga a tela no `recipeRepositoryProvider`. Algumas receitas não têm tempo
/// para exercitar o card sem número.
final List<Recipe> kSampleRecipes = () {
  final t = DateTime.utc(2026, 1, 1);
  Recipe make(
    String id,
    String name, {
    int? prep,
    int? cook,
    int? servings,
  }) {
    return Recipe(
      id: id,
      name: name,
      createdAt: t,
      updatedAt: t,
      prepMinutes: prep,
      cookMinutes: cook,
      servings: servings,
    );
  }

  return [
    make('sample-1', 'Estrogonofe de frango', prep: 15, cook: 20, servings: 4),
    make('sample-2', 'Bolo de fubá cremoso', prep: 10, cook: 45, servings: 12),
    make('sample-3', 'Lasanha à bolonhesa', prep: 30, cook: 40, servings: 8),
    make('sample-4', 'Panqueca de banana', prep: 5, cook: 10, servings: 2),
    make('sample-5', 'Feijoada completa', prep: 40, cook: 120, servings: 10),
    make('sample-6', 'Salada Caesar'),
    make('sample-7', 'Risoto de cogumelos', prep: 10, cook: 30, servings: 4),
    make('sample-8', 'Pão de queijo', prep: 15, cook: 25, servings: 20),
    make('sample-9', 'Moqueca de peixe', prep: 25, cook: 25, servings: 6),
    make('sample-10', 'Torta de limão', prep: 20, cook: 15, servings: 8),
    make('sample-11', 'Sopa de legumes', prep: 15, cook: 30, servings: 4),
    make('sample-12', 'Farofa de ovo'),
    make('sample-13', 'Frango ao curry', prep: 15, cook: 25, servings: 4),
    make('sample-14', 'Brigadeiro de panela', prep: 5, cook: 15),
  ];
}();
