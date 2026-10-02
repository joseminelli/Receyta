/// Busca e filtros do histórico "cozinhei" (G7). Puro: recebe o "agora" de fora.
library;

import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/cook_log.dart';

/// Recortes do histórico.
enum CookLogFilter {
  all('Tudo'),
  week('Últimos 7 dias'),
  month('Este mês'),
  withNote('Com nota');

  const CookLogFilter(this.label);

  final String label;
}

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Registros que passam no [filter] e que contêm [query] no nome da receita
/// ou na nota (sem diferenciar maiúscula nem acento). Mantém a ordem.
List<CookLog> filterCookLogs(
  List<CookLog> logs, {
  String query = '',
  CookLogFilter filter = CookLogFilter.all,
  required DateTime now,
}) {
  final q = stripAccents(query.trim().toLowerCase());
  final today = _dayOnly(now);

  bool passesFilter(CookLog l) {
    final day = _dayOnly(l.cookedAt.toLocal());
    switch (filter) {
      case CookLogFilter.all:
        return true;
      case CookLogFilter.week:
        return today.difference(day).inDays < 7;
      case CookLogFilter.month:
        return day.year == today.year && day.month == today.month;
      case CookLogFilter.withNote:
        return l.hasNote;
    }
  }

  bool matches(CookLog l) {
    if (q.isEmpty) return true;
    final haystack =
        stripAccents('${l.recipeName} ${l.note ?? ''}'.toLowerCase());
    return haystack.contains(q);
  }

  return [
    for (final l in logs)
      if (passesFilter(l) && matches(l)) l,
  ];
}
