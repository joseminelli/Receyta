/// Textos do histórico "cozinhei" (G7), em pt-BR, sem depender de `intl` nem
/// de inicialização de locale. Puro: recebe o "agora" de fora.
library;

import 'package:receyta/domain/models/cook_log.dart';

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

/// O registro mais recente que tem estrelas ou frase ([logs] vem do mais novo
/// ao mais antigo), ou nulo se nenhum tem.
CookLog? latestFeedback(List<CookLog> logs) {
  for (final l in logs) {
    if (l.rating != null || l.hasNote) return l;
  }
  return null;
}

/// Frases prontas do "como ficou?": um toque escreve na nota.
const kQuickFeedbackPhrases = [
  'Menos sal',
  'Mais tempero',
  'Menos açúcar',
  'Cozinhar mais',
  'Ficou seco',
  'Repetir sempre',
];

/// Palavra que acompanha as estrelas ("Perfeito!"); vazio sem nota.
String ratingVerdict(int? stars) => switch (stars) {
      1 => 'Não rolou',
      2 => 'Dava pra melhorar',
      3 => 'Bom',
      4 => 'Muito bom',
      5 => 'Perfeito!',
      _ => '',
    };

/// O que o cloche diz no balão conforme as estrelas.
String clocheReply(int? stars) => switch (stars) {
      1 => 'Ah, que pena…',
      2 => 'Dá pra melhorar!',
      3 => 'Foi bom!',
      4 => 'Que bom!',
      5 => 'Uau, perfeito!',
      _ => 'E aí, gostou?',
    };

List<String> _noteParts(String note) => [
      for (final p in note.split(','))
        if (p.trim().isNotEmpty) p.trim(),
    ];

/// A [phrase] já está na [note] (partes separadas por vírgula)?
bool noteHasPhrase(String note, String phrase) {
  final want = phrase.toLowerCase();
  return _noteParts(note).any((p) => p.toLowerCase() == want);
}

/// Liga/desliga a [phrase] na [note]: tira se já está, senão acrescenta ao
/// fim (com a inicial minúscula quando não é a primeira).
String toggleNotePhrase(String note, String phrase) {
  final parts = _noteParts(note);
  final want = phrase.toLowerCase();
  if (parts.any((p) => p.toLowerCase() == want)) {
    return parts.where((p) => p.toLowerCase() != want).join(', ');
  }
  final added = parts.isEmpty
      ? phrase
      : '${phrase[0].toLowerCase()}${phrase.substring(1)}';
  return [...parts, added].join(', ');
}
