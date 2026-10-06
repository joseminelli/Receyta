import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Arquivos da pasta [uid] no Storage.
  Future<List<RemoteImage>> list(String uid);
}

/// Um arquivo do bucket: o nome (sem a pasta do usuário) e quando foi
/// gravado, pra a limpeza respeitar uma carência.
typedef RemoteImage = ({String name, DateTime? updatedAt});

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

  @override
  Future<List<RemoteImage>> list(String uid) async {
    const page = 100;
    final out = <RemoteImage>[];
    for (var offset = 0;; offset += page) {
      final files = await _bucket.list(
        path: uid,
        searchOptions: sb.SearchOptions(limit: page, offset: offset),
      );
      for (final f in files) {
        if (f.id == null) continue;
        out.add((
          name: f.name,
          updatedAt: DateTime.tryParse(f.updatedAt ?? f.createdAt ?? ''),
        ));
      }
      if (files.length < page) return out;
    }
  }
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

  @override
  Future<List<RemoteImage>> list(String uid) async => const [];
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

  static const _queueKey = 'image_remote_deletions';

  /// Anota fotos que precisam sair do Storage (receita apagada de vez). Fica
  /// guardado no aparelho até dar pra apagar de fato — sem login ou sem rede
  /// a remoção espera a próxima rodada.
  Future<void> queueRemoteDeletion(Iterable<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = {...?prefs.getStringList(_queueKey), ...names};
    await prefs.setStringList(_queueKey, queue.toList());
  }

  Future<void> _flushRemoteDeletions(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_queueKey) ?? const [];
    if (queue.isEmpty) return;
    final left = <String>[];
    for (final name in queue) {
      try {
        debugPrint('imageSync: removendo $uid/$name (receita apagada)');
        await _remote.remove('$uid/$name');
      } catch (e) {
        debugPrint('imageSync.remove($name): $e');
        left.add(name);
      }
    }
    await prefs.setStringList(_queueKey, left);
  }

  /// Envia as fotos novas e apaga da nuvem as trocadas/removidas. Devolve
  /// quantas receitas acertou. Nunca lança; uma falha numa receita não
  /// impede as outras, e ela fica pendente pra próxima vez.
  Future<int> syncPending() async {
    final uid = _remote.userId;
    if (uid == null || _running) return 0;
    _running = true;
    var done = 0;
    try {
      try {
        await _flushRemoteDeletions(uid);
      } catch (e) {
        debugPrint('imageSync.flush: $e');
      }
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
      debugPrint('imageSync: removendo $uid/$synced (receita $id)');
      await _remote.remove('$uid/$synced');
      if (current == null) {
        await _dao.setImageSynced(id, null);
        return true;
      }
    }
    if (current == null) return false;

    final file = await _images.fileFor(current);
    if (!await file.exists()) return false;
    debugPrint('imageSync: enviando $uid/$current (receita $id)');
    await _remote.upload('$uid/$current', file);
    await _dao.setImageSynced(id, current);
    return true;
  }

  /// Apaga do Storage o que nenhuma receita usa mais (sobra de receita
  /// apagada, foto trocada, envio interrompido) pra não gastar o espaço do
  /// plano. Devolve quantos apagou. Nunca lança.
  ///
  /// Arquivo gravado há menos de [grace] fica: pode ser um envio em andamento
  /// cuja receita ainda não foi salva. ATENÇÃO: a conta é uma só, mas as
  /// receitas ainda não sincronizam entre aparelhos — num segundo aparelho
  /// logado na mesma conta, as fotos do primeiro contam como "sem uso".
  Future<int> sweepRemoteOrphans({
    Duration grace = const Duration(days: 1),
    DateTime Function() clock = DateTime.now,
  }) async {
    final uid = _remote.userId;
    if (uid == null) return 0;
    var removed = 0;
    try {
      final inUse = await _dao.referencedImageNames();
      final cutoff = clock().subtract(grace);
      for (final file in await _remote.list(uid)) {
        if (inUse.contains(file.name)) continue;
        final at = file.updatedAt;
        if (at == null || at.isAfter(cutoff)) continue;
        debugPrint('imageSync: limpando sobra $uid/${file.name}');
        await _remote.remove('$uid/${file.name}');
        removed++;
      }
    } catch (e) {
      debugPrint('imageSync.sweep: $e');
    }
    return removed;
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
