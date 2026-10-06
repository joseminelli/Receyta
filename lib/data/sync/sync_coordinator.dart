import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/sync/shared_remote.dart';
import 'package:receyta/data/sync/sync_engine.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/data/sync/sync_error.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/shared_sync_providers.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';

enum SyncPhase { idle, syncing, error }

/// O que a tela mostra do sync.
@immutable
class SyncState {
  const SyncState({
    this.enabled = false,
    this.phase = SyncPhase.idle,
    this.lastSyncAt,
    this.failure,
    this.problem,
  });

  /// Há conta conectada (sem ela não há o que sincronizar nem o que mostrar).
  final bool enabled;
  final SyncPhase phase;

  /// Última rodada que deu certo.
  final DateTime? lastSyncAt;

  /// Mensagem da última falha, enquanto durar (já em português, pronta pra
  /// mostrar).
  final String? failure;

  /// O que causou a falha — a tela e as novas tentativas dependem disso.
  final SyncProblem? problem;

  SyncState copyWith({
    bool? enabled,
    SyncPhase? phase,
    DateTime? lastSyncAt,
    String? failure,
    SyncProblem? problem,
    bool clearFailure = false,
  }) {
    return SyncState(
      enabled: enabled ?? this.enabled,
      phase: phase ?? this.phase,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      failure: clearFailure ? null : (failure ?? this.failure),
      problem: clearFailure ? null : (problem ?? this.problem),
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
  StreamSubscription<SharedChange>? _realtime;
  StreamSubscription<void>? _accountRealtime;
  String? _realtimeSpace;
  bool _disposed = false;
  bool _started = false;
  bool _running = false;
  bool _again = false;
  int _failures = 0;

  static const _lastSyncKey = 'sync_last_at';

  @override
  SyncState build() {
    ref.onDispose(() {
      _disposed = true;
      _cancelWork();
    });
    return const SyncState();
  }

  /// Liga os gatilhos. Idempotente. Enquanto não há conta, não toca em banco
  /// nem em rede.
  void start() {
    if (_started) return;
    _started = true;
    ref.listen<String?>(currentSpaceIdProvider, (previous, next) {
      if (!state.enabled) return;
      _watchSpace(next);
      requestSync(immediate: true);
    });
    ref.listen<AsyncValue<AppUser?>>(
      authUserProvider,
      (previous, next) => _onUser(next.valueOrNull),
      fireImmediately: true,
    );
  }

  /// Pede uma rodada. Com [immediate] não espera o atraso (login, botão);
  /// [after] troca o atraso padrão (avisos em tempo real usam um bem curto).
  void requestSync({bool immediate = false, Duration? after}) {
    if (!state.enabled) return;
    _debounce?.cancel();
    if (immediate) {
      unawaited(_run());
    } else {
      _debounce = Timer(
        after ?? ref.read(syncDebounceProvider),
        () => unawaited(_run()),
      );
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
    _watchAccount();
    _watchSpace(ref.read(currentSpaceIdProvider));
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

  /// Qualquer escrita em receitas, pastas, listas, calendário (o da pessoa e o
  /// dos outros da casa) ou histórico. Só vira rodada se sobrou algo
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
      db.sharedMeals,
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

  /// Escuta a conta em tempo real: outro aparelho da mesma pessoa gravou, vale
  /// uma rodada logo.
  void _watchAccount() {
    _accountRealtime?.cancel();
    _accountRealtime = ref.read(syncRemoteProvider).changes().listen(
          (_) => requestSync(after: const Duration(seconds: 1)),
          onError: (Object e) =>
              debugPrint('SyncCoordinator.accountRealtime: $e'),
        );
  }

  /// Escuta a casa em tempo real: mudança nos itens vira uma rodada logo; gente
  /// que entra ou sai manda reler a casa.
  void _watchSpace(String? spaceId) {
    if (_realtimeSpace == spaceId) return;
    _realtime?.cancel();
    _realtime = null;
    _realtimeSpace = spaceId;
    if (spaceId == null) return;
    _realtime = ref.read(sharedRemoteProvider).changes(spaceId).listen(
      (change) {
        switch (change) {
          case SharedChange.docs:
            requestSync(after: const Duration(seconds: 1));
          case SharedChange.members:
            unawaited(ref.read(spaceControllerProvider.notifier).refresh());
        }
      },
      onError: (Object e) => debugPrint('SyncCoordinator.realtime: $e'),
    );
  }

  Future<bool> _hasPendingChanges() async {
    if (await ref.read(syncEngineProvider).hasPending()) return true;
    final space = ref.read(currentSpaceIdProvider);
    if (space == null) return false;
    return ref.read(sharedSyncEngineProvider(space)).hasPending();
  }

  /// A rodada da casa, depois da da conta. `null` = não há casa.
  Future<Result<SyncReport>?> _syncShared() async {
    final space = ref.read(currentSpaceIdProvider);
    if (space == null) return null;
    return ref.read(sharedSyncEngineProvider(space)).sync();
  }

  Future<void> _run() async {
    if (!state.enabled) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _retry?.cancel();
    state = state.copyWith(phase: SyncPhase.syncing, clearFailure: true);

    Result<SyncReport> result;
    try {
      result = await ref.read(syncEngineProvider).sync();
      if (result is Ok<SyncReport>) {
        final shared = await _syncShared();
        if (shared is Err<SyncReport>) result = shared;
      }
    } catch (e) {
      _running = false;
      if (_disposed) return;
      _fail(classifySyncError(e));
      return;
    }
    _running = false;
    if (_disposed || !state.enabled) return;

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
        _fail(
          failure is SyncFailure
              ? failure
              : SyncFailure(SyncProblem.unknown, failure.message),
        );
    }
  }

  Future<void> _saveLastSync(DateTime at) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, at.toIso8601String());
  }

  /// Guarda a falha e agenda (ou não) a próxima tentativa conforme a causa:
  /// sessão vencida não melhora sozinha — espera a pessoa entrar de novo (ou o
  /// app voltar ao primeiro plano); espaço da nuvem acabado tenta raramente;
  /// o resto tenta com espera crescente.
  void _fail(SyncFailure failure) {
    _failures++;
    _again = false;
    state = state.copyWith(
      phase: SyncPhase.error,
      failure: failure.message,
      problem: failure.problem,
    );
    _retry?.cancel();
    _retry = null;

    final base = ref.read(syncRetryBaseProvider).inMilliseconds;
    final Duration? wait = switch (failure.problem) {
      SyncProblem.auth => null,
      // 20x a espera base: 10 minutos com a base de 30 s.
      SyncProblem.serverFull => Duration(milliseconds: base * 20),
      _ => Duration(
          milliseconds: base * (1 << (_failures - 1).clamp(0, 3)).clamp(1, 10),
        ),
    };
    if (wait != null) _retry = Timer(wait, () => unawaited(_run()));
  }

  void _cancelWork() {
    _debounce?.cancel();
    _retry?.cancel();
    _periodic?.cancel();
    _changes?.cancel();
    _realtime?.cancel();
    _accountRealtime?.cancel();
    _accountRealtime = null;
    _debounce = _retry = _periodic = null;
    _changes = null;
    _realtime = null;
    _realtimeSpace = null;
    _again = false;
  }
}

final syncCoordinatorProvider =
    NotifierProvider<SyncCoordinator, SyncState>(SyncCoordinator.new);
