import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipes;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    recipes = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
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

  test('watchAllWithCounts inclui tag não usada com contagem 0', () async {
    await recipes.saveDetail(name: 'Curry', tagNames: ['rápido']);
    await db.tagDao.ensureTags(['orfã']);

    final rows = await db.tagDao.watchAllWithCounts().first;
    expect(
      {for (final r in rows) r.tag.name: r.count},
      {'Rápido': 1, 'orfã': 0},
    );
  });

  test('deleteTag: some do catálogo e de todas as receitas (cascade)',
      () async {
    final curry = (await recipes.saveDetail(
      name: 'Curry',
      tagNames: ['rápido', 'frango'],
    ) as Ok<Recipe>)
        .value;
    await recipes.saveDetail(name: 'Sopa', tagNames: ['rápido']);

    final rapido = (await db.tagDao.watchAll().first)
        .firstWhere((t) => t.name == 'Rápido');
    expect(await db.tagDao.usageCount(rapido.id), 2);

    await db.tagDao.deleteTag(rapido.id);

    expect(
      (await db.tagDao.watchAll().first).map((t) => t.name),
      ['Frango'],
    );
    final detail =
        (await recipes.getDetail(curry.id) as Ok<RecipeDetail>).value;
    expect(detail.tags.map((t) => t.name), ['Frango']);
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
