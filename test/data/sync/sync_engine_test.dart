import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/sync/sync_engine.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/domain/engine/sync_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O "servidor": uma linha por (tipo, id), com a mesma regra do trigger do SQL
/// — atualização com `edited_at` mais velho que o gravado é descartada — e
/// `updated_at` carimbado por um relógio próprio, que só avança.
class _Server {
  final rows = <String, SyncDoc>{};
  var _tick = DateTime.utc(2026, 1, 1);

  DateTime next() => _tick = _tick.add(const Duration(seconds: 1));

  int writes = 0;
}

class _FakeRemote implements SyncRemote {
  _FakeRemote(this.server);

  final _Server server;

  @override
  String? userId = 'u1';

  bool failPush = false;
  bool failPull = false;
  Future<void> Function()? duringPush;
  final pushedKinds = <String>[];

  @override
  Future<void> push(List<SyncDoc> docs) async {
    if (failPush) throw Exception('sem rede');
    await duringPush?.call();
    final stamp = server.next();
    for (final d in docs) {
      final key = '${d.kind}/${d.id}';
      final old = server.rows[key];
      if (old != null && d.editedAt.isBefore(old.editedAt)) continue;
      server.writes++;
      pushedKinds.add(d.kind);
      server.rows[key] = SyncDoc(
        kind: d.kind,
        id: d.id,
        editedAt: d.editedAt,
        data: d.deleted ? null : d.data,
        deleted: d.deleted,
        updatedAt: stamp,
      );
    }
  }

  @override
  Future<List<SyncDoc>> pullSince(DateTime? since) async {
    if (failPull) throw Exception('sem rede');
    final out = [
      for (final d in server.rows.values)
        if (since == null || !d.updatedAt!.isBefore(since)) d,
    ]..sort((a, b) => a.updatedAt!.compareTo(b.updatedAt!));
    return out;
  }
}

/// Um aparelho: banco próprio, relógio próprio e as preferências próprias (o
/// ponto de leitura do sync mora lá).
class _Device {
  _Device(this.name, _Server server, {Directory? imagesRoot}) {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => clock);
    remote = _FakeRemote(server);
    if (imagesRoot != null) {
      images = RecipeImageService(
        baseDir: () async => Directory(p.join(imagesRoot.path, name)),
        compress: (src, dst, {required maxSide, required quality}) =>
            File(src).copy(dst),
      );
    }
    engine = SyncEngine(
      remote: remote,
      db: db,
      recipes: repo,
      images: images,
    );
  }

  final String name;
  late final AppDatabase db;
  late final RecipeRepository repo;
  late final _FakeRemote remote;
  late final SyncEngine engine;
  RecipeImageService? images;
  DateTime clock = DateTime.utc(2026, 2, 1);
  Map<String, Object> prefs = {};

  void at(int minutes) =>
      clock = DateTime.utc(2026, 2, 1).add(Duration(minutes: minutes));

  Future<Result<SyncReport>> sync() async {
    SharedPreferences.setMockInitialValues(Map.of(prefs));
    final result = await engine.sync();
    final saved = await SharedPreferences.getInstance();
    prefs = {for (final k in saved.getKeys()) k: saved.get(k)!};
    return result;
  }

  Future<SyncReport> syncOk() async {
    final r = await sync();
    expect(r.isOk, isTrue,
        reason: '$name: ${r is Err ? (r as Err).failure : ''}');
    return r.valueOrNull!;
  }

  Future<String> newRecipe(
    String recipeName, {
    List<String> ingredients = const ['2 ovos'],
    List<String> tags = const [],
  }) async {
    final saved = await repo.saveDetail(
      name: recipeName,
      ingredientLines: ingredients,
      stepLines: const ['Misture'],
      tagNames: tags,
    );
    return saved.valueOrNull!.id;
  }

  Future<RecipeRow?> row(String id) => db.recipeDao.findIncludingTrashed(id);

  Future<List<RecipeRow>> allRecipes() => db.select(db.recipes).get();

  Future<void> close() => db.close();
}

void main() {
  late _Server server;
  late _Device a;
  late _Device b;
  late Directory root;

  setUp(() async {
    server = _Server();
    root = await Directory.systemTemp.createTemp('sync_engine_test');
    a = _Device('A', server, imagesRoot: root);
    b = _Device('B', server, imagesRoot: root);
  });

  tearDown(() async {
    await a.close();
    await b.close();
    if (await root.exists()) await root.delete(recursive: true);
  });

  group('remoteWins', () {
    final t1 = DateTime.utc(2026, 1, 1, 10);
    final t2 = DateTime.utc(2026, 1, 1, 11);
    final t3 = DateTime.utc(2026, 1, 1, 12);

    test('item que não existe aqui: aplica', () {
      expect(remoteWins(exists: false, remoteEditedAt: t1), isTrue);
    });

    test('local limpo e mesma versão: nada a fazer', () {
      expect(
        remoteWins(
          exists: true,
          remoteEditedAt: t2,
          localUpdatedAt: t2,
          localSyncedAt: t2,
        ),
        isFalse,
      );
    });

    test('local limpo e a nuvem mudou: segue a nuvem', () {
      expect(
        remoteWins(
          exists: true,
          remoteEditedAt: t3,
          localUpdatedAt: t2,
          localSyncedAt: t2,
        ),
        isTrue,
      );
    });

    test('local com mudança pendente: vence a edição mais recente', () {
      expect(
        remoteWins(
          exists: true,
          remoteEditedAt: t3,
          localUpdatedAt: t2,
          localSyncedAt: t1,
        ),
        isTrue,
      );
      expect(
        remoteWins(
          exists: true,
          remoteEditedAt: t1,
          localUpdatedAt: t2,
          localSyncedAt: t1,
        ),
        isFalse,
      );
    });

    test('nunca sincronizado conta como pendente', () {
      expect(
        remoteWins(
          exists: true,
          remoteEditedAt: t1,
          localUpdatedAt: t2,
          localSyncedAt: null,
        ),
        isFalse,
      );
    });
  });

  group('enviar e receber', () {
    test('sem login, não sincroniza', () async {
      a.remote.userId = null;

      final result = await a.sync();

      expect(result, isA<Err<SyncReport>>());
      expect((result as Err<SyncReport>).failure, isA<ValidationFailure>());
    });

    test('receita nova sobe e deixa de estar pendente', () async {
      await a.newRecipe('Bolo');

      final report = await a.syncOk();

      expect(report.pushed, 1);
      expect(server.rows.keys.single, startsWith('recipe/'));
      expect(await a.db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('o outro aparelho recebe a receita inteira', () async {
      final id = await a.newRecipe(
        'Frango ao curry',
        ingredients: ['500g de peito de frango em cubos', '1 cebola'],
        tags: ['Jantar', 'Rápido'],
      );
      await a.repo.setFavorite(id, true);
      await a.repo.setAppearance(id, color: null, motif: null);
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.applied, 1);
      final detail = (await b.repo.getDetail(id)).valueOrNull!;
      expect(detail.recipe.name, 'Frango ao curry');
      expect(detail.recipe.isFavorite, isTrue);
      expect(detail.ingredients.map((i) => i.rawText),
          ['500g de peito de frango em cubos', '1 cebola']);
      expect(detail.ingredients.first.quantity, 500);
      expect(detail.steps.single.text, 'Misture');
      expect(detail.tags.map((t) => t.name).toSet(), {'Jantar', 'Rápido'});
      expect(await b.db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('cor, textura e foto (pelo nome) viajam', () async {
      final id = await a.newRecipe('Sopa');
      await a.db.recipeDao.setAppearance(
        id,
        color: 'mar',
        motif: 'onda',
        at: a.clock,
      );
      await a.repo.setImage(id, 'abc_1.jpg');
      await a.syncOk();

      await b.syncOk();

      final r = (await b.row(id))!;
      expect(r.tileColor, 'mar');
      expect(r.tileMotif, 'onda');
      expect(r.imagePath, 'abc_1.jpg');
      // Já está na nuvem: o outro aparelho não tenta enviar de novo.
      expect(r.imageSyncedPath, 'abc_1.jpg');
    });

    test('segunda rodada sem mudanças não aplica nem envia nada', () async {
      await a.newRecipe('Bolo');
      await a.syncOk();

      final again = await a.syncOk();

      expect(again.applied, 0);
      expect(again.pushed, 0);
    });

    test('o que A mandou volta pra A na janela de sobreposição, mas é ignorado',
        () async {
      await a.newRecipe('Bolo');
      await a.syncOk();
      final writes = server.writes;

      final again = await a.syncOk();

      expect(again.pulled, greaterThan(0));
      expect(again.applied, 0);
      expect(server.writes, writes);
    });

    test('editar numa ponta aparece na outra', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.repo.setFavorite(id, true);
      await a.syncOk();
      await b.syncOk();

      expect((await b.row(id))!.isFavorite, isTrue);
    });

    test('a edição de B depois de receber chega em A', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      b.at(30);
      final loaded = (await b.repo.getDetail(id)).valueOrNull!;
      await b.repo.saveDetail(base: loaded.recipe, name: 'Bolo de fubá');
      await b.syncOk();
      await a.syncOk();

      expect((await a.row(id))!.name, 'Bolo de fubá');
    });

    test('abrir a receita (último acesso) não gera envio', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();

      await a.db.recipeDao.setLastOpenedAt(id, DateTime.utc(2027, 1, 1));
      final report = await a.syncOk();

      expect(report.pushed, 0);
    });
  });

  group('conflitos: a edição mais recente vence', () {
    test('as duas editaram offline: vale a de B (mais nova), em qualquer ordem',
        () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      final la = (await a.repo.getDetail(id)).valueOrNull!;
      await a.repo.saveDetail(base: la.recipe, name: 'Bolo da A');
      b.at(20);
      final lb = (await b.repo.getDetail(id)).valueOrNull!;
      await b.repo.saveDetail(base: lb.recipe, name: 'Bolo da B');

      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      expect((await a.row(id))!.name, 'Bolo da B');
      expect((await b.row(id))!.name, 'Bolo da B');
    });

    test('mesma coisa com B sincronizando primeiro', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      final la = (await a.repo.getDetail(id)).valueOrNull!;
      await a.repo.saveDetail(base: la.recipe, name: 'Bolo da A');
      b.at(20);
      final lb = (await b.repo.getDetail(id)).valueOrNull!;
      await b.repo.saveDetail(base: lb.recipe, name: 'Bolo da B');

      await b.syncOk();
      await a.syncOk();
      await b.syncOk();

      expect((await a.row(id))!.name, 'Bolo da B');
      expect((await b.row(id))!.name, 'Bolo da B');
    });

    test('a edição MAIS ANTIGA nunca sobrescreve a mais nova no servidor',
        () async {
      a.at(50);
      final id = await a.newRecipe('Bolo');
      await a.syncOk();

      // B tinha uma versão velha pendente e a empurra direto.
      await b.syncOk();
      b.at(5);
      final lb = (await b.repo.getDetail(id)).valueOrNull!;
      await b.repo.saveDetail(base: lb.recipe, name: 'Velha');
      await b.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: id,
          editedAt: DateTime.utc(2026, 2, 1, 0, 5),
          data: {'v': 1, 'id': id, 'name': 'Velha'},
        ),
      ]);

      final stored = server.rows['recipe/$id']!;
      expect(stored.data!['name'], 'Bolo');
    });

    test('apagar numa ponta e editar (mais tarde) na outra: a edição vence',
        () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.repo.softDelete(id);
      await a.db.recipeDao.hardDelete(id);
      await a.db.customStatement(
        "UPDATE sync_tombstones SET deleted_at = '2026-02-01T00:10:00.000Z'",
      );
      b.at(20);
      await b.repo.setFavorite(id, true);

      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      expect((await b.row(id)), isNotNull);
      expect((await a.row(id)), isNotNull);
      expect((await a.row(id))!.isFavorite, isTrue);
    });

    test('apagar mais tarde que a edição da outra ponta: a exclusão vence',
        () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      b.at(10);
      await b.repo.setFavorite(id, true);
      a.at(20);
      await a.repo.softDelete(id);
      await a.db.recipeDao.hardDelete(id);
      await a.db.customStatement(
        "UPDATE sync_tombstones SET deleted_at = '2026-02-01T00:20:00.000Z'",
      );

      await b.syncOk();
      await a.syncOk();
      await b.syncOk();

      expect(await b.row(id), isNull);
    });
  });

  group('exclusões', () {
    test('apagar de vez numa ponta apaga na outra, sem eco', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      await a.repo.softDelete(id);
      await a.repo.deleteForever(id);
      await a.syncOk();
      final report = await b.syncOk();

      expect(report.removed, 1);
      expect(await b.row(id), isNull);
      expect(await b.db.select(b.db.syncTombstones).get(), isEmpty);
      expect(await a.db.select(a.db.syncTombstones).get(), isEmpty);
    });

    test('mover pra lixeira sincroniza (aparece na lixeira da outra)',
        () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.repo.softDelete(id);
      await a.syncOk();
      await b.syncOk();

      expect((await b.row(id))!.deletedAt, isNotNull);
    });

    test('restaurar da lixeira também', () async {
      final id = await a.newRecipe('Bolo');
      a.at(5);
      await a.repo.softDelete(id);
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.repo.restore(id);
      await a.syncOk();
      await b.syncOk();

      expect((await b.row(id))!.deletedAt, isNull);
    });

    test('o aviso de exclusão que já foi enviado não é reenviado', () async {
      final id = await a.newRecipe('Bolo');
      await a.syncOk();
      await a.repo.softDelete(id);
      await a.repo.deleteForever(id);
      await a.syncOk();
      final writes = server.writes;

      final again = await a.syncOk();

      expect(again.pushed, 0);
      expect(server.writes, writes);
    });

    test('foto de receita apagada pela nuvem sai do aparelho, se ninguém usa',
        () async {
      final src = File(p.join(root.path, 'src.jpg'))..writeAsBytesSync([1, 2]);
      final name = await a.images!.store(src);
      await b.images!.storeBytes(await src.readAsBytes(), compress: false);
      final id = await a.newRecipe('Bolo');
      await a.repo.setImage(id, name);
      await a.syncOk();
      await b.syncOk();
      expect(await (await b.images!.fileFor(name)).exists(), isTrue);

      await a.repo.softDelete(id);
      await a.repo.deleteForever(id);
      await a.syncOk();
      await b.syncOk();

      expect(await (await b.images!.fileFor(name)).exists(), isFalse);
    });
  });

  group('pastas', () {
    test('pasta e receita dentro dela chegam ligadas', () async {
      final folder = await a.db.folderDao.create(name: 'Massas');
      final id = await a.newRecipe('Lasanha');
      await a.db.recipeDao.setFolder(id, folder.id, a.clock);
      await a.syncOk();

      await b.syncOk();

      expect((await b.row(id))!.folderId, folder.id);
      expect((await b.db.folderDao.findAny(folder.id))!.name, 'Massas');
    });

    test('subpasta chega mesmo vindo antes da pasta pai na lista', () async {
      final parent = await a.db.folderDao.create(name: 'Pai');
      final child =
          await a.db.folderDao.create(name: 'Filho', parentId: parent.id);
      await a.syncOk();

      await b.syncOk();

      expect((await b.db.folderDao.findAny(child.id))!.parentId, parent.id);
    });

    test('renomear pasta chega na outra', () async {
      final folder = await a.db.folderDao.create(name: 'Massas');
      await a.syncOk();
      await b.syncOk();

      await a.db.folderDao.rename(
        folder.id,
        'Massas e molhos',
        DateTime.now().toUtc().add(const Duration(minutes: 1)),
      );
      await a.syncOk();
      await b.syncOk();

      expect(
          (await b.db.folderDao.findAny(folder.id))!.name, 'Massas e molhos');
    });

    test('apagar a pasta sobe o conteúdo pro pai nas duas pontas', () async {
      final parent = await a.db.folderDao.create(name: 'Pai');
      final child =
          await a.db.folderDao.create(name: 'Filho', parentId: parent.id);
      final id = await a.newRecipe('Receita');
      await a.db.recipeDao.setFolder(id, child.id, a.clock);
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.db.folderDao.deleteFolder(child.id, a.clock);
      await a.syncOk();
      await b.syncOk();

      expect(await b.db.folderDao.findAny(child.id), isNull);
      expect((await b.row(id))!.folderId, parent.id);
    });

    test('receita que aponta pra pasta inexistente cai na raiz', () async {
      await b.syncOk();
      final id = 'receita-solta';
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: id,
          editedAt: DateTime.utc(2026, 2, 1),
          data: {
            'v': 1,
            'id': id,
            'name': 'Sem pasta',
            'folderId': 'pasta-que-nao-existe',
            'createdAt': '2026-02-01T00:00:00.000Z',
            'updatedAt': '2026-02-01T00:00:00.000Z',
          },
        ),
      ]);

      await b.syncOk();

      expect((await b.row(id))!.folderId, isNull);
    });
  });

  group('primeiro login e dados misturados', () {
    test('cada aparelho com receitas diferentes: no fim os dois têm tudo',
        () async {
      final ida = await a.newRecipe('Da A');
      final idb = await b.newRecipe('Da B');

      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      for (final d in [a, b]) {
        expect((await d.allRecipes()).map((r) => r.id).toSet(), {ida, idb});
      }
    });

    test('mesmo item nos dois lados, conteúdo diferente: a mais nova fica',
        () async {
      final id = await a.newRecipe('Bolo');
      a.at(10);
      b.at(30);
      await b.db.into(b.db.recipes).insert(RecipesCompanion.insert(
            id: id,
            name: 'Bolo (versão B)',
            createdAt: Value(b.clock),
            updatedAt: Value(b.clock),
          ));

      await a.syncOk();
      await b.syncOk();
      await a.syncOk();

      expect((await a.row(id))!.name, 'Bolo (versão B)');
      expect((await b.row(id))!.name, 'Bolo (versão B)');
    });

    test('ingredientes iguais viram um só no catálogo do aparelho novo',
        () async {
      await a.newRecipe('Bolo', ingredients: ['2 ovos', '1 xícara de açúcar']);
      await a.newRecipe('Pudim', ingredients: ['3 ovos', '1 lata de leite']);
      await a.syncOk();

      await b.syncOk();

      final names = (await b.db.select(b.db.ingredients).get())
          .map((i) => i.displayName.toLowerCase())
          .toList();
      expect(names.where((n) => n.contains('ovo')).length, 1);
    });
  });

  group('campo apagado também sincroniza (nulo não pode ser ignorado)', () {
    test('esvaziar Sobre, tempos e notas numa ponta limpa na outra', () async {
      final saved = await a.repo.saveDetail(
        name: 'Bolo',
        about: 'Da vovó',
        prepMinutes: 10,
        cookMinutes: 40,
        servings: 8,
        notes: 'nota',
      );
      final id = saved.valueOrNull!.id;
      await a.syncOk();
      await b.syncOk();
      expect((await b.row(id))!.about, 'Da vovó');

      a.at(10);
      final base = (await a.repo.getDetail(id)).valueOrNull!.recipe;
      await a.repo.saveDetail(base: base, name: 'Bolo');
      await a.syncOk();
      await b.syncOk();

      final r = (await b.row(id))!;
      expect(r.about, isNull);
      expect(r.prepMinutes, isNull);
      expect(r.cookMinutes, isNull);
      expect(r.servings, isNull);
      expect(r.notes, isNull);
    });

    test('tirar a foto, a cor e a pasta numa ponta limpa na outra', () async {
      final folder = await a.db.folderDao.create(name: 'Massas');
      final id = await a.newRecipe('Lasanha');
      await a.db.recipeDao.setFolder(id, folder.id, a.clock);
      await a.db.recipeDao
          .setAppearance(id, color: 'mar', motif: 'onda', at: a.clock);
      await a.repo.setImage(id, 'x.jpg');
      await a.syncOk();
      await b.syncOk();

      a.at(10);
      await a.db.recipeDao.setFolder(id, null, a.clock);
      await a.db.recipeDao
          .setAppearance(id, color: null, motif: null, at: a.clock);
      await a.repo.setImage(id, null);
      await a.syncOk();
      await b.syncOk();

      final r = (await b.row(id))!;
      expect(r.folderId, isNull);
      expect(r.tileColor, isNull);
      expect(r.tileMotif, isNull);
      expect(r.imagePath, isNull);
    });

    test('mover uma pasta pra raiz chega na outra', () async {
      final parent = await a.db.folderDao.create(name: 'Pai');
      final child =
          await a.db.folderDao.create(name: 'Filho', parentId: parent.id);
      await a.syncOk();
      await b.syncOk();
      expect((await b.db.folderDao.findAny(child.id))!.parentId, parent.id);

      await a.db.folderDao.move(
        child.id,
        null,
        DateTime.now().toUtc().add(const Duration(minutes: 1)),
      );
      await a.syncOk();
      await b.syncOk();

      expect((await b.db.folderDao.findAny(child.id))!.parentId, isNull);
    });
  });

  group('robustez', () {
    test('sem rede no envio: fica pendente e a próxima rodada envia', () async {
      await a.newRecipe('Bolo');
      a.remote.failPush = true;

      final failed = await a.sync();

      expect(failed, isA<Err<SyncReport>>());
      expect(await a.db.recipeDao.dirtyForSync(), hasLength(1));

      a.remote.failPush = false;
      expect((await a.syncOk()).pushed, 1);
      expect(await a.db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('sem rede na leitura: nada é perdido e o ponto de leitura não avança',
        () async {
      await a.newRecipe('Bolo');
      await a.syncOk();
      b.remote.failPull = true;

      final failed = await b.sync();

      expect(failed, isA<Err<SyncReport>>());
      expect(b.prefs.keys.where((k) => k.startsWith('sync_cursor_')), isEmpty);

      b.remote.failPull = false;
      expect((await b.syncOk()).applied, 1);
    });

    test('edição feita durante o envio continua pendente', () async {
      final id = await a.newRecipe('Bolo');
      a.remote.duringPush = () async {
        a.at(99);
        await a.repo.setFavorite(id, true);
      };

      await a.syncOk();

      expect(await a.db.recipeDao.dirtyForSync(), hasLength(1));
      a.remote.duringPush = null;
      expect((await a.syncOk()).pushed, 1);
      expect(await a.db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('item de uma versão mais nova do formato é ignorado sem quebrar',
        () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: 'futuro',
          editedAt: DateTime.utc(2026, 2, 1),
          data: {
            'v': kSyncSchemaVersion + 1,
            'id': 'futuro',
            'name': 'Do futuro',
            'createdAt': '2026-02-01T00:00:00.000Z',
            'updatedAt': '2026-02-01T00:00:00.000Z',
          },
        ),
      ]);

      final report = await b.syncOk();

      expect(report.applied, 0);
      expect(await b.row('futuro'), isNull);
    });

    test('lixo no servidor (corpo quebrado, tipo desconhecido) é ignorado',
        () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: 'quebrada',
          editedAt: DateTime.utc(2026, 2, 1),
          data: {'nada': 'util'},
        ),
        SyncDoc(
          kind: 'calendario',
          id: 'x',
          editedAt: DateTime.utc(2026, 2, 1),
          data: {'v': 1},
        ),
      ]);
      final id = await a.newRecipe('Boa');
      await a.syncOk();

      final report = await b.syncOk();

      expect(report.applied, 1);
      expect(await b.row(id), isNotNull);
      expect(await b.row('quebrada'), isNull);
    });

    test('unidade que este aparelho não conhece vira "sem unidade", sem erro',
        () async {
      await a.remote.push([
        SyncDoc(
          kind: kSyncKindRecipe,
          id: 'r1',
          editedAt: DateTime.utc(2026, 2, 1),
          data: {
            'v': 1,
            'id': 'r1',
            'name': 'Com unidade nova',
            'createdAt': '2026-02-01T00:00:00.000Z',
            'updatedAt': '2026-02-01T00:00:00.000Z',
            'ingredients': [
              {
                'position': 0,
                'rawText': '3 bobinas de sal',
                'name': 'Sal',
                'quantity': 3,
                'unit': 'bobina_inexistente',
              },
            ],
          },
        ),
      ]);

      await b.syncOk();

      final ing = await b.db.select(b.db.recipeIngredients).getSingle();
      expect(ing.unitId, isNull);
      expect(ing.rawText, '3 bobinas de sal');
    });

    test('mais de um lote de itens é enviado inteiro', () async {
      for (var i = 0; i < 120; i++) {
        await a.newRecipe('Receita $i', ingredients: const ['1 ovo']);
      }

      final report = await a.syncOk();

      expect(report.pushed, 120);
      expect(server.rows.length, 120);
      expect(await a.db.recipeDao.dirtyForSync(), isEmpty);
    });

    test('depois de limpar o aparelho, a próxima rodada traz tudo de volta',
        () async {
      await a.newRecipe('Bolo');
      await a.newRecipe('Pudim');
      await a.syncOk();
      await a.db.wipeUserData();
      a.prefs = {};

      final report = await a.syncOk();

      expect(report.applied, 2);
      expect(await a.allRecipes(), hasLength(2));
    });
  });
}
