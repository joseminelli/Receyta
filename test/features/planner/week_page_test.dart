import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/week_page.dart';
import 'package:receyta/theme/app_theme.dart';

Widget _host(List<MealPlanEntry> entries) => ProviderScope(
      overrides: [
        weekEntriesProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const WeekPage()),
    );

MealPlanEntry _entry(String name, MealType meal, {bool done = false}) =>
    MealPlanEntry(
      id: name,
      recipeId: name,
      recipeName: name,
      date: today(),
      mealType: meal,
      done: done,
    );

void main() {
  testWidgets('mostra o dia de hoje com as refeições agendadas', (tester) async {
    await tester.pumpWidget(_host([
      _entry('Bolo de Fubá', MealType.breakfast),
      _entry('Sopa', MealType.dinner, done: true),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Semana'), findsOneWidget);
    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('Bolo de Fubá'), findsOneWidget);
    expect(find.text('Sopa'), findsOneWidget);
    for (final m in MealType.values) {
      expect(find.text(m.label.toUpperCase()), findsOneWidget);
    }
    expect(find.text('Nada planejado'), findsNWidgets(2));
    expect(find.text('Hoje'), findsNothing);
  });

  testWidgets('tocar em outro dia da faixa troca o dia e oferece voltar pra hoje',
      (tester) async {
    await tester.pumpWidget(_host([_entry('Bolo de Fubá', MealType.lunch)]));
    await tester.pumpAndSettle();

    final other = addDays(today(), today().weekday == DateTime.monday ? 1 : -1);
    await tester.tap(find.text('${other.day}').first);
    await tester.pumpAndSettle();

    expect(find.text('HOJE'), findsNothing);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Nada planejado'), findsNWidgets(4));

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('Bolo de Fubá'), findsOneWidget);
  });
}
