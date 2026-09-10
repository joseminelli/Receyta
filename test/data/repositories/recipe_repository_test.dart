import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026, 1, 1, 12);
    repo = RecipeRepository(db.recipeDao, db.tagDao, clock: () => clock);
  });

  tearDown(() => db.close());

  Recipe unwrap(Result<Recipe> r) => (r as Ok<Recipe>).value;
  RecipeDetail unwrapDetail(Result<RecipeDetail> r) =>
      (r as Ok<RecipeDetail>).value;

  test('saveDetail cria: uuid v4, timestamps do clock, listas na ordem',
      () async {
    final recipe = unwrap(await repo.saveDetail(
      name: '  Bolo de fubá  ',
      about: 'cremoso',
      prepMinutes: 10,
      ingredientLines: ['2 xícaras de fubá', '3 ovos'],
      stepLines: ['Misture tudo', 'Asse 40 min'],
    ));

    expect(recipe.name, '  Bolo de fubá  ');
    expect(recipe.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')));
    expect(recipe.createdAt, clock);

    final detail = unwrapDetail(await repo.getDetail(recipe.id));
    expect(detail.ingredients.map((i) => i.rawText), ['2 xícaras de fubá', '3 ovos']);
    expect(detail.ingredients.map((i) => i.position), [0, 1]);
    expect(detail.ingredients.every((i) => i.ingredientId == null), isTrue);
    expect(detail.steps.map((s) => s.text), ['Misture tudo', 'Asse 40 min']);
  });

  test('saveDetail edita: mantém id/createdAt, substitui as listas', () async {
    final created = unwrap(await repo.saveDetail(
      name: 'Sopa',
      ingredientLines: ['água', 'sal', 'cenoura'],
      stepLines: ['Ferva'],
    ));
    clock = clock.add(const Duration(hours: 2));

    final edited = unwrap(await repo.saveDetail(
      base: created,
      name: 'Caldo verde',
      ingredientLines: ['batata', 'couve'],
      stepLines: ['Cozinhe a batata', 'Junte a couve'],
    ));

    expect(edited.id, created.id);
    expect(edited.createdAt, created.createdAt);
    expect(edited.updatedAt, clock);

    final detail = unwrapDetail(await repo.getDetail(created.id));
    expect(detail.recipe.name, 'Caldo verde');
    expect(detail.ingredients.map((i) => i.rawText), ['batata', 'couve']);
    expect(detail.steps.map((s) => s.text),
        ['Cozinhe a batata', 'Junte a couve']);
  });

  test('watchDetail reemite quando a receita é salva de novo', () async {
    final created = unwrap(await repo.saveDetail(name: 'A', ingredientLines: ['x']));

    final stream = repo.watchDetail(created.id);
    expect((await stream.first)!.ingredients.map((i) => i.rawText), ['x']);

    await repo.saveDetail(base: created, name: 'A', ingredientLines: ['x', 'y']);
    expect(
      (await stream.first)!.ingredients.map((i) => i.rawText),
      ['x', 'y'],
    );
  });

  test('getDetail devolve NotFoundFailure quando não existe', () async {
    final res = await repo.getDetail('nope');
    expect((res as Err<RecipeDetail>).failure, isA<NotFoundFailure>());
  });

  test('watchAll: mais recente primeiro, exclui soft-deleted', () async {
    final a = unwrap(await repo.saveDetail(name: 'A'));
    clock = clock.add(const Duration(minutes: 1));
    final b = unwrap(await repo.saveDetail(name: 'B'));

    expect((await repo.watchAll().first).map((r) => r.id), [b.id, a.id]);

    clock = clock.add(const Duration(minutes: 1));
    await repo.softDelete(a.id);
    expect((await repo.watchAll().first).map((r) => r.name), ['B']);
  });

  test('softDelete: some das consultas, linha continua no banco', () async {
    final r = unwrap(await repo.saveDetail(name: 'Rascunho'));
    await repo.softDelete(r.id);

    expect(await repo.getById(r.id), isA<Err<Recipe>>());
    expect(await repo.watchAll().first, isEmpty);

    final raw = await db.customSelect(
      'SELECT deleted_at FROM recipes WHERE id = ?',
      variables: [Variable<String>(r.id)],
    ).getSingle();
    expect(raw.read<DateTime?>('deleted_at'), isNotNull);
  });

  test('saveDetail grava tags, reaproveita a mesma linha entre receitas',
      () async {
    final a = unwrap(await repo.saveDetail(
      name: 'Curry',
      tagNames: ['rápido', 'frango'],
    ));
    final b = unwrap(await repo.saveDetail(
      name: 'Sopa',
      tagNames: ['rápido', 'vegano'],
    ));

    expect(
      unwrapDetail(await repo.getDetail(a.id)).tags.map((t) => t.name),
      ['Frango', 'Rápido'],
    );
    expect(
      unwrapDetail(await repo.getDetail(b.id)).tags.map((t) => t.name),
      ['Rápido', 'Vegano'],
    );

    final rows = await db.customSelect('SELECT COUNT(*) c FROM tags').getSingle();
    expect(rows.read<int>('c'), 3);
  });

  test('saveDetail edita: substitui as tags, não acumula', () async {
    final r = unwrap(await repo.saveDetail(name: 'X', tagNames: ['Ana', 'Boa']));
    await repo.saveDetail(base: r, name: 'X', tagNames: ['Boa', 'Céu']);

    expect(
      unwrapDetail(await repo.getDetail(r.id)).tags.map((t) => t.name),
      ['Boa', 'Céu'],
    );
  });

  test('watchAll(anyOfTagIds): filtro OU, só receitas ativas com a tag',
      () async {
    final curry =
        unwrap(await repo.saveDetail(name: 'Curry', tagNames: ['rápido']));
    unwrap(await repo.saveDetail(name: 'Bolo', tagNames: ['doce']));
    final sopa = unwrap(
        await repo.saveDetail(name: 'Sopa', tagNames: ['rápido', 'vegano']));

    final rapido = unwrapDetail(await repo.getDetail(curry.id))
        .tags
        .firstWhere((t) => t.name == 'Rápido')
        .id;

    final filtered =
        await repo.watchAll(anyOfTagIds: {rapido}).first;
    expect(filtered.map((r) => r.name).toSet(), {'Curry', 'Sopa'});

    await repo.softDelete(sopa.id);
    final afterDelete = await repo.watchAll(anyOfTagIds: {rapido}).first;
    expect(afterDelete.map((r) => r.name), ['Curry']);
  });

  test('saveDetail grava os ingredientes vinculados à receita', () async {
    final r = unwrap(await repo.saveDetail(
      name: 'X',
      ingredientLines: ['a', 'b'],
    ));
    final count = await db
        .customSelect('SELECT COUNT(*) c FROM recipe_ingredients WHERE recipe_id = ?',
            variables: [Variable<String>(r.id)])
        .getSingle();
    expect(count.read<int>('c'), 2);
  });
}
