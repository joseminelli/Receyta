import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';

void main() {
  late AppDatabase db;
  late RecipesViewModel vm;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026);
    vm = RecipesViewModel(RecipeRepository(db.recipeDao, db.tagDao, clock: () => clock));
  });

  tearDown(() => db.close());

  test('watchRecipes começa vazio', () async {
    expect(await vm.watchRecipes().first, isEmpty);
  });

  test('watchRecipes traz o mais recente primeiro', () async {
    final repo = RecipeRepository(db.recipeDao, db.tagDao, clock: () => clock);
    await repo.saveDetail(name: 'A');
    clock = clock.add(const Duration(minutes: 1));
    await repo.saveDetail(name: 'B');

    expect(
      (await vm.watchRecipes().first).map((r) => r.name),
      ['B', 'A'],
    );
  });

  test('watchRecipes(tagIds): filtra pelas tags marcadas', () async {
    final repo = RecipeRepository(db.recipeDao, db.tagDao, clock: () => clock);
    await repo.saveDetail(name: 'Curry', tagNames: ['rápido']);
    await repo.saveDetail(name: 'Bolo', tagNames: ['doce']);

    final rapido = (await db.tagDao.watchAll().first)
        .firstWhere((t) => t.name == 'Rápido')
        .id;

    expect(
      (await vm.watchRecipes(tagIds: {rapido}).first).map((r) => r.name),
      ['Curry'],
    );
    expect((await vm.watchRecipes().first).map((r) => r.name).toSet(),
        {'Curry', 'Bolo'});
  });
}
