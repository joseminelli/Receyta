import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/data/services/timers_store.dart';
import 'package:receyta/domain/models/cooking_timer.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';

export 'package:receyta/domain/models/cooking_timer.dart';

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

/// Timers de cozinha (G1): vários ao mesmo tempo, cada um por receita. Sair do
/// modo cozinha pra olhar outra coisa não os derruba, e eles ficam guardados no
/// aparelho (sobrevivem ao app ser morto). O tempo é calculado pelo horário de
/// fim (`endsAt`), não por contagem de ticks.
///
/// Com o app minimizado ([onBackground]) cada timer vira uma notificação do
/// sistema — relógio regressivo à vista, botões (pausar, +1 min, parar) e um
/// aviso agendado pra hora certa, que toca/vibra mesmo com o app em segundo
/// plano. Os botões mexem nos timers guardados; ao voltar ([onForeground]) o
/// app relê o que foi guardado, as notificações saem e a tela assume.
class CookingTimersNotifier extends Notifier<List<CookingTimer>> {
  /// Depois de acabar o alerta repete a cada [_repeatEvery] por até
  /// [_alertFor] — se você está de mão suja longe do celular, ele insiste.
  static const _repeatEvery = Duration(seconds: 3);
  static const _alertFor = Duration(seconds: 30);

  /// Acabou há mais que isto = acabou com o app em segundo plano: a
  /// notificação já avisou, então a tela não vibra/toca de novo na volta.
  static const _staleAfter = Duration(seconds: 5);

  static const _askedPermissionsKey = 'timer_notifications_asked';

  Timer? _ticker;
  int _nextId = 1;

  /// Com o app minimizado a notificação é quem manda (os botões dela mexem nos
  /// timers guardados). A tela fica quieta: sem relógio de 1 s e sem gravar o
  /// estado dela por cima do que a notificação gravou.
  bool _inBackground = false;

  @override
  List<CookingTimer> build() {
    ref.onDispose(() => _ticker?.cancel());
    _restore();
    return const [];
  }

  DateTime _now() => ref.read(cookingClockProvider)();

  void _set(List<CookingTimer> timers) {
    state = timers;
    if (!_inBackground) _persist();
  }

  /// Rodando recalcula pelo horário de fim (se já passou, está "pronto", com o
  /// fim de verdade como hora em que acabou); parado fica como estava.
  CookingTimer _recalc(CookingTimer t, DateTime now) {
    if (!t.isRunning || t.endsAt == null) return t;
    final left = t.endsAt!.difference(now);
    return left <= Duration.zero
        ? t.copyWith(
            remaining: Duration.zero,
            phase: TimerPhase.finished,
            clearEndsAt: true,
            finishedAt: t.endsAt,
          )
        : t.copyWith(remaining: left);
  }

  /// Lê os timers guardados. Na abertura, só acrescenta (o usuário pode ter
  /// iniciado um antes da leitura terminar); com [replace], na volta de
  /// segundo plano, a lista guardada manda — os botões da notificação
  /// pausaram/cancelaram timers lá.
  Future<void> _restore({bool replace = false}) async {
    try {
      final stored = await ref.read(timersStoreProvider).load();
      if (stored == null) return;
      final now = _now();
      final restored = [for (final t in stored) _recalc(t, now)];

      if (replace) {
        state = restored;
      } else {
        if (restored.isEmpty) return;
        final liveIds = {for (final t in state) t.id};
        state = [
          for (final t in restored)
            if (!liveIds.contains(t.id)) t,
          ...state,
        ];
      }
      final maxId = state.fold<int>(0, (m, t) => t.id > m ? t.id : m);
      if (maxId >= _nextId) _nextId = maxId + 1;
      _syncTicker();
    } catch (e) {
      debugPrint('CookingTimers._restore: $e');
    }
  }

  Future<void> _persist() async {
    try {
      await ref.read(timersStoreProvider).save(state);
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

  /// O app foi pro segundo plano: cada timer vira notificação (rodando: relógio
  /// regressivo + aviso agendado; pausado: o que falta, sem aviso).
  Future<void> onBackground() async {
    // O disco em dia antes de o processo poder ser morto: os botões da
    // notificação partem do que está guardado. Dali em diante a tela se cala.
    await _persist();
    _inBackground = true;
    _ticker?.cancel();
    _ticker = null;
    final svc = ref.read(timerNotificationsProvider);
    final settings = ref.read(cookingAlertSettingsProvider);
    for (final t in state) {
      if (t.isRunning && t.endsAt != null) {
        await svc.showRunning(
          timerId: t.id,
          recipeId: t.recipeId,
          title: t.title,
          endsAt: t.endsAt!,
          vibrate: settings.vibrate,
          sound: settings.sound,
        );
      } else if (t.isPaused) {
        await svc.showPaused(
          timerId: t.id,
          recipeId: t.recipeId,
          title: t.title,
          remaining: t.remaining,
        );
      }
    }
  }

  /// O app voltou: relê os timers guardados (os botões da notificação podem
  /// ter pausado/estendido/cancelado), tira as notificações e acerta o relógio.
  Future<void> onForeground() async {
    _inBackground = false;
    await _restore(replace: true);
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

  void pause(int id) => _update(id, (t) => t.paused(_now()));

  void resume(int id) => _update(id, (t) => t.resumed(_now()));

  void toggle(int id) {
    final t = state.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    t.isRunning ? pause(id) : resume(id);
  }

  /// Soma [by] ao que falta (rodando ou pausado).
  void addTime(int id, Duration by) => _update(id, (t) => t.extended(by));

  /// Volta ao tempo inicial e roda de novo (também serve pra "mais uma vez"
  /// num timer que acabou).
  void restart(int id) => _update(id, (t) {
        if (t.isFinished) _stopSound();
        return t.restarted(_now());
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
          next.add(_recalc(t, now));
        } else {
          next.add(t.copyWith(remaining: left));
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
    if (_inBackground) return;
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
