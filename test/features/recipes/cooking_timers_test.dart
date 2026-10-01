import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/data/services/timer_notification_actions.dart';
import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/data/services/timers_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';

import '../../helpers/fake_alarm_driver.dart';
import '../../helpers/fake_timer_notifications.dart';

void main() {
  late DateTime now;
  late int alerts;
  late FakeAlarmDriver driver;
  late FakeTimerNotifications notifications;
  late ProviderContainer container;

  CookingTimersNotifier notifier() =>
      container.read(cookingTimersProvider.notifier);
  List<CookingTimer> timers() => container.read(cookingTimersProvider);

  setUp(() {
    now = DateTime.utc(2026, 10, 1, 12);
    alerts = 0;
    driver = FakeAlarmDriver();
    notifications = FakeTimerNotifications();
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        cookingClockProvider.overrideWithValue(() => now),
        cookingAlertProvider.overrideWithValue(() => alerts++),
        alarmDriverProvider.overrideWithValue(driver),
        timerNotificationsProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
  });

  void advance(Duration d) {
    now = now.add(d);
    notifier().tick();
  }

  test('start cria o timer rodando com o tempo cheio', () {
    final id = notifier().start(
      recipeId: 'r1',
      label: 'Cozimento',
      duration: const Duration(minutes: 25),
      key: 'cook',
    );
    final t = timers().single;
    expect(t.id, id);
    expect(t.phase, TimerPhase.running);
    expect(t.remaining, const Duration(minutes: 25));
    expect(t.total, const Duration(minutes: 25));
  });

  test('tick desconta o tempo pelo relógio, não por contagem de ticks', () {
    notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 10),
    );
    advance(const Duration(minutes: 4));
    expect(timers().single.remaining, const Duration(minutes: 6));
    // Um salto longo (app em segundo plano) cai certo de uma vez.
    advance(const Duration(minutes: 5, seconds: 30));
    expect(timers().single.remaining, const Duration(seconds: 30));
  });

  test('ao chegar em zero acaba, avisa uma vez e fica "pronto"', () {
    notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(seconds: 30),
    );
    advance(const Duration(seconds: 29));
    expect(alerts, 0);
    advance(const Duration(seconds: 2));

    final t = timers().single;
    expect(t.isFinished, isTrue);
    expect(t.remaining, Duration.zero);
    expect(alerts, 1);
  });

  test('o alerta repete a cada 3 s por até 30 s e depois para', () {
    notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(seconds: 5),
    );
    advance(const Duration(seconds: 5));
    expect(alerts, 1);

    for (var s = 1; s <= 31; s++) {
      advance(const Duration(seconds: 1));
    }
    // 1 (ao acabar) + 3,6,...,30 s depois = 10 repetições.
    expect(alerts, 11);
    advance(const Duration(seconds: 10));
    expect(alerts, 11);
  });

  test('pausar guarda o que falta; retomar volta a contar dali', () {
    final id = notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 10),
    );
    advance(const Duration(minutes: 3));
    notifier().pause(id);
    expect(timers().single.phase, TimerPhase.paused);
    expect(timers().single.remaining, const Duration(minutes: 7));

    advance(const Duration(minutes: 20));
    expect(timers().single.remaining, const Duration(minutes: 7));
    expect(timers().single.isFinished, isFalse);

    notifier().resume(id);
    advance(const Duration(minutes: 2));
    expect(timers().single.remaining, const Duration(minutes: 5));
  });

  test('toggle alterna entre pausar e retomar', () {
    final id = notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 1),
    );
    notifier().toggle(id);
    expect(timers().single.phase, TimerPhase.paused);
    notifier().toggle(id);
    expect(timers().single.phase, TimerPhase.running);
    notifier().toggle(999); // inexistente: nada acontece
    expect(timers(), hasLength(1));
  });

  test('restart volta ao tempo cheio, inclusive de um que já acabou', () {
    final id = notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 1),
    );
    advance(const Duration(minutes: 2));
    expect(timers().single.isFinished, isTrue);

    notifier().restart(id);
    expect(timers().single.phase, TimerPhase.running);
    expect(timers().single.remaining, const Duration(minutes: 1));
    advance(const Duration(seconds: 20));
    expect(timers().single.remaining, const Duration(seconds: 40));
  });

  test('cancelar tira o timer; vários rodam juntos', () {
    final a = notifier().start(
      recipeId: 'r1',
      label: 'a',
      duration: const Duration(minutes: 5),
    );
    notifier().start(
      recipeId: 'r1',
      label: 'b',
      duration: const Duration(minutes: 8),
    );
    advance(const Duration(minutes: 1));
    expect(timers().map((t) => t.remaining),
        [const Duration(minutes: 4), const Duration(minutes: 7)]);

    notifier().cancel(a);
    expect(timers().map((t) => t.label), ['b']);
  });

  test('a mesma key reinicia em vez de duplicar; receitas diferentes não', () {
    notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 5),
      key: 'cook',
    );
    advance(const Duration(minutes: 2));
    notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 5),
      key: 'cook',
    );
    notifier().start(
      recipeId: 'r2',
      label: 'x',
      duration: const Duration(minutes: 5),
      key: 'cook',
    );

    expect(timers(), hasLength(2));
    final r1 = timers().firstWhere((t) => t.recipeId == 'r1');
    expect(r1.remaining, const Duration(minutes: 5));
  });

  test('sem nada rodando o relógio de fundo para (dispose não deixa timer)',
      () {
    final id = notifier().start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(minutes: 1),
    );
    notifier().cancel(id);
    expect(timers(), isEmpty);
    // container.dispose (tearDown) cancela qualquer ticker restante.
  });

  test('falha ao alertar não derruba o timer', () {
    final broken = ProviderContainer(
      overrides: [
        cookingClockProvider.overrideWithValue(() => now),
        cookingAlertProvider
            .overrideWithValue(() => throw StateError('sem som')),
      ],
    );
    addTearDown(broken.dispose);
    final n = broken.read(cookingTimersProvider.notifier);
    n.start(
      recipeId: 'r1',
      label: 'x',
      duration: const Duration(seconds: 1),
    );
    now = now.add(const Duration(seconds: 2));
    n.tick();
    expect(broken.read(cookingTimersProvider).single.isFinished, isTrue);
  });

  test('repetir mantém o nome da receita e limpa o "acabou"', () {
    final id = notifier().start(
      recipeId: 'r1',
      recipeName: 'Frango ao curry',
      label: 'Passo 2',
      duration: const Duration(minutes: 1),
    );
    advance(const Duration(minutes: 2));
    expect(timers().single.finishedAt, isNotNull);

    notifier().restart(id);
    final t = timers().single;
    expect(t.recipeName, 'Frango ao curry');
    expect(t.finishedAt, isNull);
    expect(t.phase, TimerPhase.running);
  });

  test('dispensar ou repetir um timer que está tocando para o som', () {
    final a = notifier().start(
      recipeId: 'r1',
      label: 'a',
      duration: const Duration(seconds: 5),
    );
    final b = notifier().start(
      recipeId: 'r1',
      label: 'b',
      duration: const Duration(minutes: 30),
    );
    advance(const Duration(seconds: 6));
    expect(driver.calls, isEmpty);

    notifier().cancel(b); // em andamento: não mexe no som
    expect(driver.calls, isEmpty);

    notifier().restart(a); // estava tocando: para
    expect(driver.calls, ['stopSound']);

    advance(const Duration(minutes: 1));
    notifier().cancel(a); // tocando de novo e dispensado: para
    expect(driver.calls, ['stopSound', 'stopSound']);
  });

  group('notificações (app minimizado)', () {
    test('minimizar: rodando vira notificação com o horário de fim e as chaves',
        () async {
      final id = notifier().start(
        recipeId: 'r1',
        recipeName: 'Frango ao curry',
        label: 'Passo 2',
        duration: const Duration(minutes: 20),
      );
      await container
          .read(cookingAlertSettingsProvider.notifier)
          .setSound(true);

      await notifier().onBackground();

      final shown = notifications.runningDetails[id]!;
      expect(shown.title, 'Frango ao curry · Passo 2');
      expect(shown.recipeId, 'r1');
      expect(shown.endsAt, now.add(const Duration(minutes: 20)));
      expect(shown.vibrate, isTrue);
      expect(shown.sound, isTrue);
    });

    test('minimizar: pausado mostra o que falta, sem aviso; pronto não mostra',
        () async {
      final paused = notifier().start(
        recipeId: 'r1',
        label: 'a',
        duration: const Duration(minutes: 10),
      );
      advance(const Duration(minutes: 3));
      notifier().pause(paused);
      final done = notifier().start(
        recipeId: 'r1',
        label: 'b',
        duration: const Duration(seconds: 5),
      );
      advance(const Duration(seconds: 6));
      expect(timers().firstWhere((t) => t.id == done).isFinished, isTrue);
      notifications.calls.clear();

      await notifier().onBackground();

      expect(notifications.pausedDetails[paused]!.remaining,
          const Duration(minutes: 7));
      expect(notifications.calls, ['paused:$paused']);
    });

    test('voltar: tira as notificações de todos os timers', () async {
      final a = notifier().start(
        recipeId: 'r1',
        label: 'a',
        duration: const Duration(minutes: 5),
      );
      final b = notifier().start(
        recipeId: 'r1',
        label: 'b',
        duration: const Duration(minutes: 9),
      );
      await notifier().onBackground();
      notifications.calls.clear();

      await notifier().onForeground();

      expect(notifications.calls, containsAll(['cancel:$a', 'cancel:$b']));
    });

    test('acabou com o app em segundo plano: na volta não vibra/toca de novo',
        () async {
      notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 1),
      );
      await notifier().onBackground();

      now = now.add(const Duration(minutes: 10)); // app minimizado esse tempo
      await notifier().onForeground();

      final t = timers().single;
      expect(t.isFinished, isTrue);
      expect(alerts, 0); // a notificação já avisou
      // "Acabou" conta a partir do fim de verdade, não da volta.
      expect(t.finishedAt, now.subtract(const Duration(minutes: 9)));
    });

    test('acabou com o app aberto: avisa na hora (não é "velho")', () {
      notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(seconds: 30),
      );
      advance(const Duration(seconds: 31));
      expect(alerts, 1);
    });

    test('cancelar tira a notificação do timer', () {
      final id = notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );
      notifications.calls.clear();
      notifier().cancel(id);
      expect(notifications.calls, ['cancel:$id']);
    });

    test('a permissão de notificação é pedida só na primeira vez', () async {
      notifier().start(
        recipeId: 'r1',
        label: 'a',
        duration: const Duration(minutes: 1),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      notifier().start(
        recipeId: 'r1',
        label: 'b',
        duration: const Duration(minutes: 1),
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
          notifications.calls.where((c) => c == 'permissions'), hasLength(1));
    });
  });

  group('persistência', () {
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    ProviderContainer reopen() {
      final c = ProviderContainer(
        overrides: [
          cookingClockProvider.overrideWithValue(() => now),
          cookingAlertProvider.overrideWithValue(() => alerts++),
          alarmDriverProvider.overrideWithValue(driver),
          timerNotificationsProvider.overrideWithValue(notifications),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('os timers sobrevivem ao app ser fechado e recalculam pelo fim',
        () async {
      final running = notifier().start(
        recipeId: 'r1',
        recipeName: 'Bolo',
        label: 'Cozimento',
        duration: const Duration(minutes: 40),
        key: 'cook',
      );
      final paused = notifier().start(
        recipeId: 'r1',
        label: 'Passo 3',
        duration: const Duration(minutes: 10),
      );
      advance(const Duration(minutes: 4));
      notifier().pause(paused);
      await settle();

      // "Fecha e reabre o app" 15 min depois.
      now = now.add(const Duration(minutes: 15));
      final c2 = reopen();
      c2.read(cookingTimersProvider);
      await settle();

      final list = c2.read(cookingTimersProvider);
      expect(list, hasLength(2));
      final r = list.firstWhere((t) => t.id == running);
      expect(r.recipeName, 'Bolo');
      expect(r.key, 'cook');
      expect(r.isRunning, isTrue);
      expect(r.remaining, const Duration(minutes: 21)); // 40 - 4 - 15
      final p = list.firstWhere((t) => t.id == paused);
      expect(p.phase, TimerPhase.paused);
      expect(p.remaining, const Duration(minutes: 6));

      // O próximo timer não repete id.
      final next = c2.read(cookingTimersProvider.notifier).start(
            recipeId: 'r1',
            label: 'novo',
            duration: const Duration(minutes: 1),
          );
      expect(next, greaterThan(paused));
    });

    test('rodando que já passou do fim volta como "pronto", sem alertar',
        () async {
      notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );
      await settle();

      now = now.add(const Duration(hours: 2));
      final c2 = reopen();
      c2.read(cookingTimersProvider);
      await settle();

      final t = c2.read(cookingTimersProvider).single;
      expect(t.isFinished, isTrue);
      expect(alerts, 0);
    });

    test('cancelar tudo limpa o que estava guardado', () async {
      final id = notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );
      await settle();
      notifier().cancel(id);
      await settle();

      final c2 = reopen();
      c2.read(cookingTimersProvider);
      await settle();
      expect(c2.read(cookingTimersProvider), isEmpty);
    });

    test('registro estragado é ignorado, não derruba', () async {
      SharedPreferences.setMockInitialValues({
        'cooking_timers_v1': '[{"id": "isso não é um timer"}, 42]',
      });
      final c2 = reopen();
      c2.read(cookingTimersProvider);
      await settle();
      expect(c2.read(cookingTimersProvider), isEmpty);
    });
  });

  group('segundo plano e botões da notificação', () {
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    TimerNotificationActions buttons() => TimerNotificationActions(
          store: PrefsTimersStore(),
          notifications: notifications,
          alertFlags: () async => (vibrate: true, sound: false),
          clock: () => now,
        );

    test(
        'minimizado, a tela se cala: não grava por cima do que a notificação gravou',
        () async {
      final id = notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 10),
      );
      await settle();
      await notifier().onBackground();

      // Com o app vivo em segundo plano, o relógio da tela ainda poderia
      // girar e regravar o estado antigo. Não pode.
      advance(const Duration(minutes: 3));
      await settle();
      final stored = await PrefsTimersStore().load();
      expect(stored!.single.remaining, const Duration(minutes: 10));

      // Botão "Pausar" da notificação 5 min depois.
      now = now.add(const Duration(minutes: 2));
      await buttons().handle(actionId: kTimerActionPause, timerId: id);
      advance(const Duration(minutes: 1)); // a tela segue quieta
      await settle();
      expect((await PrefsTimersStore().load())!.single.isPaused, isTrue);
    });

    test('na volta, o que os botões fizeram vale (pausar, +1 min, parar)',
        () async {
      final a = notifier().start(
        recipeId: 'r1',
        label: 'a',
        duration: const Duration(minutes: 10),
      );
      final b = notifier().start(
        recipeId: 'r1',
        label: 'b',
        duration: const Duration(minutes: 20),
      );
      final c = notifier().start(
        recipeId: 'r1',
        label: 'c',
        duration: const Duration(minutes: 30),
      );
      await settle();
      await notifier().onBackground();

      now = now.add(const Duration(minutes: 4));
      await buttons().handle(actionId: kTimerActionPause, timerId: a);
      await buttons().handle(actionId: kTimerActionPlusMinute, timerId: b);
      await buttons().handle(actionId: kTimerActionStop, timerId: c);

      await notifier().onForeground();

      expect(timers().map((t) => t.id), [a, b]);
      final ta = timers().firstWhere((t) => t.id == a);
      expect(ta.isPaused, isTrue);
      expect(ta.remaining, const Duration(minutes: 6));
      final tb = timers().firstWhere((t) => t.id == b);
      expect(tb.isRunning, isTrue);
      expect(tb.remaining, const Duration(minutes: 17)); // 20 - 4 + 1
    });

    test('na volta o relógio da tela volta a girar (e para de novo ao pausar)',
        () async {
      final id = notifier().start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );
      await settle();
      await notifier().onBackground();
      now = now.add(const Duration(minutes: 1));
      await notifier().onForeground();

      advance(const Duration(minutes: 1));
      expect(timers().single.remaining, const Duration(minutes: 3));
      notifier().pause(id);
      expect(timers().single.isPaused, isTrue);
    });

    test('nada guardado na volta não zera a lista da tela', () async {
      final fresh = ProviderContainer(
        overrides: [
          cookingClockProvider.overrideWithValue(() => now),
          cookingAlertProvider.overrideWithValue(() => alerts++),
          alarmDriverProvider.overrideWithValue(driver),
          timerNotificationsProvider.overrideWithValue(notifications),
          timersStoreProvider.overrideWithValue(_NullStore()),
        ],
      );
      addTearDown(fresh.dispose);
      final n = fresh.read(cookingTimersProvider.notifier);
      n.start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );

      await n.onBackground();
      await n.onForeground();

      expect(fresh.read(cookingTimersProvider), hasLength(1));
    });
  });
}

/// Um disco que nunca tem nada (ou que falhou): `load` devolve `null`.
class _NullStore implements TimersStore {
  @override
  Future<List<CookingTimer>?> load() async => null;

  @override
  Future<void> save(List<CookingTimer> timers) async {}
}
