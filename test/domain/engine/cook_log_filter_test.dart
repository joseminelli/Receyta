import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/domain/engine/cook_log_filter.dart';
import 'package:receyta/domain/models/cook_log.dart';

CookLog _log(String id, String name, DateTime at, {String? note}) => CookLog(
      id: id,
      recipeId: id,
      recipeName: name,
      cookedAt: at,
      note: note,
    );

void main() {
  final now = DateTime(2026, 10, 15, 12);
  final logs = [
    _log('1', 'Pão de queijo', DateTime(2026, 10, 14, 9), note: 'faltou sal'),
    _log('2', 'Sopa de abóbora', DateTime(2026, 10, 3, 19)),
    _log('3', 'Bolo de cenoura', DateTime(2026, 9, 20, 15), note: 'Ótimo!'),
  ];

  List<String> ids(List<CookLog> l) => [for (final x in l) x.id];

  test('sem filtro nem busca, devolve tudo na mesma ordem', () {
    expect(ids(filterCookLogs(logs, now: now)), ['1', '2', '3']);
  });

  test('últimos 7 dias', () {
    final r = filterCookLogs(logs, filter: CookLogFilter.week, now: now);
    expect(ids(r), ['1']);
  });

  test('este mês', () {
    final r = filterCookLogs(logs, filter: CookLogFilter.month, now: now);
    expect(ids(r), ['1', '2']);
  });

  test('com nota', () {
    final r = filterCookLogs(logs, filter: CookLogFilter.withNote, now: now);
    expect(ids(r), ['1', '3']);
  });

  test('busca no nome, sem diferenciar maiúscula nem acento', () {
    expect(ids(filterCookLogs(logs, query: 'ABOBORA', now: now)), ['2']);
    expect(ids(filterCookLogs(logs, query: 'pao', now: now)), ['1']);
  });

  test('busca também na nota', () {
    expect(ids(filterCookLogs(logs, query: 'otimo', now: now)), ['3']);
  });

  test('busca e filtro se combinam', () {
    final r = filterCookLogs(
      logs,
      query: 'de',
      filter: CookLogFilter.month,
      now: now,
    );
    expect(ids(r), ['1', '2']);
  });

  test('espaços na busca não atrapalham e busca vazia não filtra', () {
    expect(ids(filterCookLogs(logs, query: '   ', now: now)), ['1', '2', '3']);
    expect(ids(filterCookLogs(logs, query: ' bolo ', now: now)), ['3']);
  });
}
