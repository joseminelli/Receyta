import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/sync/sync_engine.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O "servidor": uma linha por (tipo, id), com a mesma regra do trigger do SQL
/// — atualização com `edited_at` mais velho que o gravado é descartada — e
/// `updated_at` carimbado por um relógio próprio, que só avança.
class SyncServer {
  final rows = <String, SyncDoc>{};
  var _tick = DateTime.utc(2026, 1, 1);

  DateTime next() => _tick = _tick.add(const Duration(seconds: 1));

  int writes = 0;
}

class ServerRemote implements SyncRemote {
  ServerRemote(this.server);

  SyncServer server;

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

  @override
  Stream<void> changes() => const Stream.empty();
}

/// Um aparelho: banco próprio, relógio próprio e as preferências próprias (o
/// ponto de leitura do sync mora lá).
class SyncDevice {
  SyncDevice(this.name, SyncServer server, {Directory? imagesRoot}) {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => clock);
    remote = ServerRemote(server);
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
  late final ServerRemote remote;
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
