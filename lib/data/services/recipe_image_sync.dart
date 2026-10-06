import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';

/// Nome do bucket privado (ver `docs/supabase/recipe-images.sql`).
const kRecipeImagesBucket = 'recipe-images';

/// Quanto a conta já usa de fotos na nuvem e qual é o teto (o valor vem do
/// servidor — ver `docs/supabase/photo-quota.sql`).
typedef PhotoUsage = ({int usedBytes, int quotaBytes});

/// O servidor recusou a foto porque a conta chegou ao teto de fotos. Não é
/// erro de rede: não adianta tentar de novo até a pessoa liberar espaço.
class PhotoQuotaExceeded implements Exception {
  const PhotoQuotaExceeded([this.usage]);

  final PhotoUsage? usage;

  @override
  String toString() => 'PhotoQuotaExceeded($usage)';
}

/// O que o sync precisa do Storage. Injetável pra o teste não usar rede.
abstract class ImageRemote {
  /// `null` = ninguém logado: o sync não faz nada.
  String? get userId;

  Future<void> upload(String path, File file);
  Future<Uint8List> download(String path);
  Future<void> remove(String path);

  /// O arquivo [path] (`<uid>/<nome>`) já está no Storage?
  Future<bool> exists(String path);

  /// Uso de fotos da conta e o teto. `null` = o servidor não sabe dizer (o SQL
  /// do teto não foi rodado, sem rede…).
  Future<PhotoUsage?> usage();
}

class SupabaseImageRemote implements ImageRemote {
  SupabaseImageRemote(this._client);

  final sb.SupabaseClient _client;

  sb.StorageFileApi get _bucket => _client.storage.from(kRecipeImagesBucket);

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> upload(String path, File file) async {
    try {
      await _bucket.upload(
        path,
        file,
        fileOptions: const sb.FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
    } on sb.StorageException catch (e) {
      // A policy do bucket recusa com 403 quando a conta passou do teto. Só
      // vira "limite atingido" se o servidor confirmar que é isso mesmo (um
      // 403 também pode ser sessão vencida).
      if (e.statusCode == '403') {
        final u = await usage();
        if (u != null && u.usedBytes >= u.quotaBytes) {
          throw PhotoQuotaExceeded(u);
        }
      }
      rethrow;
    }
  }

  @override
  Future<PhotoUsage?> usage() async {
    try {
      final used = await _client.rpc('photo_usage_bytes');
      final quota = await _client.rpc('photo_quota_bytes');
      if (used is! num || quota is! num) return null;
      return (usedBytes: used.toInt(), quotaBytes: quota.toInt());
    } catch (_) {
      return null;
    }
  }

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

  @override
  Future<PhotoUsage?> usage() async => null;
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
  static const _blockedKey = 'image_quota_blocked';

  /// A conta chegou ao teto de fotos: fotos novas ficam só no aparelho (e
  /// pendentes) até a pessoa liberar espaço. Lembrado entre aberturas do app.
  bool _blocked = false;
  bool _blockedLoaded = false;
  bool _noticePending = false;

  bool get quotaBlocked => _blocked;

  /// `true` UMA vez por vez que o limite é atingido — quem mostra o aviso
  /// ("a foto ficou só neste aparelho") chama isto pra não repetir a cada
  /// tentativa.
  bool takeQuotaNotice() {
    final pending = _noticePending;
    _noticePending = false;
    return pending;
  }

  Future<void> _loadBlocked() async {
    if (_blockedLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _blocked = prefs.getBool(_blockedKey) ?? false;
    _blockedLoaded = true;
  }

  Future<void> _setBlocked(bool value) async {
    if (_blocked == value) return;
    _blocked = value;
    if (value) _noticePending = true;
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_blockedKey, true);
    } else {
      await prefs.remove(_blockedKey);
    }
  }

  /// Bloqueado: o servidor ainda diz que a conta está cheia? Se já sobrou
  /// espaço (a pessoa apagou fotos), volta a enviar. Se o servidor não sabe
  /// dizer, também tenta de novo — quem decide é a recusa dele.
  Future<void> _recheckBlocked() async {
    if (!_blocked) return;
    final usage = await _remote.usage();
    if (usage == null || usage.usedBytes < usage.quotaBytes) {
      await _setBlocked(false);
    }
  }

  /// Uso e teto da conta, mais quantas fotos estão esperando espaço. `null` =
  /// o servidor não informou (sem login, sem rede, SQL do teto não rodado).
  Future<PhotoQuota?> quota() async {
    if (_remote.userId == null) return null;
    await _loadBlocked();
    final usage = await _remote.usage();
    if (usage == null) return null;
    final pending = (await _dao.pendingImageSync())
        .where((r) => r.imagePath != null)
        .length;
    return PhotoQuota(
      usedBytes: usage.usedBytes,
      quotaBytes: usage.quotaBytes,
      blocked: _blocked || usage.usedBytes >= usage.quotaBytes,
      pending: pending,
    );
  }

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
      await _loadBlocked();
      try {
        await _recheckBlocked();
      } catch (e) {
        debugPrint('imageSync.recheck: $e');
      }
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
    // Conta cheia: a foto continua pendente (e boa no aparelho) até sobrar
    // espaço. Nem tenta enviar de novo à toa.
    if (_blocked) return false;

    final path = '$uid/$current';
    if (await _remote.exists(path)) {
      debugPrint('imageSync: $path já está na nuvem (receita $id)');
    } else {
      final file = await _images.fileFor(current);
      if (!await file.exists()) return false;
      debugPrint('imageSync: enviando $path (receita $id)');
      try {
        await _remote.upload(path, file);
      } on PhotoQuotaExceeded {
        debugPrint('imageSync: limite de fotos da conta atingido');
        await _setBlocked(true);
        return false;
      }
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

/// Como está o espaço de fotos da conta (pra tela).
@immutable
class PhotoQuota {
  const PhotoQuota({
    required this.usedBytes,
    required this.quotaBytes,
    required this.blocked,
    required this.pending,
  });

  final int usedBytes;
  final int quotaBytes;

  /// Cheia: fotos novas ficam só no aparelho.
  final bool blocked;

  /// Fotos que estão esperando espaço pra subir.
  final int pending;

  double get fraction =>
      quotaBytes <= 0 ? 0 : (usedBytes / quotaBytes).clamp(0.0, 1.0);

  /// Passou de 80%: hora de avisar antes de bloquear.
  bool get nearLimit => !blocked && fraction >= 0.8;
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

/// Uso de fotos da conta pra tela. Refaz sozinho depois de cada rodada de
/// sincronização (que é quando o que a pessoa apagou ou enviou já contou no
/// servidor).
final photoQuotaProvider = FutureProvider.autoDispose<PhotoQuota?>((ref) {
  ref.watch(syncCoordinatorProvider.select((s) => s.lastSyncAt));
  return ref.watch(recipeImageSyncProvider).quota();
});
