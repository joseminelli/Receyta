import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/sync/sync_engine.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';

enum SyncPhase { idle, syncing, error }

/// O que a tela mostra do sync.
@immutable
class SyncState {
  const SyncState({
    this.enabled = false,
    this.phase = SyncPhase.idle,
    this.lastSyncAt,
    this.failure,
  });

  /// Há conta conectada (sem ela não há o que sincronizar nem o que mostrar).
  final bool enabled;
  final SyncPhase phase;

  /// Última rodada que deu certo.
  final DateTime? lastSyncAt;

  /// Mensagem da última falha, enquanto durar.
  final String? failure;

  SyncState copyWith({
    bool? enabled,
    SyncPhase? phase,
    DateTime? lastSyncAt,
    String? failure,
    bool clearFailure = false,
  }) {
    return SyncState(
      enabled: enabled ?? this.enabled,
      phase: phase ?? this.phase,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Quanto esperar depois de uma mudança antes de sincronizar (agrupa uma
/// sequência de edições numa rodada só).
final syncDebounceProvider =
    Provider<Duration>((ref) => const Duration(seconds: 4));

/// De quanto em quanto tempo puxar mudanças de outros aparelhos com o app
/// aberto. `null` desliga (testes).
final syncPeriodProvider =
    Provider<Duration?>((ref) => const Duration(minutes: 3));

/// Espera base antes de tentar de novo depois de uma falha (dobra a cada
/// falha seguida, até 10 vezes isto).
final syncRetryBaseProvider =
    Provider<Duration>((ref) => const Duration(seconds: 30));

final syncClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Decide QUANDO sincronizar e guarda o estado pra tela. O trabalho em si é do
/// [SyncEngine].
///
/// Gatilhos: entrar na conta, qualquer mudança em receitas/pastas (com
/// atraso), voltar pro app, um relógio de poucos minutos e o botão
/// "Sincronizar agora". Uma rodada nunca roda em cima de outra: o pedido que
/// chega no meio vira UMA rodada extra depois. Falha de rede tenta de novo
/// sozinha, com espera crescente.
class SyncCoordinator extends Notifier<SyncState> {
  Timer? _debounce;
  Timer? _retry;
  Timer? _periodic;
  StreamSubscription<Object?>? _changes;
  bool _started = false;
  bool _running = false;
  bool _again = false;
  int _failures = 0;

  static const _lastSyncKey = 'sync_last_at';

  @override
  SyncState build() {
    ref.onDispose(_cancelWork);
    return const SyncState();
  }

  /// Liga os gatilhos. Idempotente. Enquanto não há conta, não toca em banco
  /// nem em rede.
  void start() {
    if (_started) return;
    _started = true;
    ref.listen<AsyncValue<AppUser?>>(
      authUserProvider,
      (previous, next) => _onUser(next.valueOrNull),
      fireImmediately: true,
    );
  }

  /// Pede uma rodada. Com [immediate] não espera o atraso (login, botão).
  void requestSync({bool immediate = false}) {
    if (!state.enabled) return;
    _debounce?.cancel();
    if (immediate) {
      unawaited(_run());
    } else {
      _debounce =
          Timer(ref.read(syncDebounceProvider), () => unawaited(_run()));
    }
  }

  /// O app voltou ao primeiro plano: só sincroniza se já faz um tempo.
  void onResumed({Duration minGap = const Duration(seconds: 30)}) {
    if (!state.enabled || _running) return;
    final last = state.lastSyncAt;
    final now = ref.read(syncClockProvider)();
    if (last == null || now.difference(last) >= minGap) {
      requestSync(immediate: true);
    }
  }

  // -------------------------------------------------------------------------

  void _onUser(AppUser? user) {
    if (user == null) {
      _cancelWork();
      _failures = 0;
      state = const SyncState();
      return;
    }
    if (state.enabled) return;
    state = state.copyWith(enabled: true);
    unawaited(_loadLastSync());
    _watchChanges();
    final period = ref.read(syncPeriodProvider);
    if (period != null) {
      _periodic = Timer.periodic(period, (_) => onResumed(minGap: period));
    }
    requestSync(immediate: true);
  }

  Future<void> _loadLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DateTime.tryParse(prefs.getString(_lastSyncKey) ?? '');
    if (saved != null && state.lastSyncAt == null && state.enabled) {
      state = state.copyWith(lastSyncAt: saved.toUtc());
    }
  }

  /// Qualquer escrita em receitas ou pastas. Só vira rodada se sobrou algo
  /// pendente de envio — a própria sincronização grava no banco ao aplicar o
  /// que veio da nuvem, e isso não deve disparar outra rodada.
  void _watchChanges() {
    final db = ref.read(databaseProvider);
    _changes?.cancel();
    _changes = db
        .tableUpdates(TableUpdateQuery.onAllTables([
      db.recipes,
      db.folders,
      db.mealPlanEntries,
      db.shoppingLists,
      db.shoppingListItems,
      db.cookLogs,
      db.ingredients,
      db.syncTombstones,
    ]))
        .listen((_) async {
      if (!state.enabled) return;
      if (await _hasPendingChanges()) requestSync();
    });
  }

  Future<bool> _hasPendingChanges() =>
      ref.read(syncEngineProvider).hasPending();

  Future<void> _run() async {
    if (!state.enabled) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _retry?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing, clearFailure: true);

    final Result<SyncReport> result;
    try {
      result = await ref.read(syncEngineProvider).sync();
    } catch (e) {
      _running = false;
      _fail('Não foi possível sincronizar agora.');
      return;
    }
    _running = false;
    if (!state.enabled) return;

    switch (result) {
      case Ok():
        _failures = 0;
        final now = ref.read(syncClockProvider)().toUtc();
        state = state.copyWith(
          phase: SyncPhase.idle,
          lastSyncAt: now,
          clearFailure: true,
        );
        unawaited(_saveLastSync(now));
        if (_again || await _hasPendingChanges()) {
          _again = false;
          requestSync();
        }
      case Err(:final failure):
        _fail(failure.message);
    }
  }

  Future<void> _saveLastSync(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, at.toIso8601String());
  }

  void _fail(String message) {
    _failures++;
    _again = false;
    state = state.copyWith(phase: SyncPhase.error, failure: message);
    // 1x, 2x, 4x, 8x e no máximo 10x a espera base (30 s → até 5 min).
    final base = ref.read(syncRetryBaseProvider).inMilliseconds;
    final factor = (1 << (_failures - 1).clamp(0, 3)).clamp(1, 10);
    _retry?.cancel();
    _retry = Timer(
      Duration(milliseconds: base * factor),
      () => unawaited(_run()),
    );
  }

  void _cancelWork() {
    _debounce?.cancel();
    _retry?.cancel();
    _periodic?.cancel();
    _changes?.cancel();
    _debounce = _retry = _periodic = null;
    _changes = null;
    _again = false;
  }
}

final syncCoordinatorProvider =
    NotifierProvider<SyncCoordinator, SyncState>(SyncCoordinator.new);
