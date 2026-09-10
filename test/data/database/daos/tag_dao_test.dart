import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recipes = RecipeRepository(db.recipeDao, db.tagDao,
        clock: () => DateTime.utc(2026));
  });
  tearDown(() => db.close());

  test('ensureTags: cria o que falta, reusa o resto, mantém a ordem', () async {
    final first = await db.tagDao.ensureTags(['frango', 'rápido']);
    final second = await db.tagDao.ensureTags(['rápido', 'novo']);

    expect(first.map((t) => t.name), ['frango', 'rápido']);
    expect(second.map((t) => t.name), ['rápido', 'novo']);
    expect(second.first.id, first.last.id);

    final all = await db.tagDao.watchAll().first;
    expect(all.map((t) => t.name), ['frango', 'novo', 'rápido']);
  });

  test('watchInUse: só tags presas a receita ativa, sem duplicar', () async {
    final a = (await recipes.saveDetail(
      name: 'Curry',
      tagNames: ['rápido', 'frango'],
    ) as Ok<Recipe>)
        .value;
    await recipes.saveDetail(name: 'Sopa', tagNames: ['rápido']);
    await db.tagDao.ensureTags(['orfã']);

    expect(
      (await db.tagDao.watchInUse().first).map((t) => t.name),
      ['Frango', 'Rápido'],
    );

    await recipes.softDelete(a.id);
    await recipes.saveDetail(name: 'Bolo');

    expect(
      (await db.tagDao.watchInUse().first).map((t) => t.name),
      ['Rápido'],
    );
  });
}
