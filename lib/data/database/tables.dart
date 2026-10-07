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

  /// Último acesso — criação ou abertura (§ "recentes" da home). Preenchida
  /// pela aplicação, nunca fica nula na prática; nullable só porque
  /// `addColumn` de migração não backfilla por linha sozinho (v3→v4 faz isso
  /// com um `UPDATE`, ver `app_database.dart`).
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  /// O `updated_at` que a pasta tinha quando foi sincronizada com a conta (H3).
  /// Nulo ou menor que `updated_at` = mudou desde então e precisa subir.
  DateTimeColumn get syncedAt => dateTime().nullable()();

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

  /// Nome da foto que já foi enviada pro Storage. Diferente de `imagePath` =
  /// há o que enviar (foto nova/trocada) ou o que apagar na nuvem (trocada
  /// ou removida). Nulo = nada enviado.
  TextColumn get imageSyncedPath => text().nullable()();
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

  /// Último acesso — criação ou abertura (§ "recentes" da home). Ver o
  /// comentário equivalente em `Folders`.
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  /// O `updated_at` que a receita tinha quando foi sincronizada com a conta
  /// (H3). Nulo ou menor que `updated_at` = mudou desde então e precisa subir.
  /// Abrir a receita (`last_opened_at`) e marcar a foto como enviada não mexem
  /// em `updated_at`, então não contam como mudança.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Receitas e pastas apagadas DE VEZ que a nuvem ainda precisa saber (H3).
/// Linha só nasce se o item já tinha sido sincronizado; sai quando o aviso
/// chega ao servidor.
@DataClassName('SyncTombstoneRow')
class SyncTombstones extends Table {
  /// `recipe` ou `folder`.
  TextColumn get kind => text()();
  TextColumn get id => text()();
  DateTimeColumn get deletedAt => dateTime()();

  /// Casa onde o item vivia; nulo = a conta da pessoa (v10).
  TextColumn get spaceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {kind, id};
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

  /// "Sempre tenho" (G11): ingrediente da despensa, que não entra nas listas
  /// de compras geradas.
  BoolColumn get inPantry => boolean().withDefault(const Constant(false))();

  /// Quando `in_pantry` mudou pela última vez (um gatilho do banco preenche) e
  /// o valor que já foi sincronizado com a conta (H4). Nulo = a despensa nunca
  /// foi mexida neste ingrediente, não há o que sincronizar.
  DateTimeColumn get pantryUpdatedAt => dateTime().nullable()();
  DateTimeColumn get pantrySyncedAt => dateTime().nullable()();

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

  /// Versão (`updated_at`) já sincronizada com a conta (H4); ver `Recipes`.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Casa (espaço compartilhado) a que a refeição pertence; nulo = só da
  /// pessoa. Quem tem casa sincroniza com ela, não com a conta (v10).
  TextColumn get spaceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Refeição planejada por OUTRA pessoa da casa (v11). Quem recebe pode não ter
/// a receita, então a linha carrega um resumo dela (`recipeJson`, o mesmo JSON
/// do sync). As refeições da própria pessoa ficam em `meal_plan_entries`, com
/// `space_id`; aqui só entram as dos outros.
@DataClassName('SharedMealRow')
class SharedMeals extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()();
  IntColumn get servingsOverride => integer().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get recipeJson => text()();
  TextColumn get authorId => text().withDefault(const Constant(''))();
  TextColumn get authorName => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Versão (`updated_at`) já enviada à casa; nulo = mexida aqui e ainda não
  /// enviada (marcar como feita, mover, apagar a refeição de outra pessoa).
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// "Cozinhei" (G7): uma linha por vez que a pessoa fez a receita. Apagar a
/// receita de vez leva o histórico junto. `mealPlanEntryId` liga o registro à
/// refeição planejada que o gerou (marcar como feita), pra desmarcar desfazer.
@DataClassName('CookLogRow')
class CookLogs extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().references(Recipes, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get cookedAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get mealPlanEntryId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Última mudança (um gatilho do banco preenche ao inserir e ao editar) e a
  /// versão já sincronizada com a conta (H4).
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

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

  /// Versão (`updated_at`) já sincronizada com a conta (H4).
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Casa a que a lista pertence (nulo = só da pessoa); os itens seguem a
  /// lista. Ver `MealPlanEntries.spaceId` (v10).
  TextColumn get spaceId => text().nullable()();

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

  /// Última mudança (um gatilho do banco preenche ao inserir e ao editar — o
  /// item é alterado em muitos lugares e nenhum precisa lembrar disso) e a
  /// versão já sincronizada com a conta (H4).
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  /// Quem adicionou e quem marcou o item (id da conta). Só têm valor em lista
  /// da casa: o sync preenche com a própria pessoa ao enviar e com quem veio
  /// no item ao receber (v12). Marcar ou desmarcar aqui zera `checkedBy`.
  TextColumn get addedBy => text().nullable()();
  TextColumn get checkedBy => text().nullable()();

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
