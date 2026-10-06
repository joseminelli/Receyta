import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/recipe_image_service.dart';

/// O que o "apagar tudo da conta" precisa do servidor. Injetável pra o teste
/// não usar rede.
abstract class AccountDataRemote {
  /// `null` = ninguém logado.
  String? get userId;

  /// Apaga todos os itens sincronizados (receitas, pastas…) da conta.
  Future<void> deleteAllDocs();

  /// Apaga todas as fotos da conta no Storage.
  Future<void> deleteAllImages();

  /// Exclui a conta de login e tudo dela no servidor (função `delete-account`,
  /// que precisa de permissão que o app não tem).
  Future<void> deleteAccount();
}

class SupabaseAccountDataRemote implements AccountDataRemote {
  SupabaseAccountDataRemote(this._client);

  final sb.SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> deleteAllDocs() async {
    final uid = userId;
    if (uid == null) return;
    try {
      await _client.from('sync_docs').delete().eq('user_id', uid);
    } on sb.PostgrestException catch (e) {
      // Tabela ainda não criada (o SQL do sync não foi rodado): não há o que
      // apagar, e isso não pode impedir limpar o resto.
      const missingTable = {'42P01', 'PGRST205'};
      if (!missingTable.contains(e.code)) rethrow;
    }
  }

  @override
  Future<void> deleteAllImages() async {
    final uid = userId;
    if (uid == null) return;
    final bucket = _client.storage.from(kAccountImagesBucket);
    // Apagar muda a listagem, então relê do começo até a pasta esvaziar.
    for (var round = 0; round < 1000; round++) {
      final files = await bucket.list(
        path: uid,
        searchOptions: const sb.SearchOptions(limit: 100),
      );
      final paths = [
        for (final f in files)
          if (f.id != null) '$uid/${f.name}',
      ];
      if (paths.isEmpty) return;
      await bucket.remove(paths);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status != 200) {
      throw Exception('delete-account respondeu ${response.status}');
    }
  }
}

/// Bucket das fotos (ver `docs/supabase/recipe-images.sql`).
const kAccountImagesBucket = 'recipe-images';

class NoAccountDataRemote implements AccountDataRemote {
  const NoAccountDataRemote();

  @override
  String? get userId => null;

  @override
  Future<void> deleteAllDocs() async {}

  @override
  Future<void> deleteAllImages() async {}

  @override
  Future<void> deleteAccount() async {}
}

/// "Limpar dados" (RF-08.4), em duas medidas. A confirmação e os avisos ficam
/// na UI (`SettingsPage`); este serviço só executa depois que o usuário já
/// confirmou.
///
/// - [wipeAll]: só ESTE aparelho. A conta, se houver, continua com a cópia —
///   que volta na próxima sincronização.
/// - [wipeEverything]: este aparelho E a conta (itens sincronizados e fotos).
class DataResetService {
  DataResetService(this._db, {AccountDataRemote? remote, this.images})
      : _remote = remote ?? const NoAccountDataRemote();

  final AppDatabase _db;
  final AccountDataRemote _remote;
  final RecipeImageService? images;

  /// Chaves de `shared_preferences` do sync e das fotos.
  static const syncCursorPrefix = 'sync_cursor_';
  static const imageOwnedKey = 'image_owned_names';
  static const imageDeletionQueueKey = 'image_remote_deletions';
  static const imageQuotaBlockedKey = 'image_quota_blocked';

  /// Só este aparelho: banco, arquivos de foto e o estado do sync.
  Future<Result<void>> wipeAll() async {
    try {
      await _wipeLocal(clearDeletionQueue: false);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao limpar os dados', cause: e));
    }
  }

  /// A conta primeiro, o aparelho depois: se a nuvem falhar (sem rede, por
  /// exemplo) nada local é apagado, e dá pra tentar de novo sem ter perdido o
  /// que só existe aqui. Exige estar conectado.
  Future<Result<void>> wipeEverything() async {
    if (_remote.userId == null) {
      return const Err(
        ValidationFailure('Entre na sua conta para apagar os dados dela.'),
      );
    }
    try {
      await _remote.deleteAllImages();
      await _remote.deleteAllDocs();
    } catch (e) {
      return Err(NetworkFailure(
        'Não foi possível apagar os dados da conta. '
        'Nada foi apagado neste aparelho; tente de novo.',
        cause: e,
      ));
    }
    try {
      await _wipeLocal(clearDeletionQueue: true);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure(
        'Os dados da conta foram apagados, mas falhou limpar este aparelho.',
        cause: e,
      ));
    }
  }

  /// Exclui a CONTA (login + dados na nuvem) e deixa este aparelho pronto pra
  /// seguir sem conta: as receitas e fotos daqui ficam, mas tudo volta a "nunca
  /// sincronizado" — se a pessoa entrar de novo será uma conta nova, e o que
  /// está aqui sobe do zero. Exige estar conectado. Se o servidor falhar nada
  /// muda. Quem chama deve sair da sessão depois.
  Future<Result<void>> deleteAccount() async {
    if (_remote.userId == null) {
      return const Err(
        ValidationFailure('Entre na sua conta para poder excluí-la.'),
      );
    }
    try {
      await _remote.deleteAccount();
    } catch (e) {
      return Err(NetworkFailure(
        'Não foi possível excluir a conta agora. '
        'Nada foi apagado; tente de novo.',
        cause: e,
      ));
    }
    try {
      await _db.resetSyncState();
      await _clearSyncPrefs(clearDeletionQueue: true);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure(
        'A conta foi excluída, mas falhou preparar este aparelho.',
        cause: e,
      ));
    }
  }

  Future<void> _clearSyncPrefs({required bool clearDeletionQueue}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(syncCursorPrefix)) await prefs.remove(key);
    }
    // A lista do que este aparelho enviou NÃO pode sobreviver: com o banco
    // vazio, a limpeza de fotos trataria tudo que ela cita como órfão e
    // apagaria da nuvem fotos que a conta ainda usa.
    await prefs.remove(imageOwnedKey);
    // O bloqueio por conta cheia era da conta antiga / do que havia aqui.
    await prefs.remove(imageQuotaBlockedKey);
    if (clearDeletionQueue) await prefs.remove(imageDeletionQueueKey);
  }

  Future<void> _wipeLocal({required bool clearDeletionQueue}) async {
    await _db.wipeUserData();
    // Sem receita nenhuma, toda foto local é órfã.
    await images?.deleteOrphans(const {});

    await _clearSyncPrefs(clearDeletionQueue: clearDeletionQueue);
    debugPrint('DataResetService: dados locais limpos');
  }
}

final accountDataRemoteProvider = Provider<AccountDataRemote>((ref) {
  try {
    return SupabaseAccountDataRemote(sb.Supabase.instance.client);
  } catch (_) {
    return const NoAccountDataRemote();
  }
});

final dataResetServiceProvider = Provider<DataResetService>((ref) {
  return DataResetService(
    ref.watch(databaseProvider),
    remote: ref.watch(accountDataRemoteProvider),
    images: ref.watch(recipeImageServiceProvider),
  );
});
