import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/day_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

MealPlanEntry _entry(
  String name,
  MealType meal, {
  bool done = false,
  String? recipeId,
}) =>
    MealPlanEntry(
      id: '$name-${meal.code}',
      recipe: Recipe(
        id: recipeId ?? name,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: today(),
      mealType: meal,
      done: done,
    );

Widget _host(List<MealPlanEntry> entries, {DateTime? day}) => ProviderScope(
      overrides: [
        dayEntriesProvider.overrideWith(
          (ref, d) => Stream.value(isSameDay(d, today()) ? entries : const []),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: DayPage(initialDay: day ?? today()),
      ),
    );

void main() {
  testWidgets('mostra o dia com as quatro refeições e as receitas agendadas',
      (tester) async {
    await tester.pumpWidget(_host([
      _entry('Bolo de Fubá', MealType.breakfast),
      _entry('Sopa', MealType.dinner, done: true),
    ]));
    await tester.pumpAndSettle();

    expect(find.text(weekdayLong(today())), findsOneWidget);
    expect(find.textContaining('· hoje'), findsOneWidget);
    expect(find.text('Bolo de Fubá'), findsOneWidget);
    expect(find.text('Sopa'), findsOneWidget);
    for (final m in MealType.values) {
      expect(find.text(m.label.toUpperCase()), findsOneWidget);
    }
    expect(find.text('Nada planejado'), findsNWidgets(2));
  });

  testWidgets('setas andam de dia em dia', (tester) async {
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Próximo dia'));
    await tester.pumpAndSettle();
    expect(find.text(weekdayLong(addDays(today(), 1))), findsOneWidget);
    expect(find.text('Bolo'), findsNothing);
    expect(find.text('Nada planejado'), findsNWidgets(4));

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Bolo'), findsOneWidget);
  });

  testWidgets('nome sobre o azulejo; só um card por receita leva o Hero',
      (tester) async {
    await tester.pumpWidget(_host([
      _entry('Bolo de Fubá', MealType.lunch, recipeId: 'bolo'),
      _entry('Bolo de Fubá', MealType.dinner, recipeId: 'bolo'),
      _entry('Sopa', MealType.dinner),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(TilePattern), findsNWidgets(3));
    expect(find.byType(Hero), findsNWidgets(2));
    final tags = tester.widgetList<Hero>(find.byType(Hero)).map((h) => h.tag);
    expect(tags, {recipeTileHeroTag('bolo'), recipeTileHeroTag('Sopa')});
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrastar o dia com o dedo passa pro dia seguinte', (tester) async {
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Nada planejado').first, const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text(weekdayLong(addDays(today(), 1))), findsOneWidget);
    expect(find.text('Bolo'), findsNothing);
  });

  testWidgets('"Hoje" só liga fora de hoje e traz de volta', (tester) async {
    await tester.pumpWidget(_host([_entry('Bolo', MealType.lunch)]));
    await tester.pumpAndSettle();

    bool enabled() => tester
        .widget<InkWell>(find.byKey(const ValueKey('stepper-today')))
        .onTap != null;
    expect(enabled(), isFalse);

    await tester.tap(find.byTooltip('Dia anterior'));
    await tester.pumpAndSettle();
    expect(enabled(), isTrue);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(enabled(), isFalse);
    expect(find.text('Bolo'), findsOneWidget);
  });
}
