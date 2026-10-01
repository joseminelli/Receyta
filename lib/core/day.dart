/// Datas de calendário (sem hora), usadas pelo planejamento semanal (§RF-04).
///
/// Um "dia" é a data local escolhida pelo usuário guardada como meia-noite
/// **UTC** daquele mesmo ano/mês/dia — assim o dia gravado nunca pula pro
/// vizinho por causa do fuso, e a comparação textual ISO do banco ordena certo.
library;

/// A data de calendário de [any] (usa ano/mês/dia como estão em [any]).
DateTime dayOf(DateTime any) => DateTime.utc(any.year, any.month, any.day);

/// Hoje, como data de calendário local.
DateTime today([DateTime Function() clock = DateTime.now]) => dayOf(clock());

/// Segunda-feira da semana de [day].
DateTime mondayOf(DateTime day) {
  final d = dayOf(day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Soma [days] dias de calendário (imune a horário de verão: opera em UTC).
DateTime addDays(DateTime day, int days) => dayOf(day).add(Duration(days: days));

/// Primeiro dia do mês de [day].
DateTime firstOfMonth(DateTime day) => DateTime.utc(day.year, day.month);

/// [months] meses depois de [day], sempre no dia 1 (mês negativo volta).
DateTime addMonths(DateTime day, int months) =>
    DateTime.utc(day.year, day.month + months);

/// "2026-09-29" — como o dia viaja na rota da tela do dia.
String dayToParam(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// Inverso de [dayToParam]; texto inválido cai em hoje.
DateTime dayFromParam(String? text) {
  final parsed = text == null ? null : DateTime.tryParse(text);
  return parsed == null ? today() : dayOf(parsed);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

const _weekdayShort = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _weekdayLong = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];
const _monthLong = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];
const _monthShort = [
  'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
  'jul', 'ago', 'set', 'out', 'nov', 'dez',
];

String weekdayShort(DateTime day) => _weekdayShort[day.weekday - 1];
String weekdayLong(DateTime day) => _weekdayLong[day.weekday - 1];
String monthShort(DateTime day) => _monthShort[day.month - 1];
String monthLong(DateTime day) => _monthLong[day.month - 1];

/// "29 set – 5 out" (ou "1 – 7 out" dentro do mesmo mês).
String weekRangeLabel(DateTime monday) {
  final sunday = addDays(monday, 6);
  if (monday.month == sunday.month) {
    return '${monday.day} – ${sunday.day} ${monthShort(sunday)}';
  }
  return '${monday.day} ${monthShort(monday)} – '
      '${sunday.day} ${monthShort(sunday)}';
}
