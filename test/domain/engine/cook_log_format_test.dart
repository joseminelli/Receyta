import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/domain/engine/cook_log_format.dart';

void main() {
  final now = DateTime(2026, 10, 2, 15);

  group('cookedAgo', () {
    test('hoje e ontem, mesmo com horas diferentes', () {
      expect(cookedAgo(DateTime(2026, 10, 2, 7), now), 'hoje');
      expect(cookedAgo(DateTime(2026, 10, 1, 23, 59), now), 'ontem');
    });

    test('dias, semanas e depois a data', () {
      expect(cookedAgo(DateTime(2026, 9, 29), now), 'há 3 dias');
      expect(cookedAgo(DateTime(2026, 9, 25), now), 'há 1 semana');
      expect(cookedAgo(DateTime(2026, 9, 11), now), 'há 3 semanas');
      expect(cookedAgo(DateTime(2026, 8, 1), now), 'sáb, 1 ago');
    });

    test('data no futuro (relógio mudado) vira "hoje"', () {
      expect(cookedAgo(DateTime(2026, 10, 5), now), 'hoje');
    });
  });

  group('formatCookedDate', () {
    test('sem o ano quando é o ano atual', () {
      expect(formatCookedDate(DateTime(2026, 9, 28), now), 'seg, 28 set');
    });

    test('com o ano quando é outro', () {
      expect(formatCookedDate(DateTime(2025, 12, 25), now), 'qui, 25 dez 2025');
    });
  });

  test('cookedTimesLabel', () {
    expect(cookedTimesLabel(0), 'Nunca cozinhada');
    expect(cookedTimesLabel(1), 'Cozinhada 1 vez');
    expect(cookedTimesLabel(4), 'Cozinhada 4 vezes');
  });

  test('formatMonthYear', () {
    expect(formatMonthYear(DateTime(2026, 10, 1)), 'Outubro 2026');
    expect(formatMonthYear(DateTime(2025, 3, 31)), 'Março 2025');
  });
}
