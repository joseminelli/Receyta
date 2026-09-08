import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';

import 'generated/schema.dart';

/// Prova que o harness de migração funciona antes do bloco C precisar dele.
///
/// O snapshot v1 vive em `drift_schema/drift_schema_v1.json` (gerado por
/// `dart run drift_dev schema dump`). Quando `schemaVersion` subir: gerar
/// `drift_schema_vN.json`, rodar `drift_dev schema generate`, e adicionar aqui
/// um teste de dados v(N-1)→vN via `verifier.schemaAt`.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('onCreate constrói todas as tabelas declaradas', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.ensureReady();
    await db.validateDatabaseSchema(validateDropped: false);
  });

  test('schema do código bate com o snapshot v1 versionado', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 1);
  });
}
