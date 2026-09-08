import 'package:drift/drift.dart';

/// Schema v1 do banco local (§6 do plano).
///
/// Definição em Dart puro — sem arquivos `.drift`. Índices, FTS5 e triggers
/// entram como SQL cru no `onCreate` de [AppDatabase]. Todas as tabelas
/// sincronizáveis já nascem com `updated_at` para não doer quando o sync chegar.
///
/// IDs são sempre `TEXT`: UUID para linhas criadas pelo usuário, slug
/// determinístico para linhas de seed (ver `seed_data.dart`).

@DataClassName('Folder')
class Folders extends Table {
  TextColumn get id => text()();

  /// Subpasta: aponta para outra pasta. `NULL` = raiz.
  TextColumn get parentId =>
      text().nullable().customConstraint('NULL REFERENCES folders (id)')();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Recipe')
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get folderId => text()
      .nullable()
      .references(Folders, #id, onDelete: KeyAction.setNull)();
  TextColumn get name => text()();
  TextColumn get about => text().nullable()();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get cookMinutes => integer().nullable()();
  IntColumn get servings => integer().nullable()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Corredores do mercado, na ordem de percurso. Seed em `seed_data.dart`.
@DataClassName('Category')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Ingredient')
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();

  /// Chave canônica do §8.2 (minúsculo, sem acento, sem qualificador, singular).
  TextColumn get normalizedKey => text().unique()();
  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Grafias alternativas confirmadas pelo usuário (§8.2, passo 3).
@DataClassName('IngredientAlias')
class IngredientAliases extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId =>
      text().references(Ingredients, #id, onDelete: KeyAction.cascade)();
  TextColumn get normalizedAlias => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Unidades de medida em pt-BR. Seed em `seed_data.dart`.
@DataClassName('Unit')
class Units extends Table {
  TextColumn get id => text()();
  TextColumn get code => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get plural => text()();

  /// `mass` | `volume` | `count` | `subjective`.
  TextColumn get kind => text()();

  /// Unidade-base da mesma família (`g` para massa, `ml` para volume).
  /// `NULL` para as próprias bases e para `count`/`subjective`.
  TextColumn get baseUnitId =>
      text().nullable().customConstraint('NULL REFERENCES units (id)')();

  /// Fator de conversão para [baseUnitId]. `NULL` quando não há base.
  RealColumn get factorToBase => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeIngredient')
class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get ingredientId =>
      text().references(Ingredients, #id, onDelete: KeyAction.restrict)();
  RealColumn get quantity => real().nullable()();
  TextColumn get unitId =>
      text().nullable().references(Units, #id, onDelete: KeyAction.setNull)();
  TextColumn get qualifier => text().nullable()();

  /// Linha original digitada — fonte de verdade se o parsing falhar (§8.1).
  TextColumn get rawText => text()();
  TextColumn get groupLabel => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeStep')
class RecipeSteps extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// Texto do passo. (Getter `instruction` e não `text` — este último colide
  /// com o construtor de coluna do drift e quebra o codegen.)
  TextColumn get instruction => text()();
  TextColumn get groupLabel => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecipeTag')
class RecipeTags extends Table {
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {recipeId, tagId};
}

@DataClassName('MealPlanEntry')
class MealPlanEntries extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();

  /// Dia planejado (a hora é ignorada).
  DateTimeColumn get date => dateTime()();

  /// `breakfast` | `lunch` | `dinner` | `snack`.
  TextColumn get mealType => text()();
  IntColumn get servingsOverride => integer().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShoppingList')
class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// `active` | `archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ShoppingListItem')
class ShoppingListItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get ingredientId => text()
      .nullable()
      .references(Ingredients, #id, onDelete: KeyAction.setNull)();

  /// Item avulso, sem ingrediente do catálogo (§RF-05.6).
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
@DataClassName('ShoppingItemSource')
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

/// Vocabulário do normalizador de ingredientes (§8.2).
///
/// Extensão deliberada do modelo do §6: o parser/normalizer (Dart puro, sem
/// Drift — §5) lê estas linhas via repositório e recebe as listas por
/// parâmetro, então o engine continua testável isoladamente.
@DataClassName('NormalizerTerm')
class NormalizerTerms extends Table {
  TextColumn get id => text()();
  TextColumn get term => text().unique()();

  /// `stopword` (conectivo/ruído, some no nome) | `qualifier` (estado/preparo,
  /// vira o campo `qualifier` de `recipe_ingredients`).
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {id};
}
