import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/timer_notification_actions.dart';
import 'package:receyta/data/services/timers_store.dart';
import 'package:receyta/domain/models/cooking_timer.dart';

import '../../helpers/fake_timer_notifications.dart';

class _MemoryStore implements TimersStore {
  _MemoryStore(this.timers);

  List<CookingTimer>? timers;

  @override
  Future<List<CookingTimer>?> load() async => timers;

  @override
  Future<void> save(List<CookingTimer> value) async => timers = value;
}

void main() {
  final t0 = DateTime.utc(2026, 10, 1, 12);
  late DateTime now;
  late FakeTimerNotifications notifications;
  late _MemoryStore store;
  late ({bool vibrate, bool sound}) flags;

  CookingTimer running(int id,
          {Duration total = const Duration(minutes: 10)}) =>
      CookingTimer(
        id: id,
        recipeId: 'r$id',
        recipeName: 'Receita $id',
        label: 'Cozimento',
        total: total,
        remaining: total,
        phase: TimerPhase.running,
        endsAt: t0.add(total),
      );

  TimerNotificationActions actions() => TimerNotificationActions(
        store: store,
        notifications: notifications,
        alertFlags: () async => flags,
        clock: () => now,
      );

  setUp(() {
    now = t0;
    notifications = FakeTimerNotifications();
    store = _MemoryStore(
        [running(1), running(2, total: const Duration(minutes: 30))]);
    flags = (vibrate: true, sound: false);
  });

  CookingTimer stored(int id) => store.timers!.firstWhere((t) => t.id == id);

  test('Pausar: guarda o que falta e mostra a notificação de pausado',
      () async {
    now = t0.add(const Duration(minutes: 4));
    await actions().handle(actionId: kTimerActionPause, timerId: 1);

    expect(stored(1).phase, TimerPhase.paused);
    expect(stored(1).remaining, const Duration(minutes: 6));
    expect(notifications.calls, ['paused:1']);
    expect(
        notifications.pausedDetails[1]!.remaining, const Duration(minutes: 6));
    expect(stored(2).isRunning, isTrue); // o outro timer não é tocado
  });

  test('Retomar: volta a contar e reagenda o aviso com as chaves atuais',
      () async {
    now = t0.add(const Duration(minutes: 4));
    await actions().handle(actionId: kTimerActionPause, timerId: 1);
    notifications.calls.clear();

    now = t0.add(const Duration(minutes: 20));
    flags = (vibrate: false, sound: true);
    await actions().handle(actionId: kTimerActionResume, timerId: 1);

    expect(stored(1).isRunning, isTrue);
    expect(stored(1).endsAt, t0.add(const Duration(minutes: 26)));
    final shown = notifications.runningDetails[1]!;
    expect(shown.endsAt, t0.add(const Duration(minutes: 26)));
    expect(shown.vibrate, isFalse);
    expect(shown.sound, isTrue);
    expect(shown.title, 'Receita 1 · Cozimento');
  });

  test('+1 min: estende rodando e pausado e atualiza a notificação', () async {
    await actions().handle(actionId: kTimerActionPlusMinute, timerId: 1);
    expect(stored(1).endsAt, t0.add(const Duration(minutes: 11)));
    expect(notifications.runningDetails[1]!.endsAt,
        t0.add(const Duration(minutes: 11)));

    await actions().handle(actionId: kTimerActionPause, timerId: 1);
    await actions().handle(actionId: kTimerActionPlusMinute, timerId: 1);
    expect(stored(1).remaining, const Duration(minutes: 12));
    expect(
        notifications.pausedDetails[1]!.remaining, const Duration(minutes: 12));
  });

  test('Parar: tira o timer da lista guardada e a notificação', () async {
    await actions().handle(actionId: kTimerActionStop, timerId: 1);

    expect(store.timers!.map((t) => t.id), [2]);
    expect(notifications.calls, ['cancel:1']);
  });

  test('Repetir (do aviso "Pronto!"): reinicia do tempo total', () async {
    now = t0.add(const Duration(hours: 1));
    store.timers = [
      running(1).copyWith(
        phase: TimerPhase.finished,
        remaining: Duration.zero,
        clearEndsAt: true,
        finishedAt: t0.add(const Duration(minutes: 10)),
      ),
    ];
    await actions().handle(actionId: kTimerActionRestart, timerId: 1);

    expect(stored(1).isRunning, isTrue);
    expect(stored(1).remaining, const Duration(minutes: 10));
    expect(stored(1).endsAt, now.add(const Duration(minutes: 10)));
    expect(notifications.runningDetails[1], isNotNull);
  });

  test('timer que já não existe: só limpa a notificação, sem mexer na lista',
      () async {
    await actions().handle(actionId: kTimerActionPause, timerId: 99);

    expect(notifications.calls, ['cancel:99']);
    expect(store.timers!.length, 2);
  });

  test('nada guardado: não quebra', () async {
    store.timers = null;
    await actions().handle(actionId: kTimerActionPause, timerId: 1);
    expect(notifications.calls, ['cancel:1']);
  });

  test('ação desconhecida não muda nada', () async {
    final before = store.timers;
    await actions().handle(actionId: 'outra_coisa', timerId: 1);
    expect(store.timers, same(before));
    expect(notifications.calls, isEmpty);
  });

  test('pausar o que já está pausado é no-op (clique duplo)', () async {
    await actions().handle(actionId: kTimerActionPause, timerId: 1);
    notifications.calls.clear();
    await actions().handle(actionId: kTimerActionPause, timerId: 1);
    expect(notifications.calls, isEmpty);
  });
}
