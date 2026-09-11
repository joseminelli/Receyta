import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// Guarda o schema versionado (RNF-07): o código tem que bater com o snapshot
/// e cada migração N→N+1 é testada com dados reais.
///
/// Snapshots em `drift_schema/drift_schema_vN.json` (`dart run drift_dev schema
/// dump`). Ao subir `schemaVersion`: gerar o novo snapshot, rodar `drift_dev
/// schema generate` e acrescentar aqui o teste de dados da nova migração.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('onCreate constrói todas as tabelas declaradas', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureReady();
    await db.validateDatabaseSchema(validateDropped: false);
  });

  test('schema do código bate com o snapshot v3 versionado', () async {
    final connection = await verifier.startAt(3);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('migração v1→v2: dados preservados, ingredient_id vira nulável',
      () async {
    final schema = await verifier.schemaAt(1);

    final oldDb = v1.DatabaseAtV1(schema.newConnection());
    await oldDb.customStatement(
      "INSERT INTO recipes (id, name, created_at, updated_at, is_favorite) "
      "VALUES ('r1', 'Bolo', '2026-01-01T00:00:00.000Z', "
      "'2026-01-01T00:00:00.000Z', 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO ingredients (id, display_name, normalized_key, usage_count) "
      "VALUES ('i1', 'trigo', 'trigo', 0)",
    );
    await oldDb.customStatement(
      "INSERT INTO recipe_ingredients "
      "(id, recipe_id, ingredient_id, raw_text, position) "
      "VALUES ('ri1', 'r1', 'i1', '2 xícaras de trigo', 0)",
    );
    await oldDb.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    addTearDown(db.close);

    final kept = await db.customSelect(
      'SELECT raw_text, ingredient_id FROM recipe_ingredients WHERE id = ?',
      variables: [Variable<String>('ri1')],
    ).getSingle();
    expect(kept.read<String>('raw_text'), '2 xícaras de trigo');
    expect(kept.read<String?>('ingredient_id'), 'i1');

    await db.customStatement(
      "INSERT INTO recipe_ingredients "
      "(id, recipe_id, ingredient_id, raw_text, position) "
      "VALUES ('ri2', 'r1', NULL, 'sal a gosto', 1)",
    );
    final free = await db.customSelect(
      "SELECT ingredient_id FROM recipe_ingredients WHERE id = 'ri2'",
    ).getSingle();
    expect(free.read<String?>('ingredient_id'), isNull);
  });

  test('migração v2→v3: dados preservados, tile_color/tile_motif entram nulos',
      () async {
    final schema = await verifier.schemaAt(2);

    final oldDb = schema.newConnection();
    final at2 = AppDatabase.forTesting(oldDb);
    await at2.customStatement(
      "INSERT INTO recipes (id, name, created_at, updated_at, is_favorite) "
      "VALUES ('r1', 'Bolo', '2026-01-01T00:00:00.000Z', "
      "'2026-01-01T00:00:00.000Z', 0)",
    );
    await at2.customStatement(
      "INSERT INTO folders (id, name, position, created_at, updated_at) "
      "VALUES ('f1', 'Doces', 0, '2026-01-01T00:00:00.000Z', "
      "'2026-01-01T00:00:00.000Z')",
    );
    await at2.close();

    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    addTearDown(db.close);

    final recipe = await db
        .customSelect("SELECT name, tile_color, tile_motif FROM recipes")
        .getSingle();
    expect(recipe.read<String>('name'), 'Bolo');
    expect(recipe.read<String?>('tile_color'), isNull);
    expect(recipe.read<String?>('tile_motif'), isNull);

    await db.customStatement(
      "UPDATE folders SET tile_color = 'lime', tile_motif = 'ponto' "
      "WHERE id = 'f1'",
    );
    final folder = await db
        .customSelect("SELECT tile_color, tile_motif FROM folders")
        .getSingle();
    expect(folder.read<String?>('tile_color'), 'lime');
    expect(folder.read<String?>('tile_motif'), 'ponto');
  });
}
