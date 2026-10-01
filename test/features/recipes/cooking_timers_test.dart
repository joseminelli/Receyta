import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';

void main() {
  late DateTime now;
  late int alerts;
  late ProviderContainer container;

  CookingTimersNotifier notifier() =>
      container.read(cookingTimersProvider.notifier);
  List<CookingTimer> timers() => container.read(cookingTimersProvider);

  setUp(() {
    now = DateTime.utc(2026, 10, 1, 12);
    alerts = 0;
    container = ProviderContainer(
      overrides: [
        cookingClockProvider.overrideWithValue(() => now),
        cookingAlertProvider.overrideWithValue(() => alerts++),
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
}
