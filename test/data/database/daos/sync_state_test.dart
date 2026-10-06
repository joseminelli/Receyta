import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';

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

  Future<String> newRecipe(String name) async =>
      ((await repo.saveDetail(name: name)).valueOrNull)!.id;

  Future<RecipeRow> row(String id) async =>
      (await db.recipeDao.findIncludingTrashed(id))!;

  group('receitas pendentes de sync', () {
    test('receita nova nunca sincronizada está pendente', () async {
      final id = await newRecipe('A');

      expect((await db.recipeDao.dirtyForSync()).map((r) => r.id), [id]);
    });

    test('depois de sincronizada deixa de estar pendente', () async {
      final id = await newRecipe('A');
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      expect(await db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('editar de novo volta a ficar pendente', () async {
      final id = await newRecipe('A');
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      clock = clock.add(const Duration(minutes: 5));
      await repo.setFavorite(id, true);

      expect((await db.recipeDao.dirtyForSync()).map((r) => r.id), [id]);
    });

    test('editada durante o envio continua pendente (marca a versão antiga)',
        () async {
      final id = await newRecipe('A');
      final sentVersion = (await row(id)).updatedAt;

      clock = clock.add(const Duration(minutes: 1));
      await repo.setFavorite(id, true);
      await db.recipeDao.markSynced(id, sentVersion);

      expect(await db.recipeDao.dirtyForSync(), hasLength(1));
    });

    test('receita na lixeira também é sincronizada', () async {
      final id = await newRecipe('A');
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      clock = clock.add(const Duration(minutes: 1));
      await repo.softDelete(id);

      expect((await db.recipeDao.dirtyForSync()).single.deletedAt, isNotNull);
    });

    test('abrir a receita e marcar a foto como enviada não são edições',
        () async {
      final id = await newRecipe('A');
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      await db.recipeDao
          .setLastOpenedAt(id, clock.add(const Duration(days: 1)));
      await db.recipeDao.setImageSynced(id, 'x.jpg');

      expect(await db.recipeDao.dirtyForSync(), isEmpty);
    });
  });

  group('avisos de exclusão pra nuvem', () {
    test('apagar de vez uma receita já sincronizada deixa o aviso', () async {
      final id = await newRecipe('A');
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      await db.recipeDao.hardDelete(id);

      final tombstones = await db.select(db.syncTombstones).get();
      expect(tombstones.single.kind, 'recipe');
      expect(tombstones.single.id, id);
    });

    test('receita que nunca subiu não precisa de aviso', () async {
      final id = await newRecipe('A');

      await db.recipeDao.hardDelete(id);

      expect(await db.select(db.syncTombstones).get(), isEmpty);
    });

    test('a limpeza da lixeira também avisa, só das já sincronizadas',
        () async {
      final synced = await newRecipe('Sincronizada');
      final local = await newRecipe('So local');
      await db.recipeDao.markSynced(synced, (await row(synced)).updatedAt);
      await repo.softDelete(synced);
      await repo.softDelete(local);
      clock = clock.add(const Duration(days: 40));

      await repo.purgeExpired();

      final tombstones = await db.select(db.syncTombstones).get();
      expect(tombstones.map((t) => t.id), [synced]);
    });
  });

  group('pastas', () {
    test('pasta nova está pendente; sincronizada, não', () async {
      final folder = await db.folderDao.create(name: 'Massas');

      expect((await db.folderDao.dirtyForSync()).map((f) => f.id), [folder.id]);

      await db.folderDao.markSynced(folder.id, folder.updatedAt);
      expect(await db.folderDao.dirtyForSync(), isEmpty);
    });

    test(
        'apagar pasta sincronizada avisa a nuvem e marca o conteúdo como mudado',
        () async {
      final parent = await db.folderDao.create(name: 'Pai');
      final child =
          await db.folderDao.create(name: 'Filho', parentId: parent.id);
      final id = await newRecipe('A');
      await db.recipeDao.setFolder(id, child.id, clock);
      for (final f in [parent, child]) {
        await db.folderDao.markSynced(f.id, f.updatedAt);
      }
      await db.recipeDao.markSynced(id, (await row(id)).updatedAt);

      await db.folderDao
          .deleteFolder(child.id, clock.add(const Duration(minutes: 1)));

      final tombstones = await db.select(db.syncTombstones).get();
      expect(tombstones.single.kind, 'folder');
      expect(tombstones.single.id, child.id);
      expect((await db.recipeDao.dirtyForSync()).map((r) => r.id), [id]);
      expect((await row(id)).folderId, parent.id);
    });
  });

  test('limpar dados apaga também os avisos pendentes', () async {
    final id = await newRecipe('A');
    await db.recipeDao.markSynced(id, (await row(id)).updatedAt);
    await db.recipeDao.hardDelete(id);

    await db.wipeUserData();

    expect(await db.select(db.syncTombstones).get(), isEmpty);
  });
}
