/// Textos do histórico "cozinhei" (G7), em pt-BR, sem depender de `intl` nem
/// de inicialização de locale. Puro: recebe o "agora" de fora.
library;

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

const _monthNames = [
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

/// "Outubro 2026" — o título de cada mês no histórico.
String formatMonthYear(DateTime date) {
  final d = date.toLocal();
  return '${_monthNames[d.month - 1]} ${d.year}';
}

/// "ter, 28 set" — com o ano quando não é o de [now].
String formatCookedDate(DateTime date, DateTime now) {
  final d = date.toLocal();
  final base = '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

/// "hoje", "ontem", "há 3 dias", "há 2 semanas" ou a data por extenso.
String cookedAgo(DateTime date, DateTime now) {
  final days = _dayOnly(now).difference(_dayOnly(date.toLocal())).inDays;
  if (days <= 0) return 'hoje';
  if (days == 1) return 'ontem';
  if (days < 7) return 'há $days dias';
  if (days < 30) {
    final weeks = days ~/ 7;
    return weeks == 1 ? 'há 1 semana' : 'há $weeks semanas';
  }
  return formatCookedDate(date, now);
}

/// "Nunca cozinhada", "Cozinhada 1 vez", "Cozinhada 3 vezes".
String cookedTimesLabel(int times) {
  if (times <= 0) return 'Nunca cozinhada';
  return times == 1 ? 'Cozinhada 1 vez' : 'Cozinhada $times vezes';
}
