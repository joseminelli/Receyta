import 'package:drift/drift.dart';

/// Schema v1 do banco local (§6 do plano). Definição em Dart puro; índices,
/// FTS5 e triggers entram como SQL no `onCreate` de `AppDatabase`. IDs são
/// sempre `TEXT`: UUID para linhas do usuário, slug para linhas de seed.

@DataClassName('FolderRow')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentId =>
      text().nullable().customConstraint('NULL REFERENCES folders (id)')();
  TextColumn get name => text()();

  /// Cor e módulo do azulejo escolhidos (§9.4). Nulo = aparência padrão
  /// (violet/meia-lua). Guardados como o `.name` do enum.
  TextColumn get tileColor => text().nullable()();
  TextColumn get tileMotif => text().nullable()();

  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeRow')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get folderId =>
      text().nullable().references(Folders, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get cookMinutes => integer().nullable()();
  IntColumn get servings => integer().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get notes => text().nullable()();

  /// Cor e módulo do azulejo escolhidos (§9.4). Nulo = deriva do id, como
  /// sempre. Guardados como o `.name` do enum.
  TextColumn get tileColor => text().nullable()();
  TextColumn get tileMotif => text().nullable()();

  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Corredores do mercado, na ordem de percurso. Seed em `seed_data.dart`.
@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('IngredientRow')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get normalizedKey => text().unique()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grafias alternativas de um ingrediente, confirmadas pelo usuário (§8.2).
@DataClassName('IngredientAliasRow')
class IngredientAliases extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId =>
      text().references(Ingredients, #id, onDelete: KeyAction.cascade)();
  TextColumn get normalizedAlias => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Unidades de medida em pt-BR. `kind`: mass | volume | count | subjective.
/// `baseUnitId`/`factorToBase` só existem em massa e volume. Seed em
/// `seed_data.dart`.
@DataClassName('UnitRow')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get plural => text()();
  TextColumn get kind => text()();
  TextColumn get baseUnitId =>
      text().nullable().customConstraint('NULL REFERENCES units (id)')();
  RealColumn get factorToBase => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// `rawText` é a fonte de verdade se o parsing falhar (§8.1). `ingredientId`
/// nasce nulo no bloco B (texto livre) e é preenchido pela normalização (C5).
@DataClassName('RecipeIngredientRow')
class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get ingredientId => text()
      .nullable()
      .references(Ingredients, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId =>
      text().nullable().references(Units, #id, onDelete: KeyAction.setNull)();
  TextColumn get qualifier => text().nullable()();
  TextColumn get rawText => text()();
  TextColumn get groupLabel => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Getter `instruction`, não `text` — este colide com o construtor de coluna
/// do drift e quebra o codegen.
@DataClassName('RecipeStepRow')
class RecipeSteps extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get instruction => text()();
  TextColumn get groupLabel => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TagRow')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeTagRow')
class RecipeTags extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {recipeId, tagId};
}

@DataClassName('MealPlanEntryRow')
class MealPlanEntries extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()();
  IntColumn get servingsOverride => integer().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShoppingListRow')
class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// `manualName` guarda item avulso, sem ingrediente do catálogo (§RF-05.6).
@DataClassName('ShoppingListItemRow')
class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get ingredientId => text()
      .nullable()
      .references(Ingredients, #id, onDelete: KeyAction.setNull)();
  TextColumn get manualName => text().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId =>
      text().nullable().references(Units, #id, onDelete: KeyAction.setNull)();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// De quais receitas veio cada item da lista (§RF-05.8).
@DataClassName('ShoppingItemSourceRow')
class ShoppingItemSources extends Table {
  TextColumn get itemId =>
      text().references(ShoppingListItems, #id, onDelete: KeyAction.cascade)();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId =>
      text().nullable().references(Units, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column> get primaryKey => {itemId, recipeId};
}

/// Vocabulário do normalizador de ingredientes (§8.2). Extensão do modelo do
/// §6. `kind`: stopword | qualifier. O engine (Dart puro, §5) lê via
/// repositório e recebe as listas por parâmetro.
@DataClassName('NormalizerTermRow')
class NormalizerTerms extends Table {
  TextColumn get id => text()();
  TextColumn get term => text().unique()();
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};
}
