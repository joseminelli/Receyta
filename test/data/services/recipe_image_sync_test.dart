import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';

class _FakeRemote implements ImageRemote {
  @override
  String? userId = 'u1';

  final objects = <String, Uint8List>{};
  bool failUpload = false;
  bool failRemove = false;
  final updatedAt = <String, DateTime>{};
  final removed = <String>[];

  @override
  Future<void> upload(String path, File file) async {
    if (failUpload) throw Exception('sem rede');
    objects[path] = await file.readAsBytes();
  }

  @override
  Future<Uint8List> download(String path) async {
    final bytes = objects[path];
    if (bytes == null) throw Exception('não existe');
    return bytes;
  }

  @override
  Future<List<RemoteImage>> list(String uid) async => [
        for (final k in objects.keys)
          if (k.startsWith('$uid/'))
            (
              name: k.substring(uid.length + 1),
              updatedAt: updatedAt[k] ?? DateTime(2020),
            ),
      ];

  @override
  Future<void> remove(String path) async {
    if (failRemove) throw Exception('sem rede');
    removed.add(path);
    objects.remove(path);
  }
}

void main() {
  late Directory root;
  late AppDatabase db;
  late RecipeRepository repo;
  late RecipeImageService images;
  late _FakeRemote remote;
  late RecipeImageSync sync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('image_sync_test');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    images = RecipeImageService(
      baseDir: () async => Directory(p.join(root.path, 'imgs')),
      compress: (src, dst, {required maxSide, required quality}) =>
          File(src).copy(dst),
    );
    remote = _FakeRemote();
    sync = RecipeImageSync(remote, db.recipeDao, images);
  });

  tearDown(() async {
    await db.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<String> recipeWithPhoto(String name, List<int> bytes) async {
    final saved = await repo.saveDetail(name: name);
    final id = (saved.valueOrNull)!.id;
    final src = File(p.join(root.path, '$name.jpg'))..writeAsBytesSync(bytes);
    final file = await images.store(src, recipeId: id);
    await repo.setImage(id, file);
    return id;
  }

  test('sem login não envia nada e a foto continua pendente', () async {
    remote.userId = null;
    await recipeWithPhoto('A', [1, 2, 3]);

    expect(await sync.syncPending(), 0);
    expect(remote.objects, isEmpty);
    expect(await db.recipeDao.pendingImageSync(), hasLength(1));
  });

  test('logado: envia pra <uid>/<arquivo> e marca como enviada', () async {
    await recipeWithPhoto('A', [1, 2, 3]);
    final name = (await db.recipeDao.pendingImageSync()).single.imagePath!;

    expect(await sync.syncPending(), 1);

    expect(remote.objects.keys, ['u1/$name']);
    expect(await db.recipeDao.pendingImageSync(), isEmpty);
  });

  test('segunda rodada não reenvia o que já subiu', () async {
    await recipeWithPhoto('A', [1, 2, 3]);
    await sync.syncPending();
    remote.objects.clear();

    expect(await sync.syncPending(), 0);
    expect(remote.objects, isEmpty);
  });

  test('falha de rede deixa pendente e a próxima rodada envia', () async {
    await recipeWithPhoto('A', [1, 2, 3]);
    remote.failUpload = true;

    expect(await sync.syncPending(), 0);
    expect(await db.recipeDao.pendingImageSync(), hasLength(1));

    remote.failUpload = false;
    expect(await sync.syncPending(), 1);
    expect(remote.objects, hasLength(1));
  });

  test('foto trocada: sobe a nova e apaga a antiga da nuvem', () async {
    final id = await recipeWithPhoto('A', [1, 2, 3]);
    await sync.syncPending();
    final oldName = remote.objects.keys.single;

    await Future<void>.delayed(const Duration(milliseconds: 3));
    final src = File(p.join(root.path, 'novo.jpg'))..writeAsBytesSync([9, 9]);
    final newName = await images.store(src, recipeId: id);
    await repo.setImage(id, newName);

    expect(await sync.syncPending(), 1);
    expect(remote.objects.keys, ['u1/$newName']);
    expect(remote.objects.containsKey(oldName), isFalse);
  });

  test('foto removida: apaga da nuvem e limpa o registro', () async {
    final id = await recipeWithPhoto('A', [1, 2, 3]);
    await sync.syncPending();

    await repo.setImage(id, null);

    expect(await sync.syncPending(), 1);
    expect(remote.objects, isEmpty);
    expect(await db.recipeDao.pendingImageSync(), isEmpty);
  });

  test('editar o texto da receita não zera o registro de envio', () async {
    final id = await recipeWithPhoto('A', [1, 2, 3]);
    await sync.syncPending();
    final detail = (await repo.getDetail(id)).valueOrNull!;

    await repo.saveDetail(base: detail.recipe, name: 'A editada');

    expect(await db.recipeDao.pendingImageSync(), isEmpty);
  });

  test('ensureLocal devolve o local, ou baixa da nuvem quando falta', () async {
    await recipeWithPhoto('A', [1, 2, 3]);
    await sync.syncPending();
    final name = remote.objects.keys.single.split('/').last;

    expect(await sync.ensureLocal(name), isNotNull);

    await images.delete(name);
    final restored = await sync.ensureLocal(name);
    expect(restored, isNotNull);
    expect(await restored!.readAsBytes(), [1, 2, 3]);
  });

  test('ensureLocal sem login ou sem a foto na nuvem devolve null', () async {
    expect(await sync.ensureLocal('inexistente.jpg'), isNull);

    remote.userId = null;
    expect(await sync.ensureLocal('inexistente.jpg'), isNull);
  });

  test('salvar com uma cópia velha da receita não faz a foto subir de novo',
      () async {
    final id = await recipeWithPhoto('A', [1, 2, 3]);
    final stale = (await repo.getDetail(id)).valueOrNull!.recipe;
    await sync.syncPending();
    remote.objects.clear();

    await repo.saveDetail(base: stale, name: 'A editada');

    expect(await db.recipeDao.pendingImageSync(), isEmpty);
    expect(await sync.syncPending(), 0);
    expect(remote.objects, isEmpty);
  });

  group('remoção de fotos de receitas apagadas', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('logado: apaga da nuvem e esvazia a fila', () async {
      remote.objects['u1/a.jpg'] = Uint8List.fromList([1]);
      await sync.queueRemoteDeletion(['a.jpg']);

      await sync.syncPending();

      expect(remote.objects, isEmpty);
      await sync.syncPending();
      expect(remote.removed, ['u1/a.jpg']);
    });

    test('sem login a fila espera e depois é esvaziada', () async {
      remote.objects['u1/a.jpg'] = Uint8List.fromList([1]);
      remote.userId = null;
      await sync.queueRemoteDeletion(['a.jpg']);

      await sync.syncPending();
      expect(remote.objects, isNotEmpty);

      remote.userId = 'u1';
      await sync.syncPending();
      expect(remote.objects, isEmpty);
    });

    test('falha ao remover mantém na fila pra próxima rodada', () async {
      remote.objects['u1/a.jpg'] = Uint8List.fromList([1]);
      remote.failRemove = true;
      await sync.queueRemoteDeletion(['a.jpg']);

      await sync.syncPending();
      expect(remote.objects, isNotEmpty);

      remote.failRemove = false;
      await sync.syncPending();
      expect(remote.objects, isEmpty);
    });
  });

  group('limpeza do que ninguém usa na nuvem', () {
    test('apaga o que nenhuma receita referencia e mantém o que está em uso',
        () async {
      await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      final inUse = remote.objects.keys.single;
      remote.objects['u1/sobra.jpg'] = Uint8List.fromList([9]);

      expect(await sync.sweepRemoteOrphans(), 1);

      expect(remote.objects.keys, [inUse]);
    });

    test('foto de receita na lixeira ainda conta como em uso', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);

      expect(await sync.sweepRemoteOrphans(), 0);
      expect(remote.objects, hasLength(1));
    });

    test('arquivo recém-gravado fica (pode ser um envio em andamento)',
        () async {
      remote.objects['u1/nova.jpg'] = Uint8List.fromList([9]);
      remote.updatedAt['u1/nova.jpg'] = DateTime.now();

      expect(await sync.sweepRemoteOrphans(), 0);
      expect(remote.objects, isNotEmpty);
    });

    test('sem login não apaga nada', () async {
      remote.objects['u1/sobra.jpg'] = Uint8List.fromList([9]);
      remote.userId = null;

      expect(await sync.sweepRemoteOrphans(), 0);
      expect(remote.objects, isNotEmpty);
    });

    test('receita apagada de vez cai na limpeza mesmo sem a fila', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);

      expect(await sync.sweepRemoteOrphans(), 1);
      expect(remote.objects, isEmpty);
    });
  });
}
