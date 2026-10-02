import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/week_planner.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';

PlanCandidate _c(String id,
        {Set<String> tags = const {},
        int? minutes,
        DateTime? cooked,
        DateTime? scheduled}) =>
    PlanCandidate(
      id: id,
      name: id,
      tags: tags,
      totalMinutes: minutes,
      lastCookedAt: cooked,
      lastScheduledOn: scheduled,
    );

MealPlanEntry _entry(String recipeId, DateTime date, MealType meal) =>
    MealPlanEntry(
      id: 'e$recipeId',
      recipe: Recipe(
        id: recipeId,
        name: recipeId,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: date,
      mealType: meal,
    );

void main() {
  final monday = DateTime.utc(2026, 9, 28);
  final now = DateTime(2026, 9, 28, 10);
  final all = [for (var i = 0; i < 10; i++) _c('r$i')];

  test('preenche sete jantares sem repetir receita', () {
    final picks = planWeek(
      candidates: all,
      existing: const [],
      options: WeekPlanOptions(monday: monday),
      now: now,
    );
    expect(picks, hasLength(7));
    expect({for (final p in picks) p.candidate.id}, hasLength(7));
  });

  test('pula espaços ocupados, dias passados e receitas já na semana', () {
    final picks = planWeek(
      candidates: all,
      existing: [_entry('r0', DateTime.utc(2026, 9, 29), MealType.dinner)],
      options: WeekPlanOptions(monday: monday),
      now: DateTime(2026, 9, 30, 10),
    );
    expect(picks.map((p) => p.date.day), [30, 1, 2, 3, 4]);
    expect(picks.any((p) => p.candidate.id == 'r0'), isFalse);
  });

  test('sem receitas suficientes deixa espaços vazios', () {
    final picks = planWeek(
      candidates: all.take(3).toList(),
      existing: const [],
      options: WeekPlanOptions(monday: monday),
      now: now,
    );
    expect(picks, hasLength(3));
  });

  test('filtra por tag e por tempo', () {
    final picks = planWeek(
      candidates: [
        _c('a', tags: {'vegetariana'}, minutes: 20),
        _c('b', tags: {'vegetariana'}, minutes: 90),
        _c('c', minutes: 10),
      ],
      existing: const [],
      options: WeekPlanOptions(
        monday: monday,
        anyOfTags: {'vegetariana'},
        maxMinutes: 30,
      ),
      now: now,
    );
    expect(picks.map((p) => p.candidate.id), ['a']);
  });

  test('prioriza a que nunca foi feita e a feita há mais tempo', () {
    final picks = planWeek(
      candidates: [
        _c('recente', cooked: now.subtract(const Duration(days: 2))),
        _c('antiga', cooked: now.subtract(const Duration(days: 60))),
        _c('nunca'),
      ],
      existing: const [],
      options: WeekPlanOptions(monday: monday, meals: {MealType.lunch}),
      now: now,
    );
    expect(picks.last.candidate.id, 'recente');
  });

  test('mesma semente repete o resultado, outra pode embaralhar', () {
    List<String> run(int seed) => planWeek(
          candidates: all,
          existing: const [],
          options: WeekPlanOptions(monday: monday, seed: seed),
          now: now,
        ).map((p) => p.candidate.id).toList();
    expect(run(1), run(1));
    expect({for (var s = 0; s < 6; s++) run(s).join()}.length, greaterThan(1));
  });
}
