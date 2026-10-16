import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/billing_service.dart';
import 'package:receyta/data/subscription/cloud_access_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';

/// Relógio do acesso (testes trocam).
final accessClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// Quanto esperar entre as conferências depois de uma compra, caso o servidor
/// ainda não tenha registrado a assinatura. `null` = não repete (testes).
final accessPollProvider =
    Provider<Duration?>((ref) => const Duration(seconds: 1));

/// O acesso à parte online de quem está logado. O servidor é a verdade; a
/// última resposta fica guardada no aparelho (por conta) pra o app saber, sem
/// internet, se pode sincronizar. Sem conta, sem acesso.
class CloudAccessController extends AsyncNotifier<CloudAccess> {
  static const cachePrefix = 'cloud_access_';

  BillingService get _billing => ref.read(billingServiceProvider);
  CloudAccessRemote get _remote => ref.read(cloudAccessRemoteProvider);

  @override
  Future<CloudAccess> build() async {
    final user = ref.watch(authUserProvider).valueOrNull;
    if (user == null) {
      unawaited(_billing.logOut());
      return CloudAccess.none;
    }
    unawaited(_billing.logIn(user.id));
    final cached = await _readCache(user.id);
    if (cached != null) {
      Future.microtask(refresh);
      return cached;
    }
    return await _fetch(user.id) ?? CloudAccess.none;
  }

  Future<CloudAccess?> _fetch(String userId) async {
    try {
      final access = await _remote.fetch();
      await _writeCache(userId, access);
      return access;
    } catch (e) {
      debugPrint('CloudAccess.fetch: $e');
      return null;
    }
  }

  /// Pergunta de novo ao servidor. Sem internet, mantém o que já sabe.
  Future<void> refresh() async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;
    final access = await _fetch(user.id);
    if (access != null) state = AsyncData(access);
  }

  /// Depois de comprar ou restaurar: manda o servidor conferir a assinatura na
  /// loja agora e espera o acesso ligar. Devolve se ligou.
  Future<bool> activate() async {
    bool? confirmed;
    try {
      confirmed = await _remote.syncSubscription();
    } catch (e) {
      debugPrint('CloudAccess.activate: $e');
    }
    if (confirmed == false) {
      await refresh();
      return _active;
    }
    final wait = ref.read(accessPollProvider);
    for (var i = 0; i < 15; i++) {
      await refresh();
      if (_active) return true;
      if (wait == null) break;
      await Future<void>.delayed(wait);
    }
    return _active;
  }

  bool get _active =>
      state.valueOrNull?.isActiveAt(ref.read(accessClockProvider)()) ?? false;

  /// Só a loja: `Ok(true)` = a compra foi confirmada (falta [activate] ligar o
  /// acesso no servidor); `Ok(false)` = a pessoa fechou a tela da loja.
  Future<Result<bool>> purchase(PlanOption plan) => _billing.purchase(plan);

  /// Só a loja: `Ok(true)` = há uma assinatura pra restaurar.
  Future<Result<bool>> restore() => _billing.restore();

  Future<CloudAccess?> _readCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$cachePrefix$userId');
    if (raw == null) return null;
    try {
      return CloudAccess.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String userId, CloudAccess access) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$cachePrefix$userId', jsonEncode(access.toJson()));
  }
}

final cloudAccessProvider =
    AsyncNotifierProvider<CloudAccessController, CloudAccess>(
  CloudAccessController.new,
);

/// A pessoa pode usar a parte online agora? É isto que liga e desliga o
/// sync, a casa e as fotos na nuvem.
final hasCloudAccessProvider = Provider<bool>((ref) {
  final access = ref.watch(cloudAccessProvider).valueOrNull;
  if (access == null) return false;
  return access.isActiveAt(ref.watch(accessClockProvider)());
});
