import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';

class _FakeRemote implements ImageRemote {
  @override
  String? userId = 'u1';

  final objects = <String, Uint8List>{};
  bool failUpload = false;

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
  Future<void> remove(String path) async => objects.remove(path);
}

void main() {
  late Directory root;
  late AppDatabase db;
  late RecipeRepository repo;
  late RecipeImageService images;
  late _FakeRemote remote;
  late RecipeImageSync sync;

  setUp(() async {
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
}
