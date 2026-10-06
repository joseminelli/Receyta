import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements AccountDataRemote {
  @override
  String? userId = 'u1';

  final calls = <String>[];
  bool failImages = false;
  bool failDocs = false;
  bool failAccount = false;

  @override
  Future<void> deleteAllImages() async {
    calls.add('images');
    if (failImages) throw Exception('sem rede');
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('conta');
    if (failAccount) throw Exception('sem rede');
  }

  @override
  Future<void> deleteAllDocs() async {
    calls.add('docs');
    if (failDocs) throw Exception('sem rede');
  }
}

void main() {
  late Directory root;
  late AppDatabase db;
  late RecipeRepository repo;
  late RecipeImageService images;
  late _FakeRemote remote;
  late DataResetService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sync_cursor_u1': '2026-01-01T00:00:00Z',
      'sync_cursor_u2': '2026-01-02T00:00:00Z',
      'image_owned_names': ['a.jpg'],
      'image_remote_deletions': ['b.jpg'],
      'image_quota_blocked': true,
      'settings_text_size': 'large',
    });
    root = await Directory.systemTemp.createTemp('data_reset_test');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    images = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (src, dst, {required maxSide, required quality}) =>
          File(src).copy(dst),
    );
    remote = _FakeRemote();
    service = DataResetService(db, remote: remote, images: images);

    final id = ((await repo.saveDetail(name: 'Bolo')).valueOrNull)!.id;
    final src = File(p.join(root.path, 'src.jpg'))..writeAsBytesSync([1, 2, 3]);
    await repo.setImage(id, await images.store(src));
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<int> recipeCount() async => (await db.select(db.recipes).get()).length;
  Future<int> photoCount() async =>
      (await (await images.directory()).list().toList()).length;

  group('limpar só este aparelho', () {
    test('apaga o banco e os arquivos de foto', () async {
      expect(await recipeCount(), 1);
      expect(await photoCount(), 1);

      final result = await service.wipeAll();

      expect(result.isOk, isTrue);
      expect(await recipeCount(), 0);
      expect(await photoCount(), 0);
    });

    test('não toca na nuvem', () async {
      await service.wipeAll();

      expect(remote.calls, isEmpty);
    });

    test('zera o ponto de leitura do sync, de todas as contas', () async {
      await service.wipeAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sync_cursor_u1'), isFalse);
      expect(prefs.containsKey('sync_cursor_u2'), isFalse);
    });

    test('esquece o bloqueio por conta cheia', () async {
      await service.wipeAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('image_quota_blocked'), isFalse);
    });

    test('esquece o que este aparelho enviou, senão a limpeza apagaria a nuvem',
        () async {
      await service.wipeAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('image_owned_names'), isFalse);
    });

    test('mantém a fila de fotos a apagar da nuvem e as preferências do app',
        () async {
      await service.wipeAll();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('image_remote_deletions'), ['b.jpg']);
      expect(prefs.getString('settings_text_size'), 'large');
    });
  });

  group('apagar tudo, inclusive da conta', () {
    test('apaga a nuvem (fotos e itens) e depois o aparelho', () async {
      final result = await service.wipeEverything();

      expect(result.isOk, isTrue);
      expect(remote.calls, ['images', 'docs']);
      expect(await recipeCount(), 0);
      expect(await photoCount(), 0);
    });

    test('limpa também a fila de fotos a apagar (já não há nada na nuvem)',
        () async {
      await service.wipeEverything();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('image_remote_deletions'), isFalse);
      expect(prefs.containsKey('image_owned_names'), isFalse);
      expect(prefs.containsKey('sync_cursor_u1'), isFalse);
      expect(prefs.getString('settings_text_size'), 'large');
    });

    test('sem conta conectada, recusa e não apaga nada', () async {
      remote.userId = null;

      final result = await service.wipeEverything();

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(remote.calls, isEmpty);
      expect(await recipeCount(), 1);
    });

    test('se as fotos da nuvem falham, NADA local é apagado', () async {
      remote.failImages = true;

      final result = await service.wipeEverything();

      expect((result as Err<void>).failure, isA<NetworkFailure>());
      expect(result.failure.message, contains('Nada foi apagado'));
      expect(remote.calls, ['images']);
      expect(await recipeCount(), 1);
      expect(await photoCount(), 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sync_cursor_u1'), isTrue);
    });

    test('se os itens da nuvem falham, nada local é apagado e dá pra repetir',
        () async {
      remote.failDocs = true;

      final first = await service.wipeEverything();
      expect(first, isA<Err<void>>());
      expect(await recipeCount(), 1);

      remote.failDocs = false;
      remote.calls.clear();
      final second = await service.wipeEverything();

      expect(second.isOk, isTrue);
      expect(await recipeCount(), 0);
    });
  });

  group('excluir a conta', () {
    Future<void> markEverythingSynced() async {
      for (final r in await db.select(db.recipes).get()) {
        await db.recipeDao.markSynced(r.id, r.updatedAt);
        await db.recipeDao.setImageSynced(r.id, r.imagePath);
      }
      await db.into(db.syncTombstones).insert(SyncTombstonesCompanion.insert(
            kind: 'recipe',
            id: 'velho',
            deletedAt: DateTime.utc(2026, 1, 1),
          ));
    }

    test('chama a função do servidor e mantém as receitas e fotos do aparelho',
        () async {
      final result = await service.deleteAccount();

      expect(result.isOk, isTrue);
      expect(remote.calls, ['conta']);
      expect(await recipeCount(), 1);
      expect(await photoCount(), 1);
    });

    test('o aparelho volta a "nunca sincronizado": numa conta nova tudo sobe',
        () async {
      await markEverythingSynced();
      expect(await db.recipeDao.dirtyForSync(), isEmpty);

      await service.deleteAccount();

      expect(await db.recipeDao.dirtyForSync(), hasLength(1));
      expect(
          (await db.select(db.recipes).get()).single.imageSyncedPath, isNull);
      expect(await db.select(db.syncTombstones).get(), isEmpty);
    });

    test('esquece cursor, lista do que enviou e fila de fotos da conta velha',
        () async {
      await service.deleteAccount();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sync_cursor_u1'), isFalse);
      expect(prefs.containsKey('image_owned_names'), isFalse);
      expect(prefs.containsKey('image_remote_deletions'), isFalse);
      expect(prefs.getString('settings_text_size'), 'large');
    });

    test('não mexe na nuvem por conta própria (a função do servidor cuida)',
        () async {
      await service.deleteAccount();

      expect(remote.calls, isNot(contains('images')));
      expect(remote.calls, isNot(contains('docs')));
    });

    test('sem conta conectada, recusa', () async {
      remote.userId = null;

      final result = await service.deleteAccount();

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(remote.calls, isEmpty);
    });

    test('se o servidor falha, nada muda no aparelho e dá pra repetir',
        () async {
      await markEverythingSynced();
      remote.failAccount = true;

      final result = await service.deleteAccount();

      expect((result as Err<void>).failure, isA<NetworkFailure>());
      expect(result.failure.message, contains('Nada foi apagado'));
      expect(await db.recipeDao.dirtyForSync(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('sync_cursor_u1'), isTrue);

      remote.failAccount = false;
      expect((await service.deleteAccount()).isOk, isTrue);
    });
  });
}
