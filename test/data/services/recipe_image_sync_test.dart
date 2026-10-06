import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements ImageRemote {
  @override
  String? userId = 'u1';

  final objects = <String, Uint8List>{};
  final uploads = <String>[];
  final removed = <String>[];
  bool failUpload = false;
  bool failRemove = false;

  @override
  Future<void> upload(String path, File file) async {
    if (failUpload) throw Exception('sem rede');
    uploads.add(path);
    objects[path] = await file.readAsBytes();
  }

  @override
  Future<Uint8List> download(String path) async {
    final bytes = objects[path];
    if (bytes == null) throw Exception('não existe');
    return bytes;
  }

  @override
  Future<bool> exists(String path) async => objects.containsKey(path);

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
  var counter = 0;

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

  /// Guarda uma foto com [bytes] e devolve o nome (hash do conteúdo).
  Future<String> photo(List<int> bytes) async {
    final src = File(p.join(root.path, 'src_${counter++}.jpg'))
      ..writeAsBytesSync(bytes);
    return images.store(src);
  }

  Future<String> recipeWithPhoto(String name, List<int> bytes) async {
    final id = ((await repo.saveDetail(name: name)).valueOrNull)!.id;
    await repo.setImage(id, await photo(bytes));
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
    remote.uploads.clear();

    expect(await sync.syncPending(), 0);
    expect(remote.uploads, isEmpty);
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
    final oldPath = remote.objects.keys.single;

    final newName = await photo([9, 9]);
    await repo.setImage(id, newName);

    expect(await sync.syncPending(), 1);
    expect(remote.objects.keys, ['u1/$newName']);
    expect(remote.objects.containsKey(oldPath), isFalse);
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

  test('salvar com uma cópia velha da receita não faz a foto subir de novo',
      () async {
    final id = await recipeWithPhoto('A', [1, 2, 3]);
    final stale = (await repo.getDetail(id)).valueOrNull!.recipe;
    await sync.syncPending();
    remote.uploads.clear();

    await repo.saveDetail(base: stale, name: 'A editada');

    expect(await db.recipeDao.pendingImageSync(), isEmpty);
    expect(await sync.syncPending(), 0);
    expect(remote.uploads, isEmpty);
  });

  group('economia de espaço', () {
    test('foto que já está na nuvem (backup restaurado) não é reenviada',
        () async {
      final name = await photo([5, 5, 5]);
      remote.objects['u1/$name'] = Uint8List.fromList([5, 5, 5]);
      final id = ((await repo.saveDetail(name: 'Restaurada')).valueOrNull)!.id;
      await repo.setImage(id, name);

      expect(await sync.syncPending(), 1);

      expect(remote.uploads, isEmpty);
      expect(await db.recipeDao.pendingImageSync(), isEmpty);
      expect(await db.recipeDao.syncedImageNames(), {name});
    });

    test('duas receitas com a mesma foto enviam UM arquivo só', () async {
      await recipeWithPhoto('A', [7, 7, 7]);
      await recipeWithPhoto('B', [7, 7, 7]);

      expect(await sync.syncPending(), 2);

      expect(remote.uploads, hasLength(1));
      expect(remote.objects, hasLength(1));
    });

    test('tirar a foto de uma receita não apaga o arquivo que a outra usa',
        () async {
      final a = await recipeWithPhoto('A', [7, 7, 7]);
      final b = await recipeWithPhoto('B', [7, 7, 7]);
      await sync.syncPending();

      await repo.setImage(a, null);
      await sync.syncPending();
      expect(remote.objects, hasLength(1));
      expect(remote.removed, isEmpty);

      await repo.setImage(b, null);
      await sync.syncPending();
      expect(remote.objects, isEmpty);
    });

    test('trocar a foto de uma receita preserva o arquivo da outra', () async {
      final a = await recipeWithPhoto('A', [7, 7, 7]);
      await recipeWithPhoto('B', [7, 7, 7]);
      await sync.syncPending();
      final shared = remote.objects.keys.single;

      await repo.setImage(a, await photo([1, 2]));
      await sync.syncPending();

      expect(remote.objects.containsKey(shared), isTrue);
      expect(remote.objects, hasLength(2));
    });

    test('arquivo local ausente e fora da nuvem: nada a enviar, fica pendente',
        () async {
      final id = ((await repo.saveDetail(name: 'Sem arquivo')).valueOrNull)!.id;
      await repo.setImage(id, '${'a' * 40}.jpg');

      expect(await sync.syncPending(), 0);
      expect(remote.uploads, isEmpty);
      expect(await db.recipeDao.pendingImageSync(), hasLength(1));
    });
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

  group('remoção de fotos de receitas apagadas', () {
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

    test('se outra receita ainda usa o arquivo, ele fica na nuvem', () async {
      final id = await recipeWithPhoto('A', [4, 4, 4]);
      await sync.syncPending();
      final name = remote.objects.keys.single.split('/').last;
      await recipeWithPhoto('B', [4, 4, 4]);
      await sync.queueRemoteDeletion([name]);

      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);
      await sync.syncPending();

      expect(remote.objects, hasLength(1));
    });
  });

  group('limpeza do que este aparelho enviou e ninguém usa', () {
    test('apaga o que enviou e nenhuma receita referencia mais', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);

      expect(await sync.sweepRemoteOrphans(), 1);
      expect(remote.objects, isEmpty);
    });

    test('NUNCA mexe em arquivo que outro aparelho enviou', () async {
      remote.objects['u1/de_outro_aparelho.jpg'] = Uint8List.fromList([9]);
      await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();

      expect(await sync.sweepRemoteOrphans(), 0);

      expect(remote.objects.containsKey('u1/de_outro_aparelho.jpg'), isTrue);
    });

    test('foto em uso (inclusive receita na lixeira) fica', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);

      expect(await sync.sweepRemoteOrphans(), 0);
      expect(remote.objects, hasLength(1));
    });

    test('foto adotada da nuvem (restauração) também é nossa pra limpar',
        () async {
      final name = await photo([5, 5, 5]);
      remote.objects['u1/$name'] = Uint8List.fromList([5, 5, 5]);
      final id = ((await repo.saveDetail(name: 'R')).valueOrNull)!.id;
      await repo.setImage(id, name);
      await sync.syncPending();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);

      expect(await sync.sweepRemoteOrphans(), 1);
      expect(remote.objects, isEmpty);
    });

    test('quem já estava enviado antes da lista existir passa a contar',
        () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      SharedPreferences.setMockInitialValues({});

      await sync.sweepRemoteOrphans();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);

      expect(await sync.sweepRemoteOrphans(), 1);
      expect(remote.objects, isEmpty);
    });

    test('sem login não apaga nada', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);
      remote.userId = null;

      expect(await sync.sweepRemoteOrphans(), 0);
      expect(remote.objects, isNotEmpty);
    });

    test('falha ao remover deixa pra próxima vez', () async {
      final id = await recipeWithPhoto('A', [1, 2, 3]);
      await sync.syncPending();
      await repo.softDelete(id);
      await db.recipeDao.hardDelete(id);
      remote.failRemove = true;

      expect(await sync.sweepRemoteOrphans(), 0);

      remote.failRemove = false;
      expect(await sync.sweepRemoteOrphans(), 1);
    });
  });
}
