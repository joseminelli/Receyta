import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Relógio dos timers — injetável pra teste (o relógio de verdade fica de fora).
final cookingClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// O que acontece quando um timer acaba: vibra e toca o som de alerta do
/// sistema. Injetável pra teste.
final cookingAlertProvider = Provider<void Function()>((ref) {
  return () {
    HapticFeedback.vibrate();
    SystemSound.play(SystemSoundType.alert);
  };
});

enum TimerPhase { running, paused, finished }

/// Um timer do modo cozinha. `key` identifica de onde veio ("cook" pro tempo
/// de cozimento da receita, "step-2-0" pro primeiro tempo do passo 3) — assim
/// o mesmo botão sabe se o timer dele já existe. `endsAt` só vale rodando;
/// parado, o que sobra está em `remaining`.
@immutable
class CookingTimer {
  const CookingTimer({
    required this.id,
    required this.recipeId,
    required this.label,
    required this.total,
    required this.remaining,
    required this.phase,
    this.key,
    this.endsAt,
    this.finishedAt,
  });

  final int id;
  final String recipeId;
  final String? key;
  final String label;
  final Duration total;
  final Duration remaining;
  final TimerPhase phase;
  final DateTime? endsAt;
  final DateTime? finishedAt;

  bool get isRunning => phase == TimerPhase.running;
  bool get isFinished => phase == TimerPhase.finished;

  CookingTimer copyWith({
    Duration? remaining,
    TimerPhase? phase,
    DateTime? endsAt,
    bool clearEndsAt = false,
    DateTime? finishedAt,
  }) =>
      CookingTimer(
        id: id,
        recipeId: recipeId,
        key: key,
        label: label,
        total: total,
        remaining: remaining ?? this.remaining,
        phase: phase ?? this.phase,
        endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
        finishedAt: finishedAt ?? this.finishedAt,
      );
}

/// Timers de cozinha (G1): vários ao mesmo tempo, cada um por receita. Vivem
/// enquanto o app vive — sair do modo cozinha pra olhar outra coisa não os
/// derruba. O tempo é calculado pelo horário de fim (`endsAt`), não por
/// contagem de ticks: se o app ficar em segundo plano, ao voltar o relógio
/// já está certo. (Tocar com o app fechado é o G6, notificação agendada.)
class CookingTimersNotifier extends Notifier<List<CookingTimer>> {
  /// Depois de acabar o alerta repete a cada [_repeatEvery] por até
  /// [_alertFor] — se você está de mão suja longe do celular, ele insiste.
  static const _repeatEvery = Duration(seconds: 3);
  static const _alertFor = Duration(seconds: 30);

  Timer? _ticker;
  int _nextId = 1;

  @override
  List<CookingTimer> build() {
    ref.onDispose(() => _ticker?.cancel());
    return const [];
  }

  DateTime _now() => ref.read(cookingClockProvider)();

  /// Cria e inicia um timer. Um [key] que já existe é reiniciado do zero.
  int start({
    required String recipeId,
    required String label,
    required Duration duration,
    String? key,
  }) {
    final id = _nextId++;
    final timer = CookingTimer(
      id: id,
      recipeId: recipeId,
      key: key,
      label: label,
      total: duration,
      remaining: duration,
      phase: TimerPhase.running,
      endsAt: _now().add(duration),
    );
    state = [
      for (final t in state)
        if (key == null || t.recipeId != recipeId || t.key != key) t,
      timer,
    ];
    _syncTicker();
    return id;
  }

  void pause(int id) => _update(id, (t) {
        if (!t.isRunning) return t;
        return t.copyWith(
          remaining: _clamp(t.endsAt!.difference(_now())),
          phase: TimerPhase.paused,
          clearEndsAt: true,
        );
      });

  void resume(int id) => _update(id, (t) {
        if (t.phase != TimerPhase.paused) return t;
        return t.copyWith(
          phase: TimerPhase.running,
          endsAt: _now().add(t.remaining),
        );
      });

  void toggle(int id) {
    final t = state.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    t.isRunning ? pause(id) : resume(id);
  }

  /// Volta ao tempo inicial e roda de novo (também serve pra "mais uma vez"
  /// num timer que acabou).
  void restart(int id) => _update(
      id,
      (t) => CookingTimer(
            id: t.id,
            recipeId: t.recipeId,
            key: t.key,
            label: t.label,
            total: t.total,
            remaining: t.total,
            phase: TimerPhase.running,
            endsAt: _now().add(t.total),
          ));

  /// Tira o timer da tela (cancelar um em andamento ou dispensar um que
  /// acabou).
  void cancel(int id) {
    state = [
      for (final t in state)
        if (t.id != id) t,
    ];
    _syncTicker();
  }

  /// Avança o relógio: atualiza o que falta, marca quem acabou (e alerta) e
  /// repete o alerta de quem continua tocando. Público pra teste.
  void tick() {
    final now = _now();
    var changed = false;
    final next = <CookingTimer>[];
    for (final t in state) {
      if (t.isRunning) {
        final left = t.endsAt!.difference(now);
        if (left <= Duration.zero) {
          _alert();
          next.add(t.copyWith(
            remaining: Duration.zero,
            phase: TimerPhase.finished,
            clearEndsAt: true,
            finishedAt: now,
          ));
        } else {
          next.add(t.copyWith(remaining: _clamp(left)));
        }
        changed = true;
      } else if (t.isFinished) {
        final since = now.difference(t.finishedAt!);
        if (since <= _alertFor &&
            since.inSeconds > 0 &&
            since.inSeconds % _repeatEvery.inSeconds == 0) {
          _alert();
        }
        next.add(t);
      } else {
        next.add(t);
      }
    }
    if (changed) state = next;
    _syncTicker();
  }

  Duration _clamp(Duration d) => d.isNegative ? Duration.zero : d;

  void _update(int id, CookingTimer Function(CookingTimer) change) {
    state = [for (final t in state) t.id == id ? change(t) : t];
    _syncTicker();
  }

  void _alert() {
    try {
      ref.read(cookingAlertProvider)();
    } catch (_) {
      // Vibrar/tocar é conveniência; falhar não pode derrubar o timer.
    }
  }

  /// O relógio de 1 s só gira enquanto há algo rodando ou ainda alertando;
  /// sem isso, nada de trabalho de fundo.
  void _syncTicker() {
    final now = _now();
    final needed = state.any(
      (t) =>
          t.isRunning ||
          (t.isFinished && now.difference(t.finishedAt!) <= _alertFor),
    );
    if (needed && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    } else if (!needed) {
      _ticker?.cancel();
      _ticker = null;
    }
  }
}

final cookingTimersProvider =
    NotifierProvider<CookingTimersNotifier, List<CookingTimer>>(
  CookingTimersNotifier.new,
);
