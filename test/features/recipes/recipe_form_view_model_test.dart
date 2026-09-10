import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late RecipeFormViewModel vm;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026, 1, 1, 12);
    repo = RecipeRepository(db.recipeDao, db.tagDao, clock: () => clock);
    vm = RecipeFormViewModel(repo);
  });

  tearDown(() => db.close());

  Recipe ok(Result<Recipe> r) => (r as Ok<Recipe>).value;
  Failure err(Result<Recipe> r) => (r as Err<Recipe>).failure;

  test('cria com todos os campos e listas; tudo volta do banco', () async {
    final created = ok(await vm.submit(
      name: '  Frango ao curry  ',
      about: ' rápido ',
      prepText: '15',
      cookText: '25',
      servingsText: '4',
      notes: 'melhor no dia seguinte',
      ingredientLines: ['  500g de frango  ', '', '2 dentes de alho'],
      stepLines: ['Tempere', '   ', 'Refogue'],
    ));

    expect(created.name, 'Frango ao curry');
    expect(created.about, 'rápido');
    expect(created.prepMinutes, 15);
    expect(created.servings, 4);

    final detail = ((await repo.getDetail(created.id)) as Ok<RecipeDetail>).value;
    expect(detail.ingredients.map((i) => i.rawText),
        ['500g de frango', '2 dentes de alho']);
    expect(detail.steps.map((s) => s.text), ['Tempere', 'Refogue']);
  });

  test('campos vazios viram null; listas vazias ficam vazias', () async {
    final created = ok(await vm.submit(
      name: 'Café',
      about: '   ',
      prepText: '',
      servingsText: '  ',
      notes: '',
    ));

    expect(created.about, isNull);
    expect(created.prepMinutes, isNull);
    expect(created.servings, isNull);

    final detail = ((await repo.getDetail(created.id)) as Ok<RecipeDetail>).value;
    expect(detail.ingredients, isEmpty);
    expect(detail.steps, isEmpty);
  });

  test('nome vazio é ValidationFailure e nada é gravado', () async {
    expect(err(await vm.submit(name: '   ')), isA<ValidationFailure>());
    expect(await repo.watchAll().first, isEmpty);
  });

  test('número inválido ou não positivo é ValidationFailure', () async {
    expect(err(await vm.submit(name: 'X', prepText: 'abc')),
        isA<ValidationFailure>());
    expect(err(await vm.submit(name: 'X', servingsText: '0')),
        isA<ValidationFailure>());
    expect(await repo.watchAll().first, isEmpty);
  });

  test('tags: title case pt-BR, espaço colapsado, sem duplicata, vazio ignorado',
      () async {
    final created = ok(await vm.submit(
      name: 'Frango',
      tagNames: ['  RÁPIDO ', 'frango', 'Rápido', '  ', 'no  forno'],
    ));

    final detail = ((await repo.getDetail(created.id)) as Ok<RecipeDetail>).value;
    expect(detail.tags.map((t) => t.name), ['Frango', 'No Forno', 'Rápido']);
  });

  test('edita: mantém id/createdAt e substitui as listas', () async {
    final original = ok(await vm.submit(
      name: 'Sopa',
      prepText: '10',
      about: 'original',
      ingredientLines: ['água', 'sal'],
      stepLines: ['Ferva'],
    ));
    clock = clock.add(const Duration(hours: 3));

    final edited = ok(await vm.submit(
      original: original,
      name: 'Caldo verde',
      about: '',
      ingredientLines: ['batata', 'couve', 'linguiça'],
      stepLines: ['Cozinhe'],
    ));

    expect(edited.id, original.id);
    expect(edited.createdAt, original.createdAt);
    expect(edited.updatedAt, clock);
    expect(edited.about, isNull);

    final detail = ((await repo.getDetail(original.id)) as Ok<RecipeDetail>).value;
    expect(detail.recipe.name, 'Caldo verde');
    expect(detail.ingredients.map((i) => i.rawText),
        ['batata', 'couve', 'linguiça']);
    expect(detail.steps.map((s) => s.text), ['Cozinhe']);
    expect(await repo.watchAll().first, hasLength(1));
  });
}
