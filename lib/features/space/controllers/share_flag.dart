import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

/// Uma escolha da pessoa sobre o que dividir com a casa (calendário, despensa,
/// listas novas). O servidor guarda a escolha, então ela volta sozinha ao
/// reinstalar o app ou entrar em outro aparelho; o aparelho só mantém uma cópia
/// pra funcionar sem internet. Escolhas feitas antes de existir o servidor
/// (servidor sem valor, cópia local ligada) sobem na primeira leitura. A
/// escolha vale por conta e some quando a pessoa sai da casa.
abstract class ShareFlagController extends AsyncNotifier<bool> {
  String get prefsPrefix;

  /// Nome da escolha no servidor (`set_share_pref`).
  String get field;

  String get noSpaceMessage;
  String get failureMessage;

  bool? serverValue(SharePrefs prefs);

  /// O que mais muda ao ligar ou desligar (ex.: subir o calendário).
  Future<void> apply(bool on, String spaceId) async {}

  @override
  Future<bool> build() async {
    final user = ref.watch(authUserProvider).valueOrNull;
    final space = ref.watch(currentSpaceIdProvider);
    if (user == null || space == null) return false;
    final server = ref.watch(mySharePrefsProvider);
    final prefs = await SharedPreferences.getInstance();
    final key = '$prefsPrefix${user.id}';
    final fromServer = server == null ? null : serverValue(server);
    if (fromServer != null) {
      await prefs.setBool(key, fromServer);
      return fromServer;
    }
    final local = prefs.getBool(key) ?? false;
    if (server != null && local) unawaited(_publish(true));
    return local;
  }

  Future<void> _publish(bool on) async {
    try {
      await ref.read(spaceRemoteProvider).setSharePref(field, on);
    } catch (e) {
      debugPrint('ShareFlagController.$field: $e');
    }
  }

  Future<Result<void>> set(bool on) async {
    final user = ref.read(authUserProvider).valueOrNull;
    final space = ref.read(currentSpaceIdProvider);
    if (user == null || space == null) {
      return Err(ValidationFailure(noSpaceMessage));
    }
    try {
      await ref.read(spaceRemoteProvider).setSharePref(field, on);
    } catch (e) {
      return Err(failureForSpace(e));
    }
    try {
      await apply(on, space);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$prefsPrefix${user.id}', on);
      await ref.read(spaceControllerProvider.notifier).refresh();
      state = AsyncData(on);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure(failureMessage, cause: e));
    }
  }
}
