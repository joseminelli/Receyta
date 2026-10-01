import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';

/// Relógio dos timers — injetável pra teste (o relógio de verdade fica de fora).
final cookingClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

/// O que acontece quando um timer acaba: vibra e/ou toca o alarme do aparelho,
/// conforme as chaves da faixa de timers (`cookingAlertSettingsProvider`, lidas
/// na hora de alertar). Quem vibra e toca é o `AlarmDriver`. Injetável pra
/// teste.
final cookingAlertProvider = Provider<void Function()>((ref) {
  return () {
    final settings = ref.read(cookingAlertSettingsProvider);
    final driver = ref.read(alarmDriverProvider);
    if (settings.vibrate) unawaited(driver.vibrate());
    if (settings.sound) unawaited(driver.playSound());
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
    this.recipeName = '',
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

  /// Nome da receita, pra faixa global dizer de qual é ("Frango · Passo 2").
  final String recipeName;
  final String? key;
  final String label;
  final Duration total;
  final Duration remaining;
  final TimerPhase phase;
  final DateTime? endsAt;
  final DateTime? finishedAt;

  bool get isRunning => phase == TimerPhase.running;
  bool get isFinished => phase == TimerPhase.finished;

  /// Pra guardar no aparelho: o timer sobrevive ao app ser fechado ou morto
  /// em segundo plano (o horário de fim é o que manda).
  Map<String, Object?> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'recipeName': recipeName,
        'key': key,
        'label': label,
        'total': total.inMilliseconds,
        'remaining': remaining.inMilliseconds,
        'phase': phase.name,
        'endsAt': endsAt?.millisecondsSinceEpoch,
        'finishedAt': finishedAt?.millisecondsSinceEpoch,
      };

  static CookingTimer? fromJson(Map<String, Object?> json) {
    try {
      DateTime? at(Object? ms) => ms == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(ms as int, isUtc: true);
      return CookingTimer(
        id: json['id']! as int,
        recipeId: json['recipeId']! as String,
        recipeName: (json['recipeName'] as String?) ?? '',
        key: json['key'] as String?,
        label: json['label']! as String,
        total: Duration(milliseconds: json['total']! as int),
        remaining: Duration(milliseconds: json['remaining']! as int),
        phase: TimerPhase.values.byName(json['phase']! as String),
        endsAt: at(json['endsAt']),
        finishedAt: at(json['finishedAt']),
      );
    } catch (_) {
      return null; // registro estragado: ignora, não derruba o app
    }
  }

  CookingTimer copyWith({
    Duration? remaining,
    TimerPhase? phase,
    DateTime? endsAt,
    bool clearEndsAt = false,
    DateTime? finishedAt,
    bool clearFinishedAt = false,
  }) =>
      CookingTimer(
        id: id,
        recipeId: recipeId,
        recipeName: recipeName,
        key: key,
        label: label,
        total: total,
        remaining: remaining ?? this.remaining,
        phase: phase ?? this.phase,
        endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
        finishedAt: clearFinishedAt ? null : (finishedAt ?? this.finishedAt),
      );
}

/// Timers de cozinha (G1): vários ao mesmo tempo, cada um por receita. Sair do
/// modo cozinha pra olhar outra coisa não os derruba, e eles ficam guardados no
/// aparelho (sobrevivem ao app ser morto). O tempo é calculado pelo horário de
/// fim (`endsAt`), não por contagem de ticks.
///
/// Com o app minimizado ([onBackground]) cada timer vira uma notificação do
/// sistema — relógio regressivo à vista e um aviso agendado pra hora certa,
/// que toca/vibra mesmo com o app em segundo plano. Ao voltar ([onForeground])
/// as notificações saem e a tela assume de novo.
class CookingTimersNotifier extends Notifier<List<CookingTimer>> {
  /// Depois de acabar o alerta repete a cada [_repeatEvery] por até
  /// [_alertFor] — se você está de mão suja longe do celular, ele insiste.
  static const _repeatEvery = Duration(seconds: 3);
  static const _alertFor = Duration(seconds: 30);

  /// Acabou há mais que isto = acabou com o app em segundo plano: a
  /// notificação já avisou, então a tela não vibra/toca de novo na volta.
  static const _staleAfter = Duration(seconds: 5);

  static const _prefsKey = 'cooking_timers_v1';
  static const _askedPermissionsKey = 'timer_notifications_asked';

  Timer? _ticker;
  int _nextId = 1;

  @override
  List<CookingTimer> build() {
    ref.onDispose(() => _ticker?.cancel());
    _restore();
    return const [];
  }

  DateTime _now() => ref.read(cookingClockProvider)();

  void _set(List<CookingTimer> timers) {
    state = timers;
    _persist();
  }

  /// Lê os timers guardados: rodando recalcula pelo horário de fim (se já
  /// passou, está "pronto"), parado fica como estava.
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final now = _now();
      final restored = <CookingTimer>[];
      for (final item in jsonDecode(raw) as List<Object?>) {
        final t = CookingTimer.fromJson((item! as Map).cast<String, Object?>());
        if (t == null) continue;
        if (t.isRunning && t.endsAt != null) {
          final left = t.endsAt!.difference(now);
          restored.add(left <= Duration.zero
              ? t.copyWith(
                  remaining: Duration.zero,
                  phase: TimerPhase.finished,
                  clearEndsAt: true,
                  finishedAt: t.endsAt,
                )
              : t.copyWith(remaining: left));
        } else {
          restored.add(t);
        }
      }
      if (restored.isEmpty) return;
      // O usuário pode ter iniciado um timer antes da leitura terminar.
      final liveIds = {for (final t in state) t.id};
      final merged = [
        for (final t in restored)
          if (!liveIds.contains(t.id)) t,
        ...state,
      ];
      final maxId = merged.fold<int>(0, (m, t) => t.id > m ? t.id : m);
      if (maxId >= _nextId) _nextId = maxId + 1;
      state = merged;
      _syncTicker();
    } catch (e) {
      debugPrint('CookingTimers._restore: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (state.isEmpty) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(
          _prefsKey,
          jsonEncode([for (final t in state) t.toJson()]),
        );
      }
    } catch (e) {
      debugPrint('CookingTimers._persist: $e');
    }
  }

  /// Na primeira vez que um timer começa, pede a permissão de notificação (e
  /// de alarme exato) — num momento em que o motivo é óbvio pro usuário.
  Future<void> _askPermissionsOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_askedPermissionsKey) ?? false) return;
      await prefs.setBool(_askedPermissionsKey, true);
      await ref.read(timerNotificationsProvider).requestPermissions();
    } catch (e) {
      debugPrint('CookingTimers._askPermissionsOnce: $e');
    }
  }

  String _title(CookingTimer t) =>
      [if (t.recipeName.isNotEmpty) t.recipeName, t.label].join(' · ');

  /// O app foi pro segundo plano: cada timer vira notificação (rodando: relógio
  /// regressivo + aviso agendado; pausado: o que falta, sem aviso).
  Future<void> onBackground() async {
    final svc = ref.read(timerNotificationsProvider);
    final settings = ref.read(cookingAlertSettingsProvider);
    for (final t in state) {
      if (t.isRunning && t.endsAt != null) {
        await svc.showRunning(
          timerId: t.id,
          recipeId: t.recipeId,
          title: _title(t),
          endsAt: t.endsAt!,
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
      } else if (t.phase == TimerPhase.paused) {
        await svc.showPaused(
          timerId: t.id,
          recipeId: t.recipeId,
          title: _title(t),
          remaining: t.remaining,
        );
      }
    }
  }

  /// O app voltou: tira as notificações (a tela assume) e acerta o relógio.
  Future<void> onForeground() async {
    final svc = ref.read(timerNotificationsProvider);
    for (final t in state) {
      await svc.cancel(t.id);
    }
    tick();
  }

  void _dropNotifications(int id) {
    try {
      unawaited(ref.read(timerNotificationsProvider).cancel(id));
    } catch (_) {
      // Notificação é conveniência; falhar não pode travar o timer.
    }
  }

  /// Cria e inicia um timer. Um [key] que já existe é reiniciado do zero.
  int start({
    required String recipeId,
    String recipeName = '',
    required String label,
    required Duration duration,
    String? key,
  }) {
    final id = _nextId++;
    final timer = CookingTimer(
      id: id,
      recipeId: recipeId,
      recipeName: recipeName,
      key: key,
      label: label,
      total: duration,
      remaining: duration,
      phase: TimerPhase.running,
      endsAt: _now().add(duration),
    );
    _set([
      for (final t in state)
        if (key == null || t.recipeId != recipeId || t.key != key) t,
      timer,
    ]);
    _syncTicker();
    unawaited(_askPermissionsOnce());
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
  void restart(int id) => _update(id, (t) {
        if (t.isFinished) _stopSound();
        return t.copyWith(
          remaining: t.total,
          phase: TimerPhase.running,
          endsAt: _now().add(t.total),
          clearFinishedAt: true,
        );
      });

  /// Tira o timer da tela (cancelar um em andamento ou dispensar um que
  /// acabou).
  void cancel(int id) {
    if (state.any((t) => t.id == id && t.isFinished)) _stopSound();
    _dropNotifications(id);
    _set([
      for (final t in state)
        if (t.id != id) t,
    ]);
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
          // Acabou na hora certa -> avisa. Acabou faz tempo (app em segundo
          // plano): a notificação já avisou, não repete.
          if (-left <= _staleAfter) _alert();
          next.add(t.copyWith(
            remaining: Duration.zero,
            phase: TimerPhase.finished,
            clearEndsAt: true,
            finishedAt: t.endsAt,
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
    if (changed) _set(next);
    _syncTicker();
  }

  Duration _clamp(Duration d) => d.isNegative ? Duration.zero : d;

  void _update(int id, CookingTimer Function(CookingTimer) change) {
    _set([for (final t in state) t.id == id ? change(t) : t]);
    _syncTicker();
  }

  void _stopSound() {
    try {
      unawaited(ref.read(alarmDriverProvider).stopSound());
    } catch (_) {
      // Parar o som é conveniência; falhar não pode travar o timer.
    }
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

/// Receita cujo modo cozinha está aberto agora (ou `null`). A faixa global de
/// timers esconde os dessa receita — a tela dela já tem a faixa grande.
final cookingModeRecipeIdProvider = StateProvider<String?>((ref) => null);

final cookingTimersProvider =
    NotifierProvider<CookingTimersNotifier, List<CookingTimer>>(
  CookingTimersNotifier.new,
);
