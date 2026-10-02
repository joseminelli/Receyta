import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/data/services/reminder_notifications.dart';
import 'package:receyta/domain/engine/quiet_hours.dart';

void main() {
  group('QuietHours que atravessa a meia-noite (22:00 às 08:00)', () {
    const quiet = QuietHours(enabled: true);

    test('pega a noite e a madrugada, e libera o dia', () {
      expect(quiet.contains(23 * 60), isTrue);
      expect(quiet.contains(3 * 60), isTrue);
      expect(quiet.contains(8 * 60), isFalse);
      expect(quiet.contains(12 * 60), isFalse);
      expect(quiet.contains(21 * 60 + 59), isFalse);
      expect(quiet.contains(22 * 60), isTrue);
    });

    test('desligado, nada é silencioso', () {
      expect(const QuietHours().contains(23 * 60), isFalse);
    });

    test('empurra pro fim da faixa: de noite vira o dia seguinte', () {
      expect(quiet.shift(23 * 60), (dayOffset: 1, minutes: 8 * 60));
      expect(quiet.shift(3 * 60), (dayOffset: 0, minutes: 8 * 60));
      expect(quiet.shift(18 * 60), (dayOffset: 0, minutes: 18 * 60));
    });
  });

  test('faixa dentro do mesmo dia (13:00 às 15:00)', () {
    const quiet = QuietHours(
      enabled: true,
      startMinutes: 13 * 60,
      endMinutes: 15 * 60,
    );

    expect(quiet.contains(14 * 60), isTrue);
    expect(quiet.contains(15 * 60), isFalse);
    expect(quiet.shift(14 * 60), (dayOffset: 0, minutes: 15 * 60));
  });

  test('início igual ao fim não silencia nada', () {
    const quiet = QuietHours(
      enabled: true,
      startMinutes: 600,
      endMinutes: 600,
    );

    expect(quiet.contains(600), isFalse);
  });

  test('formatMinutes', () {
    expect(formatMinutes(18 * 60), '18:00');
    expect(formatMinutes(8 * 60 + 5), '08:05');
  });

  group('nextWeekly', () {
    test('mesmo dia ainda por vir: é hoje', () {
      // 2026-10-04 é domingo.
      final next = nextWeekly(
        DateTime(2026, 10, 4, 10),
        weekday: DateTime.sunday,
        minutes: 18 * 60,
      );

      expect(next, DateTime(2026, 10, 4, 18));
    });

    test('hora que já passou hoje: só na semana seguinte', () {
      final next = nextWeekly(
        DateTime(2026, 10, 4, 19),
        weekday: DateTime.sunday,
        minutes: 18 * 60,
      );

      expect(next, DateTime(2026, 10, 11, 18));
    });

    test('outro dia da semana', () {
      // 2026-10-02 é sexta; a próxima segunda é 5/10.
      final next = nextWeekly(
        DateTime(2026, 10, 2, 9),
        weekday: DateTime.monday,
        minutes: 8 * 60,
      );

      expect(next, DateTime(2026, 10, 5, 8));
    });
  });
}
