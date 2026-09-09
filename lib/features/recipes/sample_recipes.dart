import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Dados falsos só para o B2 (layout da home). **O B3 apaga este arquivo** e
/// liga a tela no `recipeRepositoryProvider`.

const int kSampleRecipeCount = 84;

const List<String> kSampleFilters = [
  'Todas',
  'Massas',
  'Frango',
  'Doces',
  'Rápidas',
];

class SampleFolder {
  const SampleFolder(this.name, this.count, {this.motif});
  final String name;
  final int count;

  /// Nulo = tile neutro "ver todas as pastas".
  final TileMotif? motif;
}

const List<SampleFolder> kSampleFolders = [
  SampleFolder('Semana', 12, motif: TileMotif.meiaLua),
  SampleFolder('Da vó', 7, motif: TileMotif.arco),
  SampleFolder('Pastas', 9),
];

Recipe _make(
  String id,
  String name, {
  int? prep,
  int? cook,
  int? servings,
  bool favorite = false,
}) {
  final t = DateTime.utc(2026, 1, 1);
  return Recipe(
    id: id,
    name: name,
    createdAt: t,
    updatedAt: t,
    prepMinutes: prep,
    cookMinutes: cook,
    servings: servings,
    isFavorite: favorite,
  );
}

final Recipe kSampleFeatured = _make(
  'sample-featured',
  'Frango ao curry',
  prep: 15,
  cook: 25,
  servings: 4,
  favorite: true,
);

final List<Recipe> kSampleRecents = [
  _make('sample-1', 'Risoto de limão', prep: 10, cook: 25, servings: 4),
  _make('sample-2', 'Sopa de abóbora', prep: 15, cook: 35, servings: 6),
  _make('sample-3', 'Estrogonofe de frango', prep: 15, cook: 20, servings: 4),
  _make('sample-4', 'Bolo de fubá cremoso', prep: 10, cook: 45, servings: 12),
  _make('sample-5', 'Lasanha à bolonhesa', prep: 30, cook: 40, servings: 8),
  _make('sample-6', 'Panqueca de banana', prep: 5, cook: 10),
  _make('sample-7', 'Moqueca de peixe', prep: 25, cook: 25, servings: 6),
  _make('sample-8', 'Farofa de ovo'),
];
