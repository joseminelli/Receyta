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

  /// O arquivo [path] (`<uid>/<nome>`) já está no Storage?
  Future<bool> exists(String path);
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

  @override
  Future<bool> exists(String path) async {
    final slash = path.lastIndexOf('/');
    final folder = path.substring(0, slash);
    final name = path.substring(slash + 1);
    final files = await _bucket.list(
      path: folder,
      searchOptions: sb.SearchOptions(limit: 10, search: name),
    );
    return files.any((f) => f.name == name);
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
  Future<bool> exists(String path) async => false;
}

/// Mantém as fotos locais espelhadas no Storage (H0). Local primeiro: o app
/// nunca espera a nuvem, e sem login ou sem rede nada se perde — a diferença
/// fica registrada em `recipes.image_synced_path` e é acertada na próxima
/// tentativa.
///
/// Caminho remoto: `<id-do-usuário>/<nome-do-arquivo>`; as policies do bucket
/// só deixam cada usuário mexer na própria pasta.
///
/// **Economia de espaço** (o plano gratuito tem 1 GB):
/// - o nome do arquivo é o hash do conteúdo, então foto igual é UM objeto;
/// - antes de enviar, confere se o arquivo já está na nuvem (backup restaurado,
///   outro aparelho, reinstalação) e, se estiver, só marca como enviado;
/// - arquivo compartilhado por mais de uma receita só sai da nuvem quando a
///   última deixa de usá-lo;
/// - a limpeza só apaga o que ESTE aparelho enviou ou adotou ([_owned]) e que
///   nenhuma receita usa mais — nunca mexe na foto de outro aparelho.
class RecipeImageSync {
  RecipeImageSync(this._remote, this._dao, this._images);

  final ImageRemote _remote;
  final RecipeDao _dao;
  final RecipeImageService _images;

  bool _running = false;

  static const _queueKey = 'image_remote_deletions';
  static const _ownedKey = 'image_owned_names';

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
        // Outra receita pode ter ficado com a mesma foto: aí ela é necessária.
        if (!await _dao.isRemoteImageUsed(name)) {
          debugPrint('imageSync: removendo $uid/$name (receita apagada)');
          await _remote.remove('$uid/$name');
          await _disown(name);
        }
      } catch (e) {
        debugPrint('imageSync.remove($name): $e');
        left.add(name);
      }
    }
    await prefs.setStringList(_queueKey, left);
  }

  Future<Set<String>> _owned() async {
    final prefs = await SharedPreferences.getInstance();
    return {...?prefs.getStringList(_ownedKey)};
  }

  Future<void> _own(Iterable<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = {...?prefs.getStringList(_ownedKey), ...names};
    await prefs.setStringList(_ownedKey, owned.toList());
  }

  Future<void> _disown(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final owned = {...?prefs.getStringList(_ownedKey)}..remove(name);
    await prefs.setStringList(_ownedKey, owned.toList());
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
      // Só sai da nuvem se nenhuma outra receita usa o mesmo arquivo.
      if (!await _dao.isRemoteImageUsed(synced, exceptRecipeId: id)) {
        debugPrint('imageSync: removendo $uid/$synced (receita $id)');
        await _remote.remove('$uid/$synced');
        await _disown(synced);
      }
      if (current == null) {
        await _dao.setImageSynced(id, null);
        return true;
      }
    }
    if (current == null) return false;

    final path = '$uid/$current';
    if (await _remote.exists(path)) {
      debugPrint('imageSync: $path já está na nuvem (receita $id)');
    } else {
      final file = await _images.fileFor(current);
      if (!await file.exists()) return false;
      debugPrint('imageSync: enviando $path (receita $id)');
      await _remote.upload(path, file);
    }
    await _own([current]);
    await _dao.setImageSynced(id, current);
    return true;
  }

  /// Apaga do Storage o que ESTE aparelho enviou (ou adotou) e que nenhuma
  /// receita usa mais — sobra de receita apagada, foto trocada. Devolve
  /// quantos apagou. Nunca lança.
  ///
  /// Não lista a pasta nem toca em arquivo que outro aparelho da mesma conta
  /// tenha enviado: a conta é uma só, mas as receitas ainda não sincronizam,
  /// então "sem uso aqui" não quer dizer "sem uso lá".
  Future<int> sweepRemoteOrphans() async {
    final uid = _remote.userId;
    if (uid == null) return 0;
    var removed = 0;
    try {
      final inUse = await _dao.referencedImageNames();
      // Quem já estava enviado antes desta lista existir também é nosso.
      await _own(await _dao.syncedImageNames());
      for (final name in (await _owned()).difference(inUse)) {
        try {
          debugPrint('imageSync: limpando sobra $uid/$name');
          await _remote.remove('$uid/$name');
          await _disown(name);
          removed++;
        } catch (e) {
          debugPrint('imageSync.sweep($name): $e');
        }
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
