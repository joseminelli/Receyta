import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';

void main() {
  late AppDatabase db;
  late RecipesViewModel vm;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    vm = RecipesViewModel(
      RecipeRepository(db.recipeDao, clock: () => DateTime.utc(2026)),
    );
  });

  tearDown(() async {
    try {
      await db.close();
    } catch (_) {}
  });

  Recipe unwrap(Result<Recipe> r) => (r as Ok<Recipe>).value;

  test('createByName apara o texto, persiste e o stream reflete', () async {
    final created = unwrap(await vm.createByName('  Pão de queijo  '));
    expect(created.name, 'Pão de queijo');

    expect(
      (await vm.watchRecipes().first).map((r) => r.name),
      ['Pão de queijo'],
    );
  });

  test('watchRecipes traz o mais recente primeiro', () async {
    await vm.createByName('A');
    await vm.createByName('B');

    expect(
      (await vm.watchRecipes().first).map((r) => r.name),
      ['B', 'A'],
    );
  });

  test('nome vazio ou só espaços vira ValidationFailure e não grava', () async {
    for (final input in ['', '   ', '\n\t']) {
      final res = await vm.createByName(input);
      expect(res, isA<Err<Recipe>>());
      expect((res as Err<Recipe>).failure, isA<ValidationFailure>());
    }
    expect(await vm.watchRecipes().first, isEmpty);
  });

  test('falha do repositório propaga como Err', () async {
    await db.close();
    final res = await vm.createByName('Bolo');
    expect(res, isA<Err<Recipe>>());
    expect((res as Err<Recipe>).failure, isA<DatabaseFailure>());
  });
}
