import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/cooking_timer.dart';

CookingTimer _running(DateTime now,
        {Duration total = const Duration(minutes: 10)}) =>
    CookingTimer(
      id: 7,
      recipeId: 'r1',
      recipeName: 'Frango ao curry',
      label: 'Passo 2',
      key: 'step-1-0',
      total: total,
      remaining: total,
      phase: TimerPhase.running,
      endsAt: now.add(total),
    );

void main() {
  final t0 = DateTime.utc(2026, 10, 1, 12);

  test('title junta receita e rótulo; sem receita é só o rótulo', () {
    expect(_running(t0).title, 'Frango ao curry · Passo 2');
    expect(
      const CookingTimer(
        id: 1,
        recipeId: 'r',
        label: 'Cozimento',
        total: Duration(minutes: 1),
        remaining: Duration(minutes: 1),
        phase: TimerPhase.paused,
      ).title,
      'Cozimento',
    );
  });

  group('paused / resumed', () {
    test('pausar guarda o que falta e solta o horário de fim', () {
      final p = _running(t0).paused(t0.add(const Duration(minutes: 4)));
      expect(p.phase, TimerPhase.paused);
      expect(p.remaining, const Duration(minutes: 6));
      expect(p.endsAt, isNull);
    });

    test('pausar depois do fim não dá tempo negativo', () {
      final p = _running(t0).paused(t0.add(const Duration(hours: 1)));
      expect(p.remaining, Duration.zero);
    });

    test('retomar volta a contar do que sobrava', () {
      final at = t0.add(const Duration(minutes: 4));
      final r =
          _running(t0).paused(at).resumed(at.add(const Duration(hours: 1)));
      expect(r.phase, TimerPhase.running);
      expect(r.endsAt, at.add(const Duration(hours: 1, minutes: 6)));
    });

    test('pausar o que não roda e retomar o que não está pausado: nada muda',
        () {
      final running = _running(t0);
      expect(identical(running.resumed(t0), running), isTrue);
      final paused = running.paused(t0);
      expect(identical(paused.paused(t0), paused), isTrue);
    });
  });

  group('extended', () {
    test('rodando: soma ao fim e ao que falta, sem mexer no tempo total', () {
      final e = _running(t0).extended(const Duration(minutes: 1));
      expect(e.endsAt, t0.add(const Duration(minutes: 11)));
      expect(e.remaining, const Duration(minutes: 11));
      expect(e.total, const Duration(minutes: 10));
    });

    test('pausado: soma só ao que falta', () {
      final p = _running(t0)
          .paused(t0.add(const Duration(minutes: 4)))
          .extended(const Duration(minutes: 1));
      expect(p.remaining, const Duration(minutes: 7));
      expect(p.isPaused, isTrue);
    });

    test('pronto não muda (pra isso existe restarted)', () {
      final done = _running(t0).copyWith(
        phase: TimerPhase.finished,
        remaining: Duration.zero,
        clearEndsAt: true,
        finishedAt: t0,
      );
      expect(
          identical(done.extended(const Duration(minutes: 1)), done), isTrue);
    });
  });

  test('restarted volta ao tempo total, roda e limpa o "acabou"', () {
    final done = _running(t0).copyWith(
      phase: TimerPhase.finished,
      remaining: Duration.zero,
      clearEndsAt: true,
      finishedAt: t0,
    );
    final r = done.restarted(t0.add(const Duration(hours: 1)));
    expect(r.phase, TimerPhase.running);
    expect(r.remaining, const Duration(minutes: 10));
    expect(r.endsAt, t0.add(const Duration(hours: 1, minutes: 10)));
    expect(r.finishedAt, isNull);
    expect(r.recipeName, 'Frango ao curry');
  });

  group('json', () {
    test('ida e volta preserva tudo', () {
      final original = _running(t0).extended(const Duration(seconds: 30));
      final back = CookingTimer.fromJson(original.toJson())!;
      expect(back.id, original.id);
      expect(back.recipeName, original.recipeName);
      expect(back.key, original.key);
      expect(back.total, original.total);
      expect(back.remaining, original.remaining);
      expect(back.phase, original.phase);
      expect(back.endsAt, original.endsAt);
    });

    test('registro estragado vira null, sem lançar', () {
      expect(CookingTimer.fromJson({'id': 'x'}), isNull);
      expect(CookingTimer.fromJson({}), isNull);
      final bad = _running(t0).toJson()..['phase'] = 'inexistente';
      expect(CookingTimer.fromJson(bad), isNull);
    });
  });
}
