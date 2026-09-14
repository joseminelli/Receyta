import 'package:drift/drift.dart';

import 'connection.dart';
import 'daos/folder_dao.dart';
import 'daos/ingredient_dao.dart';
import 'daos/recipe_dao.dart';
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
  'CREATE INDEX IF NOT EXISTS idx_ingredient_aliases_normalized_alias '
      'ON ingredient_aliases (normalized_alias)',
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
    ShoppingLists,
    ShoppingListItems,
    ShoppingItemSources,
    NormalizerTerms,
  ],
  daos: [RecipeDao, TagDao, FolderDao, IngredientDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Banco isolado para testes — passe `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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
    await _backfillLastOpenedAt();
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
}
