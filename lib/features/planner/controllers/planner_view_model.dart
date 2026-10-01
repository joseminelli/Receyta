import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';

/// Dia aberto na tela da semana (RF-04.1) — o chip selecionado e o dia
/// detalhado embaixo. Começa em hoje.
final selectedDayProvider = StateProvider<DateTime>((ref) => today());

/// Segunda-feira da semana mostrada: deriva do dia selecionado, então
/// navegar de semana é só mover o dia.
final weekStartProvider = Provider<DateTime>(
  (ref) => mondayOf(ref.watch(selectedDayProvider)),
);

/// Todas as refeições agendadas da semana mostrada, ao vivo.
final weekEntriesProvider = StreamProvider<List<MealPlanEntry>>((ref) {
  final monday = ref.watch(weekStartProvider);
  return ref
      .watch(mealPlanRepositoryProvider)
      .watchRange(monday, addDays(monday, 7));
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
