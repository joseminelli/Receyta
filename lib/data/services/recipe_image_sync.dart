import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/recipe_image_service.dart';

/// Nome do bucket privado (ver `docs/supabase/recipe-images.sql`).
const kRecipeImagesBucket = 'recipe-images';

/// O que o sync precisa do Storage. Injetável pra o teste não usar rede.
abstract class ImageRemote {
  /// `null` = ninguém logado: o sync não faz nada.
  String? get userId;

  Future<void> upload(String path, File file);
  Future<Uint8List> download(String path);
  Future<void> remove(String path);
}

class SupabaseImageRemote implements ImageRemote {
  SupabaseImageRemote(this._client);

  final sb.SupabaseClient _client;

  sb.StorageFileApi get _bucket => _client.storage.from(kRecipeImagesBucket);

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> upload(String path, File file) => _bucket.upload(
        path,
        file,
        fileOptions: const sb.FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

  @override
  Future<Uint8List> download(String path) => _bucket.download(path);

  @override
  Future<void> remove(String path) => _bucket.remove([path]);
}

/// Usado quando o Supabase não inicializou.
class NoImageRemote implements ImageRemote {
  const NoImageRemote();

  @override
  String? get userId => null;

  @override
  Future<void> upload(String path, File file) async {}

  @override
  Future<Uint8List> download(String path) async => Uint8List(0);

  @override
  Future<void> remove(String path) async {}
}

/// Mantém as fotos locais espelhadas no Storage (H0). Local primeiro: o app
/// nunca espera a nuvem, e sem login ou sem rede nada se perde — a diferença
/// fica registrada em `recipes.image_synced_path` e é acertada na próxima
/// tentativa.
///
/// Caminho remoto: `<id-do-usuário>/<nome-do-arquivo>`; as policies do bucket
/// só deixam cada usuário mexer na própria pasta.
class RecipeImageSync {
  RecipeImageSync(this._remote, this._dao, this._images);

  final ImageRemote _remote;
  final RecipeDao _dao;
  final RecipeImageService _images;

  bool _running = false;

  /// Envia as fotos novas e apaga da nuvem as trocadas/removidas. Devolve
  /// quantas receitas acertou. Nunca lança; uma falha numa receita não
  /// impede as outras, e ela fica pendente pra próxima vez.
  Future<int> syncPending() async {
    final uid = _remote.userId;
    if (uid == null || _running) return 0;
    _running = true;
    var done = 0;
    try {
      for (final row in await _dao.pendingImageSync()) {
        try {
          if (await _syncOne(uid, row.id, row.imagePath, row.imageSyncedPath)) {
            done++;
          }
        } catch (e) {
          debugPrint('imageSync(${row.id}): $e');
        }
      }
    } catch (e) {
      debugPrint('imageSync: $e');
    } finally {
      _running = false;
    }
    return done;
  }

  Future<bool> _syncOne(
    String uid,
    String id,
    String? current,
    String? synced,
  ) async {
    if (synced != null && synced != current) {
      await _remote.remove('$uid/$synced');
      if (current == null) {
        await _dao.setImageSynced(id, null);
        return true;
      }
    }
    if (current == null) return false;

    final file = await _images.fileFor(current);
    if (!await file.exists()) return false;
    await _remote.upload('$uid/$current', file);
    await _dao.setImageSynced(id, current);
    return true;
  }

  /// O arquivo local da foto [name]; se não existe (outro aparelho, dados
  /// limpos), tenta baixar da nuvem. `null` = indisponível agora.
  Future<File?> ensureLocal(String name) async {
    final file = await _images.fileFor(name);
    if (await file.exists()) return file;

    final uid = _remote.userId;
    if (uid == null) return null;
    try {
      final bytes = await _remote.download('$uid/$name');
      if (bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('imageSync.download($name): $e');
      return null;
    }
  }
}

final imageRemoteProvider = Provider<ImageRemote>((ref) {
  try {
    return SupabaseImageRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoImageRemote();
  }
});

final recipeImageSyncProvider = Provider<RecipeImageSync>((ref) {
  return RecipeImageSync(
    ref.watch(imageRemoteProvider),
    ref.watch(databaseProvider).recipeDao,
    ref.watch(recipeImageServiceProvider),
  );
});
