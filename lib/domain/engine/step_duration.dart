import 'package:receyta/domain/engine/text_normalize.dart';

/// Um tempo achado no texto de um passo ("20 minutos", "1h30", "meia hora"):
/// o valor e um rótulo curto pro botão do timer ("20 min", "1 h 30 min").
class StepDuration {
  const StepDuration({required this.duration, required this.label});

  final Duration duration;
  final String label;
}

/// Acima disto não é tempo de preparo, é outra coisa ("500 horas").
const _maxDuration = Duration(hours: 24);

/// Padrões, do mais específico pro mais geral — cada trecho achado é
/// "apagado" do texto de trabalho, então "1 hora e 30 minutos" é um tempo só e
/// não uma hora mais 30 minutos. Roda em minúsculas e sem acento (o mapa de
/// acentos troca letra por letra, os índices batem com o texto original).
final _patterns = <(RegExp, Duration? Function(RegExpMatch))>[
  // meia hora
  (RegExp(r'\bmeia\s+hora\b'), (_) => const Duration(minutes: 30)),
  // 1h30 / 1 h 30 / 1h15min
  (
    RegExp(r'\b(\d{1,2})\s*h\s*(\d{1,2})(?:\s*(?:min|minutos?))?\b'),
    (m) => Duration(
          hours: int.parse(m[1]!),
          minutes: int.parse(m[2]!),
        ),
  ),
  // 1 hora e meia
  (
    RegExp(r'\b(\d+)\s*(?:horas?|hrs?|h)\s*e\s*meia\b'),
    (m) => Duration(hours: int.parse(m[1]!), minutes: 30),
  ),
  // 1 hora e 15 minutos
  (
    RegExp(
      r'\b(\d+)\s*(?:horas?|hrs?|h)\s*e\s*(\d{1,2})\s*(?:minutos?|min)\b',
    ),
    (m) => Duration(hours: int.parse(m[1]!), minutes: int.parse(m[2]!)),
  ),
  // 1,5 hora / 2 horas / 1h
  (
    RegExp(r'\b(\d+(?:[.,]\d+)?)\s*(?:horas?|hrs?|h)\b'),
    (m) {
      final hours = double.parse(m[1]!.replaceAll(',', '.'));
      return Duration(minutes: (hours * 60).round());
    },
  ),
  // 20 minutos / 20 a 25 minutos / 20-25 min (fica com o menor)
  (
    RegExp(
      r'\b(\d+)(?:\s*(?:a|ou|-|–)\s*\d+)?\s*(?:minutos?|min)\b',
    ),
    (m) => Duration(minutes: int.parse(m[1]!)),
  ),
  // 30 segundos
  (
    RegExp(r'\b(\d+)\s*(?:segundos?|seg)\b'),
    (m) => Duration(seconds: int.parse(m[1]!)),
  ),
];

/// Tempos que o texto de um passo menciona, na ordem em que aparecem. Cada um
/// vira um botão de timer no modo cozinha. Faixa ("20 a 25 minutos") fica com
/// o menor valor — o timer é o lembrete de ir olhar.
List<StepDuration> findStepDurations(String text) {
  if (text.trim().isEmpty) return const [];
  var work = stripAccents(text.toLowerCase());
  final found = <({int start, StepDuration value})>[];

  for (final (pattern, toDuration) in _patterns) {
    for (final match in pattern.allMatches(work).toList()) {
      final duration = toDuration(match);
      if (duration == null ||
          duration <= Duration.zero ||
          duration > _maxDuration) {
        continue;
      }
      found.add((
        start: match.start,
        value: StepDuration(duration: duration, label: _shortLabel(duration)),
      ));
      work = work.replaceRange(
        match.start,
        match.end,
        ' ' * (match.end - match.start),
      );
    }
  }

  found.sort((a, b) => a.start.compareTo(b.start));
  return [for (final f in found) f.value];
}

/// "20 min", "1 h 30 min", "2 h", "30 s".
String _shortLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return m > 0 ? '$h h $m min' : '$h h';
  if (m > 0) return s > 0 ? '$m min $s s' : '$m min';
  return '$s s';
}

/// Relógio do timer: "05:07" ou "1:02:03". Negativo vira zero.
String formatTimer(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
