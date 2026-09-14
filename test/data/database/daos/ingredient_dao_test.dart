import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('getOrCreate cria na primeira vez e reusa depois', () async {
    final first = await db.ingredientDao.getOrCreate('Tomate');
    final second = await db.ingredientDao.getOrCreate('tomates');

    expect(second.id, first.id);
    expect(first.displayName, 'Tomate');
    expect(first.normalizedKey, 'tomate');
  });

  test('bate por alias sem criar duplicata', () async {
    final tomato = await db.ingredientDao.getOrCreate('Tomate');
    await db.into(db.ingredientAliases).insert(
          IngredientAliasRow(
            id: 'alias-1',
            ingredientId: tomato.id,
            normalizedAlias: 'jitomate',
          ),
        );

    final byAlias = await db.ingredientDao.getOrCreate('jitomate');
    expect(byAlias.id, tomato.id);

    final all = await db.select(db.ingredients).get();
    expect(all.length, 1);
  });

  test('nomes diferentes viram ingredientes diferentes', () async {
    final a = await db.ingredientDao.getOrCreate('Cebola');
    final b = await db.ingredientDao.getOrCreate('Alho');
    expect(a.id, isNot(b.id));
  });

  test('addAlias grava e getOrCreate passa a bater direto por ele', () async {
    final tomato = await db.ingredientDao.getOrCreate('Tomate');
    await db.ingredientDao.addAlias(tomato.id, 'tomatee');

    final byAlias = await db.ingredientDao.getOrCreate('tomatee');
    expect(byAlias.id, tomato.id);

    final all = await db.select(db.ingredients).get();
    expect(all.length, 1);
  });

  test('addAlias não duplica se o alias já existe', () async {
    final tomato = await db.ingredientDao.getOrCreate('Tomate');
    await db.ingredientDao.addAlias(tomato.id, 'tomatee');
    await db.ingredientDao.addAlias(tomato.id, 'tomatee');

    final aliases = await db.select(db.ingredientAliases).get();
    expect(aliases.length, 1);
  });

  test('merge reaponta linhas de receita e apaga a origem', () async {
    final repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    final recipe = (await repo.saveDetail(
      name: 'Salada',
      ingredientLines: ['3 tomates'],
    ) as Ok<Recipe>)
        .value;
    final before =
        (await repo.getDetail(recipe.id) as Ok<RecipeDetail>).value;
    final sourceId = before.ingredients.single.ingredientId!;

    final target = await db.ingredientDao.getOrCreate('Tomate Italiano');
    await db.ingredientDao.merge(sourceId, target.id);

    final after = (await repo.getDetail(recipe.id) as Ok<RecipeDetail>).value;
    expect(after.ingredients.single.ingredientId, target.id);

    final remaining = await db.select(db.ingredients).get();
    expect(remaining.map((i) => i.id), [target.id]);
  });

  test('merge preserva o nome de origem como alias do destino', () async {
    final source = await db.ingredientDao.getOrCreate('Jitomate');
    final target = await db.ingredientDao.getOrCreate('Tomate');

    await db.ingredientDao.merge(source.id, target.id);

    final byOldName = await db.ingredientDao.getOrCreate('Jitomate');
    expect(byOldName.id, target.id);
    final all = await db.select(db.ingredients).get();
    expect(all.length, 1);
  });

  test('merge não faz nada quando origem e destino são o mesmo', () async {
    final tomato = await db.ingredientDao.getOrCreate('Tomate');
    await db.ingredientDao.merge(tomato.id, tomato.id);

    final all = await db.select(db.ingredients).get();
    expect(all.length, 1);
  });

  test('watchAllWithCounts conta linhas de receita por ingrediente', () async {
    final repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    await repo.saveDetail(name: 'A', ingredientLines: ['2 ovos']);
    await repo.saveDetail(name: 'B', ingredientLines: ['3 ovos', '1 alho']);
    await db.ingredientDao.getOrCreate('Sal');

    final rows = await db.ingredientDao.watchAllWithCounts().first;
    final byName = {
      for (final r in rows) r.ingredient.displayName: r.count,
    };
    expect(byName['ovos'], 2);
    expect(byName['alho'], 1);
    expect(byName['Sal'], 0);
  });
}
