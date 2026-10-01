import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';

MealPlanEntry _entry(String id, MealType meal) => MealPlanEntry(
      id: id,
      recipe: Recipe(
        id: id,
        name: id,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: DateTime.utc(2026, 9, 29),
      mealType: meal,
    );

void main() {
  group('monthWeeks', () {
    test('mês que cabe em 5 semanas (setembro/2026)', () {
      final weeks = monthWeeks(DateTime.utc(2026, 9, 15));
      expect(weeks.first, DateTime.utc(2026, 8, 31));
      expect(weeks.last, DateTime.utc(2026, 9, 28));
      expect(weeks, hasLength(5));
    });

    test('mês que pede 6 semanas (agosto/2026 começa no sábado)', () {
      final weeks = monthWeeks(DateTime.utc(2026, 8));
      expect(weeks, hasLength(6));
      expect(weeks.first, DateTime.utc(2026, 7, 27));
      expect(weeks.last, DateTime.utc(2026, 8, 31));
    });

    test('fevereiro de 28 dias começando na segunda cabe em 4 semanas', () {
      final weeks = monthWeeks(DateTime.utc(2027, 2));
      expect(weeks, hasLength(4));
      expect(weeks.first, DateTime.utc(2027, 2));
    });
  });

  group('mainEntryOfDay', () {
    test('dia vazio não tem principal', () {
      expect(mainEntryOfDay(const []), isNull);
    });

    test('almoço vence jantar, que vence café, que vence lanche', () {
      final snack = _entry('s', MealType.snack);
      final breakfast = _entry('b', MealType.breakfast);
      final dinner = _entry('d', MealType.dinner);
      final lunch = _entry('l', MealType.lunch);
      expect(mainEntryOfDay([snack, breakfast]), breakfast);
      expect(mainEntryOfDay([snack, breakfast, dinner]), dinner);
      expect(mainEntryOfDay([snack, breakfast, dinner, lunch]), lunch);
    });

    test('empate fica com o mais antigo (primeiro da lista)', () {
      final a = _entry('a', MealType.lunch);
      final b = _entry('b', MealType.lunch);
      expect(mainEntryOfDay([a, b]), a);
    });
  });
}
