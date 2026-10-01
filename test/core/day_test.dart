import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';

void main() {
  test('dayOf guarda a data local como meia-noite UTC', () {
    final d = dayOf(DateTime(2026, 9, 29, 23, 59));
    expect(d, DateTime.utc(2026, 9, 29));
    expect(d.isUtc, isTrue);
  });

  test('mondayOf devolve a segunda da semana (domingo fecha a semana)', () {
    expect(mondayOf(DateTime(2026, 9, 29)), DateTime.utc(2026, 9, 28));
    expect(mondayOf(DateTime(2026, 9, 28)), DateTime.utc(2026, 9, 28));
    expect(mondayOf(DateTime(2026, 10, 4)), DateTime.utc(2026, 9, 28));
    expect(mondayOf(DateTime(2026, 10, 5)), DateTime.utc(2026, 10, 5));
  });

  test('addDays atravessa mês e ano', () {
    expect(addDays(DateTime.utc(2026, 12, 30), 3), DateTime.utc(2027, 1, 2));
    expect(addDays(DateTime.utc(2026, 3, 1), -1), DateTime.utc(2026, 2, 28));
  });

  test('weekRangeLabel dentro e entre meses', () {
    expect(weekRangeLabel(DateTime.utc(2026, 10, 5)), '5 – 11 out');
    expect(weekRangeLabel(DateTime.utc(2026, 9, 28)), '28 set – 4 out');
  });

  test('nomes de dia', () {
    final tue = DateTime.utc(2026, 9, 29);
    expect(weekdayShort(tue), 'Ter');
    expect(weekdayLong(tue), 'Terça-feira');
    expect(monthShort(tue), 'set');
  });

  test('mês: primeiro dia, somar meses e nome', () {
    expect(firstOfMonth(DateTime.utc(2026, 9, 29)), DateTime.utc(2026, 9));
    expect(addMonths(DateTime.utc(2026, 11), 2), DateTime.utc(2027, 1));
    expect(addMonths(DateTime.utc(2026, 1), -1), DateTime.utc(2025, 12));
    expect(monthLong(DateTime.utc(2026, 3)), 'Março');
  });

  test('dayToParam / dayFromParam são inversos; lixo cai em hoje', () {
    final d = DateTime.utc(2026, 9, 5);
    expect(dayToParam(d), '2026-09-05');
    expect(dayFromParam('2026-09-05'), d);
    expect(dayFromParam('bobagem'), today());
    expect(dayFromParam(null), today());
  });
}
