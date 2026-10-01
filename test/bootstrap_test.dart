import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/bootstrap.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';

/// A splash (`lib/splash.dart`, testada em `splash_test.dart`) espera
/// `appBootstrapProvider`. Aqui provamos que esse provider abre o Drift, roda
/// o seed e resolve — sem a máquina de tempo falso de um widget test — e que a
/// manutenção (lixeira, ingredientes antigos) ficou fora desse caminho.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ProviderContainer containerWith({Duration? delay}) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        maintenanceDelayProvider.overrideWithValue(delay),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('appBootstrapProvider abre o banco e conclui o seed', () async {
    await containerWith().read(appBootstrapProvider.future);

    final units =
        await db.customSelect('SELECT COUNT(*) AS c FROM units').getSingle();
    expect(units.read<int>('c'), greaterThanOrEqualTo(30));

    final terms = await db
        .customSelect('SELECT COUNT(*) AS c FROM normalizer_terms')
        .getSingle();
    expect(terms.read<int>('c'), greaterThan(0));
  });

  // `getById` esconde receita da lixeira; conta direto na tabela.
  Future<int> rowsOf(String id) async {
    final row = await db.customSelect(
      'SELECT COUNT(*) AS c FROM recipes WHERE id = ?',
      variables: [Variable<String>(id)],
    ).getSingle();
    return row.read<int>('c');
  }

  test('a abertura não espera a manutenção: lixeira vencida segue lá', () async {
    final t0 = DateTime.utc(2026, 1, 1);
    final old = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => t0);
    final recipe =
        (await old.saveDetail(name: 'Velha') as Ok<Recipe>).value;
    await old.softDelete(recipe.id);

    final later = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => t0.add(const Duration(days: 31)));

    // Sem agendar manutenção (delay nulo) o bootstrap resolve e não apaga.
    await containerWith().read(appBootstrapProvider.future);
    expect(await rowsOf(recipe.id), 1);

    await runAppMaintenance(later);
    expect(await rowsOf(recipe.id), 0);
  });

  test('runAppMaintenance resolve ingrediente de receita antiga', () async {
    final repo =
        RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    final recipe = (await repo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['2 ovos'],
    ) as Ok<Recipe>)
        .value;
    // Simula dado do bloco B: linha sem vínculo com o catálogo.
    await db.customStatement('UPDATE recipe_ingredients SET ingredient_id = NULL');
    expect(await db.recipeDao.findUnresolvedIngredients(), isNotEmpty);

    await runAppMaintenance(repo);

    expect(await db.recipeDao.findUnresolvedIngredients(), isEmpty);
    expect(recipe.id, isNotEmpty);
  });

  test('runAppMaintenance nunca lança, mesmo com o banco fechado', () async {
    final repo =
        RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    await db.close();
    await expectLater(runAppMaintenance(repo), completes);
    // tearDown fecha de novo: não pode reclamar.
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
}
