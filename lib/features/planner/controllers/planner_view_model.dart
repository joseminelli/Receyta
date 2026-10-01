import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';

/// Primeiro dia do mês mostrado no calendário (RF-04.1). Começa no mês de
/// hoje; navegar de mês é só trocar este valor.
final visibleMonthProvider = StateProvider<DateTime>(
  (ref) => firstOfMonth(today()),
);

/// As segundas-feiras das semanas que a grade do [month] mostra (4 a 6),
/// incluindo os dias vizinhos que completam a primeira e a última semana.
List<DateTime> monthWeeks(DateTime month) {
  final first = firstOfMonth(month);
  final start = mondayOf(first);
  final lastDay = addDays(firstOfMonth(addMonths(first, 1)), -1);
  final end = mondayOf(lastDay);
  final count = end.difference(start).inDays ~/ 7 + 1;
  return [for (var i = 0; i < count; i++) addDays(start, i * 7)];
}

/// Todas as refeições agendadas no que a grade de [month] mostra, ao vivo.
/// Família por mês: a tela também observa os dois vizinhos, então o deslize
/// com o dedo já encontra a grade ao lado pronta.
final monthEntriesProvider =
    StreamProvider.family<List<MealPlanEntry>, DateTime>((ref, month) {
  final weeks = monthWeeks(month);
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(weeks.first, addDays(weeks.last, 7));
});

/// As refeições de um dia, ao vivo — a tela do dia.
final dayEntriesProvider =
    StreamProvider.family<List<MealPlanEntry>, DateTime>((ref, day) {
  return ref.watch(mealPlanRepositoryProvider).watchRange(day, addDays(day, 1));
});

/// Até cinco refeições ainda por fazer nos 14 dias a partir de [from], em
/// ordem de dia e de refeição — o "Próximas refeições" do calendário. Família
/// por dia: virou o dia, a tela pede outra chave e recalcula sozinha.
final upcomingEntriesProvider =
    StreamProvider.family<List<MealPlanEntry>, DateTime>((ref, from) {
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(from, addDays(from, 14))
      .map((entries) {
    final pending = [
      for (final e in entries)
        if (!e.done) e,
    ]..sort((a, b) {
        final byDay = a.date.compareTo(b.date);
        return byDay != 0
            ? byDay
            : a.mealType.index.compareTo(b.mealType.index);
      });
    return pending.take(3).toList();
  });
});

/// Quantas vezes cada receita aparece nas refeições ainda por fazer
/// (`done == false`) a partir de [from] — é o que a lista de compras da
/// semana precisa comprar (receita feita 2× = ingredientes em dobro).
Map<String, int> pendingRecipeCounts(
  List<MealPlanEntry> entries,
  DateTime from,
) {
  final counts = <String, int>{};
  for (final e in entries) {
    if (e.done || e.date.isBefore(dayOf(from))) continue;
    counts.update(e.recipeId, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}
