/// "Sugerir a semana": escolhe receitas pros espaços vazios da agenda. Puro:
/// recebe o "agora" e a semente de fora, então o resultado é reproduzível.
library;

import 'dart:math';

import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';

/// Uma receita que pode ser sugerida, com o que o motor precisa saber dela.
class PlanCandidate {
  const PlanCandidate({
    required this.id,
    required this.name,
    this.tags = const {},
    this.totalMinutes,
    this.isFavorite = false,
    this.lastCookedAt,
    this.cookCount = 0,
    this.lastScheduledOn,
  });

  final String id;
  final String name;

  /// Nomes de tag em minúsculas, sem acento (`stripAccents`).
  final Set<String> tags;
  final int? totalMinutes;
  final bool isFavorite;
  final DateTime? lastCookedAt;
  final int cookCount;

  /// Último dia em que a receita aparece na agenda (qualquer data), ou nulo.
  final DateTime? lastScheduledOn;
}

class WeekPlanOptions {
  const WeekPlanOptions({
    required this.monday,
    this.meals = const {MealType.dinner},
    this.anyOfTags = const {},
    this.maxMinutes,
    this.seed = 0,
  });

  final DateTime monday;
  final Set<MealType> meals;

  /// Vazio = qualquer receita. Senão, a receita precisa ter ao menos uma.
  final Set<String> anyOfTags;

  /// Nulo = sem limite. Receita sem tempo informado não entra quando há limite.
  final int? maxMinutes;

  /// Muda a cada "Trocar": mesma entrada com outra semente embaralha o empate.
  final int seed;
}

class PlanPick {
  const PlanPick({
    required this.date,
    required this.mealType,
    required this.candidate,
  });

  final DateTime date;
  final MealType mealType;
  final PlanCandidate candidate;
}

/// Quanto vale sugerir [c] agora: nunca feita e feita há muito tempo sobem;
/// favorita sobe um pouco; já agendada por perto desce.
double scoreCandidate(PlanCandidate c, DateTime now) {
  var score = 0.0;
  final cooked = c.lastCookedAt;
  if (cooked == null) {
    score += 3;
  } else {
    final days = now.difference(cooked).inDays;
    score += min(days / 14.0, 3.0);
  }
  if (c.isFavorite) score += 1;
  final scheduled = c.lastScheduledOn;
  if (scheduled != null) {
    final gap = (dayOf(now).difference(dayOf(scheduled)).inDays).abs();
    if (gap < 14) score -= 2.5 * (1 - gap / 14);
  }
  return score;
}

/// Preenche os espaços vazios da semana de [options.monday]: um por dia
/// futuro (hoje incluso) e refeição escolhida que ainda não tem receita. Sem
/// repetir receita dentro da proposta; se faltarem receitas, deixa o espaço
/// vazio. Ordem por data e refeição.
List<PlanPick> planWeek({
  required List<PlanCandidate> candidates,
  required List<MealPlanEntry> existing,
  required WeekPlanOptions options,
  required DateTime now,
}) {
  final today = dayOf(now);
  final taken = {
    for (final e in existing)
      '${dayOf(e.date).toIso8601String()}|${e.mealType.name}',
  };
  final inWeek = {
    for (final e in existing)
      if (!e.date.isBefore(options.monday) &&
          e.date.isBefore(addDays(options.monday, 7)))
        e.recipeId,
  };

  final pool = [
    for (final c in candidates)
      if (!inWeek.contains(c.id) &&
          (options.anyOfTags.isEmpty ||
              c.tags.any(options.anyOfTags.contains)) &&
          (options.maxMinutes == null ||
              (c.totalMinutes != null &&
                  c.totalMinutes! <= options.maxMinutes!)))
        c,
  ];

  final rng = Random(options.seed);
  final jitter = {for (final c in pool) c.id: rng.nextDouble() * 1.2};
  pool.sort((a, b) {
    final sa = scoreCandidate(a, now) + jitter[a.id]!;
    final sb = scoreCandidate(b, now) + jitter[b.id]!;
    return sb.compareTo(sa);
  });

  final meals = [
    for (final m in MealType.values)
      if (options.meals.contains(m)) m,
  ];
  final picks = <PlanPick>[];
  var next = 0;
  for (var d = 0; d < 7; d++) {
    final date = addDays(options.monday, d);
    if (date.isBefore(today)) continue;
    for (final meal in meals) {
      if (taken.contains('${date.toIso8601String()}|${meal.name}')) continue;
      if (next >= pool.length) return picks;
      picks.add(PlanPick(date: date, mealType: meal, candidate: pool[next++]));
    }
  }
  return picks;
}
