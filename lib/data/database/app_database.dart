import 'package:drift/drift.dart';

import 'connection.dart';
import 'seed_data.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Índices do §6. `IF NOT EXISTS` mantém o `onCreate` reexecutável em teste.
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

/// Busca textual do §6: FTS5 externo sobre `recipes`, mantido por triggers.
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
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Banco isolado para testes — passe `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

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
          // A8: passos versionados (stepByStep a partir do schema dump) +
          // teste de migração v1→v2. v1 é o baseline — nada a migrar ainda.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Semeia unidades, categorias e o vocabulário do normalizador (§6).
  ///
  /// Idempotente: IDs são slugs determinísticos e a inserção é `insertOrIgnore`,
  /// então reexecutar (num upgrade futuro, ou num teste) não duplica nada.
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

  /// Força a abertura preguiçosa do banco, rodando migração e seed. É o que a
  /// splash aguarda (`appBootstrapProvider` → `lib/bootstrap.dart`).
  Future<void> ensureReady() async {
    await customSelect('SELECT 1').get();
  }

  /// Reexecuta o seed com `insertOrIgnore`. Existe para o teste de
  /// idempotência; o app não precisa chamar.
  Future<void> reseed() => _seed();
}
