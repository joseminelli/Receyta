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

/// Todas as refeições agendadas no que a grade do mês mostra, ao vivo.
final monthEntriesProvider = StreamProvider<List<MealPlanEntry>>((ref) {
  final weeks = monthWeeks(ref.watch(visibleMonthProvider));
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(weeks.first, addDays(weeks.last, 7));
});

/// As refeições de um dia, ao vivo — a tela do dia.
final dayEntriesProvider =
    StreamProvider.family<List<MealPlanEntry>, DateTime>((ref, day) {
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(day, addDays(day, 1));
});

/// A refeição que "representa" o dia no calendário: a principal (almoço,
/// depois jantar, café, lanche), a mais antiga em caso de empate. `null`
/// quando o dia está vazio.
MealPlanEntry? mainEntryOfDay(List<MealPlanEntry> dayEntries) {
  const priority = [
    MealType.lunch,
    MealType.dinner,
    MealType.breakfast,
    MealType.snack,
  ];
  for (final meal in priority) {
    for (final e in dayEntries) {
      if (e.mealType == meal) return e;
    }
  }
  return null;
}

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
