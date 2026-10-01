import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/data/services/timers_store.dart';
import 'package:receyta/domain/models/cooking_timer.dart';

/// Ids dos botões da notificação de timer.
const kTimerActionPause = 'timer_pause';
const kTimerActionResume = 'timer_resume';
const kTimerActionPlusMinute = 'timer_plus_minute';
const kTimerActionStop = 'timer_stop';
const kTimerActionRestart = 'timer_restart';

/// O que cada botão da notificação faz — Dart puro, sobre os timers guardados
/// ([TimersStore]), sem Riverpod nem tela: roda num isolate de segundo plano,
/// com o app minimizado ou até fechado. Depois de mexer, regrava a lista e
/// atualiza a notificação (e o aviso agendado) pra refletir o novo estado.
///
/// Ao voltar ao app, o `CookingTimersNotifier` relê a lista guardada e a tela
/// reflete o que foi feito aqui.
class TimerNotificationActions {
  TimerNotificationActions({
    required this.store,
    required this.notifications,
    required this.alertFlags,
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final TimersStore store;
  final TimerNotifications notifications;

  /// As chaves de vibrar/som da faixa de timers, lidas na hora (o aviso
  /// agendado usa o canal certo pra combinação).
  final Future<({bool vibrate, bool sound})> Function() alertFlags;
  final DateTime Function() _clock;

  Future<void> handle({required String actionId, required int timerId}) async {
    final timers = await store.load() ?? const <CookingTimer>[];
    final index = timers.indexWhere((t) => t.id == timerId);
    if (index < 0) {
      // O timer já não existe (cancelado no app): só limpa a notificação.
      await notifications.cancel(timerId);
      return;
    }

    final now = _clock();
    final current = timers[index];

    if (actionId == kTimerActionStop) {
      await notifications.cancel(timerId);
      await store.save([
        for (final t in timers)
          if (t.id != timerId) t,
      ]);
      return;
    }

    final updated = switch (actionId) {
      kTimerActionPause => current.paused(now),
      kTimerActionResume => current.resumed(now),
      kTimerActionPlusMinute => current.extended(const Duration(minutes: 1)),
      kTimerActionRestart => current.restarted(now),
      _ => current,
    };
    if (identical(updated, current)) return;

    await store.save([
      for (final t in timers) t.id == timerId ? updated : t,
    ]);
    await _show(updated);
  }

  Future<void> _show(CookingTimer t) async {
    if (t.isRunning && t.endsAt != null) {
      final flags = await alertFlags();
      await notifications.showRunning(
        timerId: t.id,
        recipeId: t.recipeId,
        title: t.title,
        endsAt: t.endsAt!,
        vibrate: flags.vibrate,
        sound: flags.sound,
      );
    } else if (t.isPaused) {
      await notifications.showPaused(
        timerId: t.id,
        recipeId: t.recipeId,
        title: t.title,
        remaining: t.remaining,
      );
    } else {
      await notifications.cancel(t.id);
    }
  }
}
