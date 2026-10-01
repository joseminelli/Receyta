import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';

void main() {
  group('monthWeeks', () {
    test('mês que cabe em 5 semanas (setembro/2026)', () {
      final weeks = monthWeeks(DateTime.utc(2026, 9, 15));
      expect(weeks.first, DateTime.utc(2026, 8, 31));
      expect(weeks.last, DateTime.utc(2026, 9, 28));
      expect(weeks, hasLength(5));
    });

    test('mês que pede 6 semanas (agosto/2026 começa no sábado)', () {
      final weeks = monthWeeks(DateTime.utc(2026, 8));
      expect(weeks, hasLength(6));
      expect(weeks.first, DateTime.utc(2026, 7, 27));
      expect(weeks.last, DateTime.utc(2026, 8, 31));
    });

    test('fevereiro de 28 dias começando na segunda cabe em 4 semanas', () {
      final weeks = monthWeeks(DateTime.utc(2027, 2));
      expect(weeks, hasLength(4));
      expect(weeks.first, DateTime.utc(2027, 2));
    });
  });
}
