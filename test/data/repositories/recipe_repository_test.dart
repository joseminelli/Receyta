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
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => clock);
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
    expect(
        recipe.id, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-')));
    expect(recipe.createdAt, clock);

    final detail = unwrapDetail(await repo.getDetail(recipe.id));
    expect(detail.ingredients.map((i) => i.rawText),
        ['2 xícaras de fubá', '3 ovos']);
    expect(detail.ingredients.map((i) => i.position), [0, 1]);
    expect(detail.ingredients.every((i) => i.ingredientId != null), isTrue);
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
    expect(
        detail.steps.map((s) => s.text), ['Cozinhe a batata', 'Junte a couve']);
  });

  test('watchDetail reemite quando a receita é salva de novo', () async {
    final created =
        unwrap(await repo.saveDetail(name: 'A', ingredientLines: ['x']));

    final stream = repo.watchDetail(created.id);
    expect((await stream.first)!.ingredients.map((i) => i.rawText), ['x']);

    await repo
        .saveDetail(base: created, name: 'A', ingredientLines: ['x', 'y']);
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

  test('setImage grava e tira a foto; referencedImagePaths lista as em uso',
      () async {
    final a = unwrap(await repo.saveDetail(name: 'A'));
    final b = unwrap(await repo.saveDetail(name: 'B'));

    await repo.setImage(a.id, 'a_1.jpg');
    await repo.setImage(b.id, 'b_1.jpg');

    expect(
        unwrapDetail(await repo.getDetail(a.id)).recipe.imagePath, 'a_1.jpg');
    expect(await repo.referencedImagePaths(), {'a_1.jpg', 'b_1.jpg'});

    await repo.setImage(a.id, null);

    expect(unwrapDetail(await repo.getDetail(a.id)).recipe.imagePath, isNull);
    expect(await repo.referencedImagePaths(), {'b_1.jpg'});
  });

  test('editar o conteúdo da receita não perde a foto', () async {
    final a = unwrap(await repo.saveDetail(name: 'A'));
    await repo.setImage(a.id, 'a_1.jpg');
    final loaded = unwrapDetail(await repo.getDetail(a.id)).recipe;

    await repo.saveDetail(base: loaded, name: 'A editada');

    expect(
      unwrapDetail(await repo.getDetail(a.id)).recipe.imagePath,
      'a_1.jpg',
    );
  });

  test('setFavorite alterna e reflete no watch', () async {
    final r = unwrap(await repo.saveDetail(name: 'Bolo'));
    expect(r.isFavorite, isFalse);

    await repo.setFavorite(r.id, true);
    expect((await repo.watchAll().first).single.isFavorite, isTrue);

    await repo.setFavorite(r.id, false);
    expect((await repo.watchAll().first).single.isFavorite, isFalse);
  });

  test('watchAll(favoritesOnly) e watchHasFavorites', () async {
    final a = unwrap(await repo.saveDetail(name: 'Curry'));
    unwrap(await repo.saveDetail(name: 'Bolo'));

    expect(await repo.watchHasFavorites().first, isFalse);
    expect(
      (await repo.watchAll(favoritesOnly: true).first),
      isEmpty,
    );

    await repo.setFavorite(a.id, true);
    expect(await repo.watchHasFavorites().first, isTrue);
    expect(
      (await repo.watchAll(favoritesOnly: true).first).map((r) => r.name),
      ['Curry'],
    );
  });

  test('lixeira: soft delete entra, restore volta, deleteForever apaga',
      () async {
    final r = unwrap(await repo.saveDetail(
      name: 'Sopa',
      ingredientLines: ['água'],
      tagNames: ['rápido'],
    ));

    await repo.softDelete(r.id);
    final trashed = await repo.watchTrashed().first;
    expect(trashed.single.name, 'Sopa');
    expect(trashed.single.deletedAt, isNotNull);

    await repo.restore(r.id);
    expect(await repo.watchTrashed().first, isEmpty);
    expect((await repo.watchAll().first).single.name, 'Sopa');

    await repo.softDelete(r.id);
    await repo.deleteForever(r.id);
    expect(await repo.watchTrashed().first, isEmpty);
    final rows = await db
        .customSelect('SELECT COUNT(*) c FROM recipe_ingredients')
        .getSingle();
    expect(rows.read<int>('c'), 0); // cascade
  });

  test('purgeExpired só apaga o que passou do prazo', () async {
    final old = unwrap(await repo.saveDetail(name: 'Antiga'));
    final fresh = unwrap(await repo.saveDetail(name: 'Nova'));

    clock = DateTime.utc(2026, 1, 1);
    await repo.softDelete(old.id);
    clock = DateTime.utc(2026, 2, 15); // 45 dias depois
    await repo.softDelete(fresh.id);

    await repo.purgeExpired(); // clock = 2026-02-15, corte = -30d = 2026-01-16

    final trashed = await repo.watchTrashed().first;
    expect(trashed.map((r) => r.name), ['Nova']);
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

    final rows =
        await db.customSelect('SELECT COUNT(*) c FROM tags').getSingle();
    expect(rows.read<int>('c'), 3);
  });

  test('saveDetail edita: substitui as tags, não acumula', () async {
    final r =
        unwrap(await repo.saveDetail(name: 'X', tagNames: ['Ana', 'Boa']));
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

    final filtered = await repo.watchAll(anyOfTagIds: {rapido}).first;
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
    final count = await db.customSelect(
        'SELECT COUNT(*) c FROM recipe_ingredients WHERE recipe_id = ?',
        variables: [Variable<String>(r.id)]).getSingle();
    expect(count.read<int>('c'), 2);
  });

  test('saveDetail roda o parser e resolve o catálogo de ingredientes',
      () async {
    final recipe = unwrap(await repo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['2 xícaras de farinha de trigo', '3 ovos'],
    ));
    final detail = unwrapDetail(await repo.getDetail(recipe.id));

    expect(detail.ingredients[0].quantity, 2);
    expect(detail.ingredients[0].unitId, 'xicara');
    expect(detail.ingredients[0].ingredientId, isNotNull);
    expect(detail.ingredients[1].quantity, 3);

    final again = unwrap(await repo.saveDetail(
      name: 'Bolo2',
      ingredientLines: ['3 tomates', '1 tomate'],
    ));
    final detailAgain = unwrapDetail(await repo.getDetail(again.id));
    expect(
      detailAgain.ingredients[0].ingredientId,
      detailAgain.ingredients[1].ingredientId,
    );
  });

  test(
      'reprocessLegacyIngredients resolve raw_text do bloco B e é '
      'idempotente', () async {
    final recipe = unwrap(await repo.saveDetail(name: 'Bolo'));
    await db.into(db.recipeIngredients).insert(
          RecipeIngredientRow(
            id: 'legacy-1',
            recipeId: recipe.id,
            rawText: '2 xícaras de farinha de trigo',
            position: 0,
          ),
        );

    final first = await repo.reprocessLegacyIngredients();
    expect((first as Ok<int>).value, 1);

    final detail = unwrapDetail(await repo.getDetail(recipe.id));
    expect(detail.ingredients[0].quantity, 2);
    expect(detail.ingredients[0].unitId, 'xicara');
    expect(detail.ingredients[0].ingredientId, isNotNull);
    expect(detail.ingredients[0].rawText, '2 xícaras de farinha de trigo');

    final second = await repo.reprocessLegacyIngredients();
    expect((second as Ok<int>).value, 0);
  });

  group('fotos ao apagar de vez', () {
    late List<(List<String>, List<String>)> released;
    late RecipeRepository withHook;

    setUp(() {
      released = [];
      withHook = RecipeRepository(
        db.recipeDao,
        db.tagDao,
        db.ingredientDao,
        clock: () => clock,
        onImagesReleased: (local, remote) async =>
            released.add((local, remote)),
      );
    });

    test('deleteForever avisa a foto local e a que já subiu', () async {
      final r = unwrap(await withHook.saveDetail(name: 'A'));
      await withHook.setImage(r.id, 'a_1.jpg');
      await db.recipeDao.setImageSynced(r.id, 'a_1.jpg');
      await withHook.softDelete(r.id);

      await withHook.deleteForever(r.id);

      expect(released, hasLength(1));
      expect(released.single.$1, ['a_1.jpg']);
      expect(released.single.$2, ['a_1.jpg']);
    });

    test('foto que nunca subiu só libera o arquivo local', () async {
      final r = unwrap(await withHook.saveDetail(name: 'A'));
      await withHook.setImage(r.id, 'a_1.jpg');
      await withHook.softDelete(r.id);

      await withHook.deleteForever(r.id);

      expect(released, hasLength(1));
      expect(released.single.$1, ['a_1.jpg']);
      expect(released.single.$2, isEmpty);
    });

    test('receita sem foto não dispara nada', () async {
      final r = unwrap(await withHook.saveDetail(name: 'A'));
      await withHook.softDelete(r.id);

      await withHook.deleteForever(r.id);

      expect(released, isEmpty);
    });

    test('purgeExpired libera só as fotos das receitas vencidas', () async {
      final old = unwrap(await withHook.saveDetail(name: 'Velha'));
      final fresh = unwrap(await withHook.saveDetail(name: 'Nova'));
      await withHook.setImage(old.id, 'velha.jpg');
      await withHook.setImage(fresh.id, 'nova.jpg');
      await withHook.softDelete(old.id);
      clock = clock.add(const Duration(days: 20));
      await withHook.softDelete(fresh.id);
      clock = clock.add(const Duration(days: 15));

      await withHook.purgeExpired();

      expect(released, hasLength(1));
      expect(released.single.$1, ['velha.jpg']);
      expect(released.single.$2, isEmpty);
      final remaining = await db.select(db.recipes).get();
      expect(remaining.map((r) => r.id), [fresh.id]);
    });
  });

  group('arquivo de foto em uso', () {
    test('isImageInUse vê quem tem o arquivo, e ignora a própria receita',
        () async {
      final a = unwrap(await repo.saveDetail(name: 'A'));
      final b = unwrap(await repo.saveDetail(name: 'B'));
      await repo.setImage(a.id, 'x.jpg');

      expect(await repo.isImageInUse('x.jpg'), isTrue);
      expect(await repo.isImageInUse('x.jpg', exceptRecipeId: a.id), isFalse);
      expect(await repo.isImageInUse('x.jpg', exceptRecipeId: b.id), isTrue);
      expect(await repo.isImageInUse('outro.jpg'), isFalse);
    });

    test('receita na lixeira ainda conta como dona do arquivo', () async {
      final a = unwrap(await repo.saveDetail(name: 'A'));
      await repo.setImage(a.id, 'x.jpg');
      await repo.softDelete(a.id);

      expect(await repo.isImageInUse('x.jpg'), isTrue);
    });

    test('na nuvem, quem ainda tem o arquivo como "enviado" também conta',
        () async {
      final a = unwrap(await repo.saveDetail(name: 'A'));
      await repo.setImage(a.id, 'novo.jpg');
      await db.recipeDao.setImageSynced(a.id, 'velho.jpg');

      expect(await db.recipeDao.isImagePathUsed('velho.jpg'), isFalse);
      expect(await db.recipeDao.isRemoteImageUsed('velho.jpg'), isTrue);
      expect(
        await db.recipeDao.isRemoteImageUsed('velho.jpg', exceptRecipeId: a.id),
        isFalse,
      );
    });
  });
}
