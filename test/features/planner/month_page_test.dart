import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/month_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_pattern.dart';

MealPlanEntry _entry(String name, DateTime day, MealType meal) =>
    MealPlanEntry(
      id: '$name-${dayToParam(day)}-${meal.code}',
      recipe: Recipe(
        id: name,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      date: day,
      mealType: meal,
    );

Widget _host(List<MealPlanEntry> entries, {List<String>? visited}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MonthPage()),
      GoRoute(
        path: '/planner/day/:date',
        builder: (_, state) {
          visited?.add(state.pathParameters['date']!);
          return const Scaffold(body: Text('tela do dia'));
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      monthEntriesProvider.overrideWith((ref) => Stream.value(entries)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

/// Tela de celular (390×844): na superfície padrão do teste (800×600) as
/// células quadradas ficam enormes e a grade passa da altura da tela.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('mostra o mês atual, os dias da semana e a dica quando vazio',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text(monthLong(today())), findsOneWidget);
    expect(find.text('${today().year}'), findsOneWidget);
    expect(find.text('SEG'), findsOneWidget);
    expect(find.text('DOM'), findsOneWidget);
    expect(find.byType(TilePattern), findsNothing);
    expect(find.text('Toque num dia pra planejar as refeições.'), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);
  });

  testWidgets('dia com refeição vira azulejo; vários mostram a contagem',
      (tester) async {
    _usePhoneSize(tester);
    final t = today();
    await tester.pumpWidget(_host([
      _entry('Bolo', t, MealType.lunch),
      _entry('Sopa', t, MealType.dinner),
      _entry('Pão', addDays(t, t.day < 28 ? 1 : -1), MealType.breakfast),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(TilePattern), findsNWidgets(2));
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('Toque num dia pra planejar as refeições.'), findsNothing);
  });

  testWidgets('tocar num dia abre a tela do dia com a data na rota',
      (tester) async {
    _usePhoneSize(tester);
    final visited = <String>[];
    await tester.pumpWidget(_host(const [], visited: visited));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('${today().day} de')).first);
    await tester.pumpAndSettle();

    expect(find.text('tela do dia'), findsOneWidget);
    expect(visited.single, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  testWidgets('trocar de mês mostra "Hoje" pra voltar', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('Hoje'), findsOneWidget);
    expect(
      find.text(monthLong(addMonths(firstOfMonth(today()), 1))),
      findsOneWidget,
    );

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    expect(find.text(monthLong(today())), findsOneWidget);
    expect(find.text('Hoje'), findsNothing);
  });

  testWidgets('carrinho da semana só liga quando há refeição pendente',
      (tester) async {
    _usePhoneSize(tester);
    final t = today();
    await tester.pumpWidget(_host([_entry('Bolo', t, MealType.lunch)]));
    await tester.pumpAndSettle();

    final enabled = find.byWidgetPredicate(
      (w) =>
          w is IconButton &&
          w.onPressed != null &&
          (w.tooltip ?? '').startsWith('Lista de compras da semana'),
    );
    expect(enabled, findsOneWidget);
  });
}
