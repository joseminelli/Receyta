/// Horário silencioso dos lembretes (G5): faixa do dia em que nenhum lembrete
/// deve chegar. Pura, sem relógio nem plugin — recebe minutos desde a meia-noite.
class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.startMinutes = 22 * 60,
    this.endMinutes = 8 * 60,
  });

  final bool enabled;

  /// Começo e fim da faixa, em minutos desde a meia-noite. Se o fim é menor
  /// que o começo, a faixa atravessa a meia-noite (22:00 às 08:00).
  final int startMinutes;
  final int endMinutes;

  bool get _crossesMidnight => endMinutes <= startMinutes;

  /// O horário [minuteOfDay] cai dentro da faixa silenciosa?
  bool contains(int minuteOfDay) {
    if (!enabled || startMinutes == endMinutes) return false;
    if (_crossesMidnight) {
      return minuteOfDay >= startMinutes || minuteOfDay < endMinutes;
    }
    return minuteOfDay >= startMinutes && minuteOfDay < endMinutes;
  }

  /// Empurra um horário que cairia na faixa pro fim dela. [dayOffset] diz se o
  /// fim está no dia seguinte (a parte da noite de uma faixa que atravessa a
  /// meia-noite). Fora da faixa, devolve o mesmo horário.
  ({int dayOffset, int minutes}) shift(int minuteOfDay) {
    if (!contains(minuteOfDay)) return (dayOffset: 0, minutes: minuteOfDay);
    final tonight = _crossesMidnight && minuteOfDay >= startMinutes;
    return (dayOffset: tonight ? 1 : 0, minutes: endMinutes);
  }

  QuietHours copyWith({bool? enabled, int? startMinutes, int? endMinutes}) =>
      QuietHours(
        enabled: enabled ?? this.enabled,
        startMinutes: startMinutes ?? this.startMinutes,
        endMinutes: endMinutes ?? this.endMinutes,
      );

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.enabled == enabled &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(enabled, startMinutes, endMinutes);
}

/// "18:00" a partir de minutos desde a meia-noite.
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60) % 24;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
