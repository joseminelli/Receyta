import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026, 1, 1, 12);
    repo = RecipeRepository(db.recipeDao, clock: () => clock);
  });

  tearDown(() => db.close());

  Recipe unwrap(Result<Recipe> r) => (r as Ok<Recipe>).value;

  test('create persiste, gera uuid v4 e timestamps do clock', () async {
    final recipe = unwrap(await repo.create(name: '  Bolo de fubá  '));

    expect(recipe.name, 'Bolo de fubá');
    expect(recipe.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')));
    expect(recipe.createdAt, clock);
    expect(recipe.updatedAt, clock);
    expect(recipe.isFavorite, isFalse);

    expect(unwrap(await repo.getById(recipe.id)).name, 'Bolo de fubá');
  });

  test('getById devolve NotFoundFailure quando não existe', () async {
    final res = await repo.getById('nope');
    expect(res, isA<Err<Recipe>>());
    expect((res as Err<Recipe>).failure, isA<NotFoundFailure>());
  });

  test('watchAll: mais recente primeiro, exclui soft-deleted', () async {
    final a = unwrap(await repo.create(name: 'A'));
    clock = clock.add(const Duration(minutes: 1));
    final b = unwrap(await repo.create(name: 'B'));

    expect(
      (await repo.watchAll().first).map((r) => r.id),
      [b.id, a.id],
    );

    clock = clock.add(const Duration(minutes: 1));
    await repo.softDelete(a.id);

    expect((await repo.watchAll().first).map((r) => r.name), ['B']);
  });

  test('update salva e sobe updatedAt sem mexer no createdAt', () async {
    final r = unwrap(await repo.create(name: 'Sopa'));
    clock = clock.add(const Duration(hours: 2));

    final saved = unwrap(
      await repo.update(r.copyWith(name: 'Caldo verde', servings: 4)),
    );

    expect(saved.name, 'Caldo verde');
    expect(saved.servings, 4);
    expect(saved.updatedAt, clock);
    expect(saved.createdAt, r.createdAt);
    expect(unwrap(await repo.getById(r.id)).name, 'Caldo verde');
  });

  test('softDelete: some das consultas, linha continua no banco', () async {
    final r = unwrap(await repo.create(name: 'Rascunho'));
    await repo.softDelete(r.id);

    expect(await repo.getById(r.id), isA<Err<Recipe>>());
    expect(await repo.watchAll().first, isEmpty);

    final raw = await db.customSelect(
      'SELECT deleted_at FROM recipes WHERE id = ?',
      variables: [Variable<String>(r.id)],
    ).getSingle();
    expect(raw.read<DateTime?>('deleted_at'), isNotNull);
  });

  test('round-trip: todo campo-núcleo sobrevive', () async {
    final created = unwrap(await repo.create(
      name: 'Frango ao curry',
      about: 'rápido',
      prepMinutes: 15,
      cookMinutes: 25,
      servings: 4,
      sourceUrl: 'https://exemplo/curry',
      notes: 'melhor no dia seguinte',
      isFavorite: true,
    ));

    expect(unwrap(await repo.getById(created.id)), created);
  });
}
