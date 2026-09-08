import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/bootstrap.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';

/// A splash (`lib/splash.dart`, testada em `splash_test.dart`) espera
/// `appBootstrapProvider`. Aqui só provamos que esse provider abre o Drift,
/// roda o seed e resolve — sem a máquina de tempo falso de um widget test.
void main() {
  test('appBootstrapProvider abre o banco e conclui o seed', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    // Não lança e resolve.
    await container.read(appBootstrapProvider.future);

    // O seed do §6 rodou como parte da abertura.
    final units =
        await db.customSelect('SELECT COUNT(*) AS c FROM units').getSingle();
    expect(units.read<int>('c'), greaterThanOrEqualTo(30));

    final terms = await db
        .customSelect('SELECT COUNT(*) AS c FROM normalizer_terms')
        .getSingle();
    expect(terms.read<int>('c'), greaterThan(0));
  });
}
