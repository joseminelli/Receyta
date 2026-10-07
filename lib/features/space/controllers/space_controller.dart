import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/data/sync/shared_sync_engine.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';

/// A casa de quem está logado (ou nulo): o espaço compartilhado onde ficam as
/// listas de compras e o calendário que a pessoa divide com outras.
///
/// O servidor é a verdade sobre quem faz parte. O id da casa fica guardado no
/// aparelho (por conta) pra o app saber, sem internet, que as listas marcadas
/// como compartilhadas são de uma casa. Ao descobrir que não faz mais parte
/// (saiu, foi removida, a casa acabou), o que era compartilhado vira só da
/// pessoa e sobe pra conta — ninguém perde o que já tinha no aparelho.
class SpaceController extends AsyncNotifier<SpaceInfo?> {
  static const cachePrefix = 'space_cache_';

  SpaceRemote get _remote => ref.read(spaceRemoteProvider);

  @override
  Future<SpaceInfo?> build() async {
    final user = ref.watch(authUserProvider).valueOrNull;
    if (user == null) return null;
    ref.listen<String>(
      appSettingsProvider.select((s) => s.nickname),
      (previous, next) => unawaited(_publishName()),
    );
    final cachedId = await _readCache(user.id);
    if (cachedId != null) {
      Future.microtask(refresh);
      return SpaceInfo(
        id: cachedId,
        name: 'Casa',
        ownerId: '',
        members: const [],
      );
    }
    try {
      final info = await _remote.mySpace();
      if (info != null) await _writeCache(user.id, info.id);
      return info;
    } catch (e) {
      debugPrint('SpaceController.build: $e');
      return null;
    }
  }

  /// Relê a casa no servidor. Sem internet, mantém o que já sabe.
  Future<void> refresh() async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;
    final SpaceInfo? info;
    try {
      info = await _remote.mySpace();
    } catch (e) {
      debugPrint('SpaceController.refresh: $e');
      return;
    }
    final before = state.valueOrNull;
    if (info == null) {
      if (before != null) await _detach(user.id, before.id);
      state = const AsyncData(null);
      return;
    }
    await _writeCache(user.id, info.id);
    state = AsyncData(info);
    await _publishName(info);
  }

  /// Se o nome da pessoa na casa difere do que ela usa aqui (apelido editado,
  /// inclusive sem internet), manda o atual pra casa.
  Future<void> _publishName([SpaceInfo? known]) async {
    final user = ref.read(authUserProvider).valueOrNull;
    final info = known ?? state.valueOrNull;
    if (user == null || info == null || info.members.isEmpty) return;
    SpaceMember? me;
    for (final m in info.members) {
      if (m.userId == user.id) me = m;
    }
    final mine = displayName();
    if (me == null || me.displayName == mine) return;
    try {
      await _remote.setDisplayName(mine);
      state = AsyncData(SpaceInfo(
        id: info.id,
        name: info.name,
        ownerId: info.ownerId,
        members: [
          for (final m in info.members)
            m.userId == user.id
                ? SpaceMember(
                    userId: m.userId,
                    displayName: mine,
                    isOwner: m.isOwner,
                  )
                : m,
        ],
      ));
    } catch (e) {
      debugPrint('SpaceController.setDisplayName: $e');
    }
  }

  /// Como a pessoa aparece pros outros da casa: apelido, senão primeiro nome
  /// da conta, senão o começo do e-mail.
  String displayName() {
    final nickname = ref.read(appSettingsProvider).nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final user = ref.read(authUserProvider).valueOrNull;
    final name = (user?.name ?? '').trim();
    if (name.isNotEmpty) return name.split(RegExp(r'\s+')).first;
    final email = user?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Alguém';
  }

  Future<Result<SpaceInfo>> create() async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) {
      return const Err(ValidationFailure('Entre na sua conta.'));
    }
    try {
      final info = await _remote.createSpace(displayName());
      await _writeCache(user.id, info.id);
      state = AsyncData(info);
      return Ok(info);
    } catch (e) {
      return Err(failureForSpace(e));
    }
  }

  /// Gera um código novo de convite.
  Future<Result<String>> invite() async {
    try {
      return Ok(await _remote.createInvite());
    } catch (e) {
      return Err(failureForSpace(e));
    }
  }

  Future<Result<SpaceInfo>> join(String code) async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) {
      return const Err(ValidationFailure('Entre na sua conta.'));
    }
    final clean = normalizeInviteCode(code);
    if (clean.length < 4) {
      return const Err(ValidationFailure('Digite o código do convite.'));
    }
    try {
      final info = await _remote.joinSpace(clean, displayName());
      await _writeCache(user.id, info.id);
      state = AsyncData(info);
      return Ok(info);
    } catch (e) {
      return Err(failureForSpace(e));
    }
  }

  /// Sai da casa. Se for o dono, a casa acaba. O que era compartilhado fica no
  /// aparelho, agora só da pessoa.
  Future<Result<void>> leave() async {
    final user = ref.read(authUserProvider).valueOrNull;
    final current = state.valueOrNull;
    if (user == null || current == null) return const Ok(null);
    try {
      await _remote.leaveSpace();
    } catch (e) {
      return Err(failureForSpace(e));
    }
    await _detach(user.id, current.id);
    state = const AsyncData(null);
    return const Ok(null);
  }

  /// O dono muda o nome da casa.
  Future<Result<void>> rename(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return const Err(ValidationFailure('Dê um nome à casa.'));
    }
    try {
      await _remote.renameSpace(clean);
      await refresh();
      return const Ok(null);
    } catch (e) {
      return Err(failureForSpace(e));
    }
  }

  /// O dono passa a casa pra [userId]. Com [thenLeave], sai em seguida (a casa
  /// continua com os outros).
  Future<Result<void>> transferTo(String userId,
      {bool thenLeave = false}) async {
    try {
      await _remote.transferOwnership(userId);
    } catch (e) {
      return Err(failureForSpace(e));
    }
    if (thenLeave) return leave();
    await refresh();
    return const Ok(null);
  }

  Future<Result<void>> remove(String userId) async {
    try {
      await _remote.removeMember(userId);
      await refresh();
      return const Ok(null);
    } catch (e) {
      return Err(failureForSpace(e));
    }
  }

  /// Compartilha a lista com a casa, ou deixa de compartilhar.
  Future<Result<void>> setListShared(String listId, bool shared) async {
    final space = state.valueOrNull;
    if (shared && space == null) {
      return const Err(
        ValidationFailure('Crie ou entre numa casa para compartilhar.'),
      );
    }
    return ref
        .read(shoppingListRepositoryProvider)
        .setSpace(listId, shared ? space!.id : null);
  }

  Future<void> _detach(String userId, String spaceId) async {
    await ref.read(databaseProvider).detachSpace(spaceId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${SharedSyncEngine.cursorPrefix}$spaceId');
    await prefs.remove('$cachePrefix$userId');
    await prefs.remove('space_calendar_$userId');
    await prefs.remove('space_pantry_$userId');
  }

  Future<String?> _readCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$cachePrefix$userId');
  }

  Future<void> _writeCache(String userId, String spaceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$cachePrefix$userId', spaceId);
  }
}

final spaceControllerProvider =
    AsyncNotifierProvider<SpaceController, SpaceInfo?>(SpaceController.new);

/// O id da casa (ou nulo), pra quem só precisa saber se há uma.
final currentSpaceIdProvider = Provider<String?>(
  (ref) => ref.watch(spaceControllerProvider).valueOrNull?.id,
);

/// O código de convite dentro do que a pessoa digitou ou colou: se vier a
/// mensagem do convite inteira, pega os 8 caracteres do código; senão, o texto
/// limpo (sem espaços nem símbolos, em maiúsculas).
String normalizeInviteCode(String input) {
  final upper = input.toUpperCase();
  final token = RegExp(r'(?<![0-9A-Z])[0-9A-F]{8}(?![0-9A-Z])')
      .allMatches(upper)
      .map((m) => m.group(0)!)
      .where((t) => RegExp(r'[0-9]').hasMatch(t))
      .firstOrNull;
  if (token != null) return token;
  return upper.replaceAll(RegExp(r'[^0-9A-Z]'), '');
}

/// Nome atual de cada pessoa da casa, por id da conta. As refeições dos outros
/// trazem o nome de quando foram planejadas; este é o de agora.
final memberNamesProvider = Provider<Map<String, String>>((ref) {
  final members = ref.watch(spaceControllerProvider).valueOrNull?.members;
  return {
    for (final m in members ?? const <SpaceMember>[])
      if (m.displayName.isNotEmpty) m.userId: m.displayName,
  };
});
