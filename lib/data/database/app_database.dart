import 'package:drift/drift.dart';

import 'connection.dart';
import 'daos/cook_log_dao.dart';
import 'daos/folder_dao.dart';
import 'daos/ingredient_dao.dart';
import 'daos/meal_plan_dao.dart';
import 'daos/recipe_dao.dart';
import 'daos/shopping_list_dao.dart';
import 'daos/tag_dao.dart';
import 'seed_data.dart';
import 'tables.dart';

part 'app_database.g.dart';

const List<String> _indexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_recipes_folder_id ON recipes (folder_id)',
  'CREATE INDEX IF NOT EXISTS idx_recipes_name ON recipes (name)',
  'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id '
      'ON recipe_ingredients (recipe_id)',
  'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_ingredient_id '
      'ON recipe_ingredients (ingredient_id)',
  'CREATE INDEX IF NOT EXISTS idx_meal_plan_entries_date '
      'ON meal_plan_entries (date)',
  'CREATE INDEX IF NOT EXISTS idx_cook_logs_recipe_id '
      'ON cook_logs (recipe_id, cooked_at)',
  'CREATE INDEX IF NOT EXISTS idx_ingredient_aliases_normalized_alias '
      'ON ingredient_aliases (normalized_alias)',
  // Filtro por tag e contagem de uso das tags procuram por `tag_id` (a chave
  // primária composta só ajuda a busca que começa por `recipe_id`).
  'CREATE INDEX IF NOT EXISTS idx_recipe_tags_tag_id ON recipe_tags (tag_id)',
];

const _isoNow = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";

/// Gatilhos que marcam "mudou" nas tabelas sem data de edição própria (H4).
/// Itens de compras, histórico e despensa são alterados em muitos lugares do
/// app; em vez de cada um lembrar de carimbar `updated_at`, o banco carimba.
/// O texto é ISO em UTC com `Z`, o mesmo formato que o Drift grava.
///
/// Só disparam quando uma coluna de DADO mudou E `updated_at` não foi mexido
/// na mesma instrução: marcar como sincronizado (`synced_at`) não conta, e o
/// sync aplicando o que veio da nuvem (que já grava `updated_at`) também não.
/// Gatilho não se dispara a si mesmo (`recursive_triggers` fica desligado).
const List<String> _syncTriggerStatements = [
  'CREATE TRIGGER IF NOT EXISTS trg_cook_logs_touch_ins '
      'AFTER INSERT ON cook_logs WHEN NEW.updated_at IS NULL BEGIN '
      'UPDATE cook_logs SET updated_at = $_isoNow WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_cook_logs_touch_upd '
      'AFTER UPDATE ON cook_logs WHEN NEW.updated_at IS OLD.updated_at AND ('
      'NEW.cooked_at IS NOT OLD.cooked_at OR NEW.note IS NOT OLD.note OR '
      'NEW.meal_plan_entry_id IS NOT OLD.meal_plan_entry_id) BEGIN '
      'UPDATE cook_logs SET updated_at = $_isoNow WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_shopping_lists_touch_upd '
      'AFTER UPDATE ON shopping_lists WHEN NEW.updated_at IS OLD.updated_at '
      'AND (NEW.name IS NOT OLD.name OR NEW.status IS NOT OLD.status) BEGIN '
      'UPDATE shopping_lists SET updated_at = $_isoNow WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_shopping_items_touch_ins '
      'AFTER INSERT ON shopping_list_items WHEN NEW.updated_at IS NULL BEGIN '
      'UPDATE shopping_list_items SET updated_at = $_isoNow '
      'WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_shopping_items_touch_upd '
      'AFTER UPDATE ON shopping_list_items '
      'WHEN NEW.updated_at IS OLD.updated_at AND ('
      'NEW.ingredient_id IS NOT OLD.ingredient_id OR '
      'NEW.manual_name IS NOT OLD.manual_name OR '
      'NEW.quantity IS NOT OLD.quantity OR NEW.unit_id IS NOT OLD.unit_id OR '
      'NEW.checked IS NOT OLD.checked OR NEW.note IS NOT OLD.note OR '
      'NEW.position IS NOT OLD.position) BEGIN '
      'UPDATE shopping_list_items SET updated_at = $_isoNow '
      'WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_ingredients_pantry_ins '
      'AFTER INSERT ON ingredients '
      'WHEN NEW.in_pantry = 1 AND NEW.pantry_updated_at IS NULL BEGIN '
      'UPDATE ingredients SET pantry_updated_at = $_isoNow '
      'WHERE id = NEW.id; END',
  'CREATE TRIGGER IF NOT EXISTS trg_ingredients_pantry_upd '
      'AFTER UPDATE OF in_pantry ON ingredients '
      'WHEN NEW.in_pantry IS NOT OLD.in_pantry '
      'AND NEW.pantry_updated_at IS OLD.pantry_updated_at BEGIN '
      'UPDATE ingredients SET pantry_updated_at = $_isoNow '
      'WHERE id = NEW.id; END',
];

/// FTS5 externo sobre `recipes` (§6), mantido em sincronia por triggers.
const List<String> _ftsStatements = [
  'CREATE VIRTUAL TABLE recipes_fts USING fts5 '
      "(name, about, notes, content='recipes', content_rowid='rowid')",
  '''
CREATE TRIGGER recipes_fts_ai AFTER INSERT ON recipes BEGIN
  INSERT INTO recipes_fts (rowid, name, about, notes)
  VALUES (new.rowid, new.name, new.about, new.notes);
END''',
  '''
CREATE TRIGGER recipes_fts_ad AFTER DELETE ON recipes BEGIN
  INSERT INTO recipes_fts (recipes_fts, rowid, name, about, notes)
  VALUES ('delete', old.rowid, old.name, old.about, old.notes);
END''',
  '''
CREATE TRIGGER recipes_fts_au AFTER UPDATE ON recipes BEGIN
  INSERT INTO recipes_fts (recipes_fts, rowid, name, about, notes)
  VALUES ('delete', old.rowid, old.name, old.about, old.notes);
  INSERT INTO recipes_fts (rowid, name, about, notes)
  VALUES (new.rowid, new.name, new.about, new.notes);
END''',
];

@DriftDatabase(
  tables: [
    Folders,
    Recipes,
    Categories,
    Ingredients,
    IngredientAliases,
    Units,
    RecipeIngredients,
    RecipeSteps,
    Tags,
    RecipeTags,
    MealPlanEntries,
    SharedMeals,
    CookLogs,
    SyncTombstones,
    ShoppingLists,
    ShoppingListItems,
    ShoppingItemSources,
    NormalizerTerms,
  ],
  daos: [
    RecipeDao,
    TagDao,
    FolderDao,
    IngredientDao,
    ShoppingListDao,
    MealPlanDao,
    CookLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Banco isolado para testes — passe `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 14;

  /// Timestamps como texto ISO-8601 UTC, não epoch-int: legível no arquivo e
  /// sem ambiguidade de fuso quando o sync chegar.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  /// v2: `recipe_ingredients.ingredient_id` passa a aceitar nulo — o bloco B
  /// grava só `raw_text`; a normalização (C5) preenche o vínculo depois.
  /// v3: `recipes`/`folders` ganham `tile_color`/`tile_motif` (§9.4, nuláveis).
  /// v4: `recipes`/`folders` ganham `last_opened_at` (recentes da home) —
  /// entra nula pela migração; `ensureReady()` backfilla com `updated_at`
  /// pra dado existente não sumir da prateleira. O backfill não roda aqui no
  /// `onUpgrade`/`beforeOpen` porque a conexão ainda não enxerga com certeza
  /// dado já commitado por outra conexão até a abertura terminar de vez.
  /// v5: tabela `cook_logs` (histórico "cozinhei", G7).
  /// v6: `ingredients.in_pantry` (despensa, G11).
  /// v7: `recipes.image_synced_path` (foto já enviada ao Storage, H0).
  /// v8: `recipes.synced_at` / `folders.synced_at` e a tabela
  /// `sync_tombstones` (sync de receitas e pastas com a conta, H3). Tudo que já
  /// existe entra com `synced_at` nulo = pendente, então a 1ª sincronização
  /// sobe a biblioteca inteira.
  /// v9: o mesmo pro resto (H4) — `synced_at` em refeições planejadas, listas
  /// e itens de compras e histórico; `updated_at` em itens e histórico;
  /// `pantry_updated_at`/`pantry_synced_at` na despensa. Os gatilhos que
  /// preenchem `updated_at` e o backfill ficam em `ensureReady()` (o mesmo
  /// motivo do `last_opened_at`: a conexão da migração não enxerga com
  /// certeza dado já gravado).
  /// v10: `space_id` em listas de compras, refeições e avisos de exclusão — a
  /// "casa" (espaço compartilhado). Tudo entra nulo = só da pessoa.
  /// v11: tabela `shared_meals` (refeições planejadas por outras pessoas da casa).
  /// v12: `shopping_list_items.added_by` / `checked_by` (quem adicionou e quem
  /// marcou, nas listas da casa).
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final stmt in _indexStatements) {
            await customStatement(stmt);
          }
          for (final stmt in _ftsStatements) {
            await customStatement(stmt);
          }
          for (final stmt in _syncTriggerStatements) {
            await customStatement(stmt);
          }
          await _seed();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.alterTable(TableMigration(recipeIngredients));
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id '
              'ON recipe_ingredients (recipe_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_ingredient_id '
              'ON recipe_ingredients (ingredient_id)',
            );
          }
          if (from < 3) {
            await m.addColumn(recipes, recipes.tileColor);
            await m.addColumn(recipes, recipes.tileMotif);
            await m.addColumn(folders, folders.tileColor);
            await m.addColumn(folders, folders.tileMotif);
          }
          if (from < 4) {
            await m.addColumn(recipes, recipes.lastOpenedAt);
            await m.addColumn(folders, folders.lastOpenedAt);
          }
          if (from < 5) {
            await m.createTable(cookLogs);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_cook_logs_recipe_id '
              'ON cook_logs (recipe_id, cooked_at)',
            );
          }
          if (from < 6) {
            final cols = await customSelect('PRAGMA table_info(ingredients)')
                .map((r) => r.read<String>('name'))
                .get();
            if (!cols.contains('in_pantry')) {
              await m.addColumn(ingredients, ingredients.inPantry);
            }
          }
          if (from < 7) {
            await m.addColumn(recipes, recipes.imageSyncedPath);
          }
          if (from < 8) {
            await m.addColumn(recipes, recipes.syncedAt);
            await m.addColumn(folders, folders.syncedAt);
            await m.createTable(syncTombstones);
          }
          if (from < 9) {
            // `cook_logs` pode ter acabado de nascer (from < 5) já com estas
            // colunas: cada uma só entra se ainda faltar.
            await _addColumnIfMissing(
                m, mealPlanEntries, mealPlanEntries.syncedAt);
            await _addColumnIfMissing(m, shoppingLists, shoppingLists.syncedAt);
            await _addColumnIfMissing(
                m, shoppingListItems, shoppingListItems.updatedAt);
            await _addColumnIfMissing(
                m, shoppingListItems, shoppingListItems.syncedAt);
            await _addColumnIfMissing(m, cookLogs, cookLogs.updatedAt);
            await _addColumnIfMissing(m, cookLogs, cookLogs.syncedAt);
            await _addColumnIfMissing(
                m, ingredients, ingredients.pantryUpdatedAt);
            await _addColumnIfMissing(
                m, ingredients, ingredients.pantrySyncedAt);
          }
          if (from < 10) {
            await _addColumnIfMissing(
                m, mealPlanEntries, mealPlanEntries.spaceId);
            await _addColumnIfMissing(m, shoppingLists, shoppingLists.spaceId);
            await _addColumnIfMissing(
                m, syncTombstones, syncTombstones.spaceId);
          }
          if (from < 11) {
            await m.createTable(sharedMeals);
          }
          if (from < 12) {
            await _addColumnIfMissing(
                m, shoppingListItems, shoppingListItems.addedBy);
            await _addColumnIfMissing(
                m, shoppingListItems, shoppingListItems.checkedBy);
          }
          if (from < 13) {
            await _addColumnIfMissing(m, ingredients, ingredients.priceCents);
            await _addColumnIfMissing(m, ingredients, ingredients.priceBasis);
          }
          if (from < 14) {
            await _addColumnIfMissing(m, ingredients, ingredients.priceQty);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final cols =
        await customSelect('PRAGMA table_info(${table.actualTableName})')
            .map((r) => r.read<String>('name'))
            .get();
    if (!cols.contains(column.name)) await m.addColumn(table, column);
  }

  /// Semeia unidades, categorias e o vocabulário do normalizador (§6).
  /// Idempotente: IDs determinísticos + `insertOrIgnore`.
  Future<void> _seed() async {
    await batch((b) {
      b.insertAll(
        units,
        [
          for (final u in kSeedUnits)
            UnitsCompanion.insert(
              id: u.code,
              code: u.code,
              displayName: u.displayName,
              plural: u.plural,
              kind: u.kind,
              baseUnitId: Value(u.baseUnitCode),
              factorToBase: Value(u.factorToBase),
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
      b.insertAll(
        categories,
        [
          for (var i = 0; i < kSeedCategories.length; i++)
            CategoriesCompanion.insert(
              id: 'cat_${kSeedCategories[i].slug}',
              name: kSeedCategories[i].name,
              sortOrder: i,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
      b.insertAll(
        normalizerTerms,
        [
          for (final t in kSeedNormalizerTerms)
            NormalizerTermsCompanion.insert(
              id: 'norm_${t.kind}_${t.term}',
              term: t.term,
              kind: t.kind,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// Força a abertura preguiçosa do banco, rodando migração e seed. É o que
  /// `appBootstrapProvider` aguarda antes de liberar a home. `_seed()` roda
  /// de novo aqui (além do `onCreate`) porque é `insertOrIgnore` — banco já
  /// existente só ganha as linhas novas que entrarem em `kSeedUnits`/
  /// `kSeedCategories`/`kSeedNormalizerTerms` depois da instalação original,
  /// sem duplicar o que já tinha.
  Future<void> ensureReady() async {
    await customSelect('SELECT 1').get();
    await _seed();
    await _ensureIndexes();
    await _backfillLastOpenedAt();
    await _ensureSyncTriggers();
    await _backfillSyncTimestamps();
  }

  /// Gatilhos do sync (H4) — `IF NOT EXISTS`, então banco antigo os ganha sem
  /// mudar a versão do schema e os demais no-op.
  Future<void> _ensureSyncTriggers() async {
    for (final stmt in _syncTriggerStatements) {
      await customStatement(stmt);
    }
  }

  /// Migração v9: `updated_at` de itens de compras e do histórico nasce nulo
  /// pra dado existente — herda da lista / da criação, uma vez só. A despensa
  /// já marcada ganha a hora de agora pra subir na 1ª sincronização.
  Future<void> _backfillSyncTimestamps() async {
    await customStatement(
      'UPDATE cook_logs SET updated_at = COALESCE(created_at, $_isoNow) '
      'WHERE updated_at IS NULL',
    );
    await customStatement(
      'UPDATE shopping_list_items SET updated_at = COALESCE('
      '(SELECT l.updated_at FROM shopping_lists l '
      'WHERE l.id = shopping_list_items.list_id), $_isoNow) '
      'WHERE updated_at IS NULL',
    );
    await customStatement(
      'UPDATE ingredients SET pantry_updated_at = $_isoNow '
      'WHERE in_pantry = 1 AND pantry_updated_at IS NULL',
    );
  }

  /// Índices que entraram depois da instalação original (ex.: `recipe_tags`)
  /// — sem isso quem já tem o app nunca os ganharia, já que o `onCreate` só
  /// roda uma vez. `IF NOT EXISTS`: no-op quando já estão lá, sem mudar a
  /// versão do schema.
  Future<void> _ensureIndexes() async {
    for (final stmt in _indexStatements) {
      await customStatement(stmt);
    }
  }

  /// Migração v4: `last_opened_at` nasce nula pra dado existente — aqui ela
  /// herda `updated_at`, uma vez só (o `WHERE` faz virar no-op depois). Trata
  /// nula como "nunca aberto ainda de propósito" seria pior: a receita
  /// sumiria da prateleira de recentes até alguém abri-la de novo.
  Future<void> _backfillLastOpenedAt() async {
    await customStatement(
      'UPDATE recipes SET last_opened_at = updated_at '
      'WHERE last_opened_at IS NULL',
    );
    await customStatement(
      'UPDATE folders SET last_opened_at = updated_at '
      'WHERE last_opened_at IS NULL',
    );
  }

  /// Reexecuta o seed. Existe para o teste de idempotência.
  Future<void> reseed() => _seed();

  /// Deixa um aviso de exclusão pra nuvem (H4: o `kind` diz de que tabela é).
  /// Quem chama só deve avisar de item que JÁ foi sincronizado — o que nunca
  /// subiu não existe lá.
  Future<void> addTombstone(String kind, String id, {String? spaceId}) {
    return into(syncTombstones).insertOnConflictUpdate(
      SyncTombstonesCompanion.insert(
        kind: kind,
        id: id,
        deletedAt: DateTime.now().toUtc(),
        spaceId: Value(spaceId),
      ),
    );
  }

  /// A pessoa saiu da casa (ou foi removida, ou a casa acabou): o que era
  /// compartilhado vira só dela e volta a "nunca sincronizado", pra subir pra
  /// conta. Os avisos de exclusão que eram da casa somem — não há mais pra
  /// quem avisar.
  Future<void> detachSpace(String spaceId) {
    return transaction(() async {
      final lists = await (select(shoppingLists)
            ..where((l) => l.spaceId.equals(spaceId)))
          .get();
      await (update(shoppingLists)..where((l) => l.spaceId.equals(spaceId)))
          .write(const ShoppingListsCompanion(
        spaceId: Value(null),
        syncedAt: Value(null),
      ));
      await (update(shoppingListItems)
            ..where((i) => i.listId.isIn([for (final l in lists) l.id])))
          .write(const ShoppingListItemsCompanion(syncedAt: Value(null)));
      await (update(mealPlanEntries)..where((e) => e.spaceId.equals(spaceId)))
          .write(const MealPlanEntriesCompanion(
        spaceId: Value(null),
        syncedAt: Value(null),
      ));
      await (delete(syncTombstones)..where((t) => t.spaceId.equals(spaceId)))
          .go();
      await (delete(sharedMeals)..where((m) => m.spaceId.equals(spaceId))).go();
      await ingredientDao.resetPantrySync();
    });
  }

  /// Esquece tudo o que se sabia da nuvem: tudo volta a "nunca sincronizado",
  /// as fotos a "nunca enviadas" e os avisos de exclusão somem. Os dados em si
  /// ficam. Usado quando a conta some (excluída): se a pessoa entrar de novo, é
  /// uma conta nova e tudo precisa subir outra vez.
  Future<void> resetSyncState() {
    return transaction(() async {
      await update(recipes).write(const RecipesCompanion(
        syncedAt: Value(null),
        imageSyncedPath: Value(null),
      ));
      await update(folders)
          .write(const FoldersCompanion(syncedAt: Value(null)));
      await update(mealPlanEntries).write(const MealPlanEntriesCompanion(
        syncedAt: Value(null),
        spaceId: Value(null),
      ));
      await update(shoppingLists).write(const ShoppingListsCompanion(
        syncedAt: Value(null),
        spaceId: Value(null),
      ));
      await update(shoppingListItems)
          .write(const ShoppingListItemsCompanion(syncedAt: Value(null)));
      await update(cookLogs)
          .write(const CookLogsCompanion(syncedAt: Value(null)));
      await update(ingredients)
          .write(const IngredientsCompanion(pantrySyncedAt: Value(null)));
      await delete(syncTombstones).go();
    });
  }

  /// Apaga tudo que o usuário criou — receitas, pastas, tags, catálogo de
  /// ingredientes, planejamento e lista de compras (RF-08.4) — mas preserva
  /// as tabelas de seed (`units`/`categories`/`normalizer_terms`): são
  /// referência do app, não dado do usuário, e apagar+reseedar não traria
  /// benefício nenhum. Ordem explícita (não só depender de cascade) pra
  /// nunca esbarrar no `onDelete: restrict` de
  /// `recipe_ingredients.ingredient_id` nem no autorreferencial de
  /// `folders.parent_id`.
  Future<void> wipeUserData() {
    return transaction(() async {
      await delete(shoppingItemSources).go();
      await delete(shoppingListItems).go();
      await delete(shoppingLists).go();
      await delete(cookLogs).go();
      await delete(syncTombstones).go();
      await delete(mealPlanEntries).go();
      await delete(sharedMeals).go();
      await delete(recipeTags).go();
      await delete(recipeSteps).go();
      await delete(recipeIngredients).go();
      await delete(ingredientAliases).go();
      await delete(ingredients).go();
      await delete(tags).go();
      await delete(recipes).go();
      await delete(folders).go();
    });
  }
}
