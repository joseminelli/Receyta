import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/seed_data.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<Set<String>> tableNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type IN ('table', 'view')",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  test('schema v1', () {
    expect(db.schemaVersion, 1);
  });

  test('onCreate cria todas as tabelas do schema + o índice FTS', () async {
    await db.ensureReady();
    final names = await tableNames();

    for (final expected in const [
      'folders',
      'recipes',
      'categories',
      'ingredients',
      'ingredient_aliases',
      'units',
      'recipe_ingredients',
      'recipe_steps',
      'tags',
      'recipe_tags',
      'meal_plan_entries',
      'shopping_lists',
      'shopping_list_items',
      'shopping_item_sources',
      'normalizer_terms',
      'recipes_fts',
    ]) {
      expect(names, contains(expected), reason: 'faltou $expected');
    }
  });

  test('foreign keys ligadas: filho órfão é rejeitado', () async {
    await db.ensureReady();
    await expectLater(
      db.customStatement(
        "INSERT INTO recipe_steps (id, recipe_id, instruction, position) "
        "VALUES ('s1', 'no-such-recipe', 'passo', 0)",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  group('seed de unidades', () {
    setUp(() => db.ensureReady());

    test('quantidade e kinds', () async {
      final units = await db.customSelect('SELECT * FROM units').get();
      expect(units.length, greaterThanOrEqualTo(30));
      expect(units.length, kSeedUnits.length);

      for (final row in units) {
        expect(kUnitKinds, contains(row.read<String>('kind')));
      }
    });

    test('g e ml são as bases; derivadas convertem para elas', () async {
      final rows = await db.customSelect('SELECT * FROM units').get();
      final byCode = {for (final r in rows) r.read<String>('code'): r};

      expect(byCode['g']!.read<String?>('base_unit_id'), isNull);
      expect(byCode['ml']!.read<String?>('base_unit_id'), isNull);
      expect(byCode['kg']!.read<String>('base_unit_id'), 'g');
      expect(byCode['kg']!.read<double>('factor_to_base'), 1000);
      expect(byCode['xicara']!.read<String>('base_unit_id'), 'ml');
    });

    test('todo base_unit_id resolve para uma unidade existente', () async {
      final rows = await db.customSelect('SELECT * FROM units').get();
      final ids = {for (final r in rows) r.read<String>('id')};
      for (final r in rows) {
        final base = r.read<String?>('base_unit_id');
        if (base != null) expect(ids, contains(base));
      }
    });
  });

  group('seed de categorias', () {
    setUp(() => db.ensureReady());

    test('ordem de corredor sem buracos, Hortifrúti primeiro', () async {
      final rows = await db
          .customSelect('SELECT * FROM categories ORDER BY sort_order')
          .get();

      expect(rows, isNotEmpty);
      expect(rows.length, kSeedCategories.length);
      expect(rows.first.read<String>('name'), 'Hortifrúti');
      for (var i = 0; i < rows.length; i++) {
        expect(rows[i].read<int>('sort_order'), i);
      }
    });
  });

  group('seed do normalizador', () {
    setUp(() => db.ensureReady());

    test('contém stopword e qualifier conhecidos; kinds válidos', () async {
      final rows =
          await db.customSelect('SELECT * FROM normalizer_terms').get();
      final byTerm = {
        for (final r in rows) r.read<String>('term'): r.read<String>('kind'),
      };

      expect(byTerm['de'], 'stopword');
      expect(byTerm['picado'], 'qualifier');
      expect(byTerm['a gosto'], 'qualifier');

      for (final kind in byTerm.values) {
        expect(kNormalizerKinds, contains(kind));
      }
      expect(rows.length, kSeedNormalizerTerms.length);
    });
  });

  test('seed é idempotente: reseed não duplica', () async {
    await db.ensureReady();

    Future<int> count(String table) async {
      final r =
          await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      return r.read<int>('c');
    }

    final before = [
      await count('units'),
      await count('categories'),
      await count('normalizer_terms'),
    ];

    await db.reseed();

    expect(
      [
        await count('units'),
        await count('categories'),
        await count('normalizer_terms'),
      ],
      before,
    );
  });

  group('FTS5 sobre recipes', () {
    setUp(() => db.ensureReady());

    Future<void> insertRecipe(String id, String name, String? about) {
      return db.customStatement(
        'INSERT INTO recipes (id, name, about, is_favorite, created_at, '
        'updated_at) VALUES (?, ?, ?, 0, 0, 0)',
        [id, name, about],
      );
    }

    Future<List<String>> search(String query) async {
      final rows = await db.customSelect(
        'SELECT r.name FROM recipes_fts f '
        'JOIN recipes r ON r.rowid = f.rowid '
        'WHERE recipes_fts MATCH ?',
        variables: [Variable<String>(query)],
      ).get();
      return rows.map((r) => r.read<String>('name')).toList();
    }

    test('acha por nome e por about; some ao deletar', () async {
      await insertRecipe('r1', 'Frango ao curry', 'rápido para a semana');
      await insertRecipe('r2', 'Bolo de fubá', 'clássico da tarde');

      expect(await search('curry'), ['Frango ao curry']);
      expect(await search('semana'), ['Frango ao curry']);
      expect(await search('fubá'), ['Bolo de fubá']);

      await db.customStatement("DELETE FROM recipes WHERE id = 'r1'");
      expect(await search('curry'), isEmpty);
    });

    test('acompanha update de nome', () async {
      await insertRecipe('r3', 'Sopa', null);
      expect(await search('sopa'), ['Sopa']);

      await db.customStatement(
        "UPDATE recipes SET name = 'Caldo verde' WHERE id = 'r3'",
      );
      expect(await search('sopa'), isEmpty);
      expect(await search('verde'), ['Caldo verde']);
    });
  });
}
