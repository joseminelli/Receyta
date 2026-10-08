import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/screens/costs_page.dart';
import 'package:receyta/theme/app_theme.dart';

final _now = DateTime(2026, 10, 15);

Widget _host(PlanCost Function(CostPeriod) build) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => CostsPage(clock: () => _now)),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('ROTA RECEITA ${s.pathParameters['id']}'),
      ),
      GoRoute(path: '/ingredients', builder: (_, __) => const Text('ROTA ING')),
    ],
  );
  return ProviderScope(
    overrides: [
      planCostProvider.overrideWith((ref, period) async => build(period)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

const _full = PlanCost(
  totalCents: 12340,
  recipes: [
    RecipeSpend(recipeId: 'r1', name: 'Lasanha', cents: 8000, times: 2),
    RecipeSpend(recipeId: 'r2', name: 'Salada', cents: 4340, times: 1),
  ],
  ingredients: [
    IngredientSpend(name: 'Queijo', cents: 6000),
    IngredientSpend(name: 'Tomate', cents: 3000),
  ],
  missingNames: ['Manjericão'],
);

const _nothing = PlanCost(
  totalCents: 0,
  recipes: [],
  ingredients: [],
  missingNames: [],
);

void main() {
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('mostra total, receita mais cara, pesos e o que ficou de fora',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    expect(find.text('ESTIMATIVA MÍNIMA'), findsOneWidget);
    expect(find.textContaining('Valor estimado.'), findsOneWidget);
    expect(find.text('R\$ 123,40'), findsOneWidget);
    expect(find.text('Receita mais cara'), findsOneWidget);
    expect(find.text('planejada 2 vezes'), findsOneWidget);
    expect(find.text('Queijo'), findsOneWidget);
    expect(find.text('R\$ 60,00'), findsOneWidget);
    expect(find.textContaining('Manjericão'), findsOneWidget);
  });

  testWidgets('receita incompleta fica fora do ranking e a tela explica',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => const PlanCost(
          totalCents: 9000,
          recipes: [
            RecipeSpend(
              recipeId: 'festa',
              name: 'Festa',
              cents: 8000,
              times: 1,
              complete: false,
            ),
            RecipeSpend(recipeId: 'r2', name: 'Salada', cents: 1000, times: 1),
          ],
          ingredients: [IngredientSpend(name: 'Queijo', cents: 8000)],
          missingNames: ['Caldo'],
        )));
    await tester.pumpAndSettle();

    expect(find.text('Receita mais cara'), findsOneWidget);
    expect(find.text('Festa'), findsNothing);
    expect(find.text('Salada'), findsWidgets);
    expect(
        find.textContaining('1 receita ficou fora do ranking'), findsOneWidget);
  });

  testWidgets('sem nenhuma receita completa não há "mais cara"',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => const PlanCost(
          totalCents: 300,
          recipes: [
            RecipeSpend(
              recipeId: 'r1',
              name: 'Bolo',
              cents: 300,
              times: 1,
              complete: false,
            ),
          ],
          ingredients: [IngredientSpend(name: 'Ovo', cents: 300)],
          missingNames: ['Farinha'],
        )));
    await tester.pumpAndSettle();

    expect(find.text('Receita mais cara'), findsNothing);
    expect(find.text('Ingredientes que mais pesaram'), findsOneWidget);
    expect(
        find.textContaining('1 receita ficou fora do ranking'), findsOneWidget);
  });

  testWidgets('sem nada faltando o rótulo é "total planejado"', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => const PlanCost(
          totalCents: 500,
          recipes: [
            RecipeSpend(recipeId: 'r1', name: 'Ovo', cents: 500, times: 1),
          ],
          ingredients: [IngredientSpend(name: 'Ovo', cents: 500)],
          missingNames: [],
        )));
    await tester.pumpAndSettle();

    expect(find.text('TOTAL ESTIMADO'), findsOneWidget);
    expect(find.textContaining('Ficaram fora'), findsNothing);
  });

  testWidgets('nada planejado avisa', (tester) async {
    await tester.pumpWidget(_host((_) => _nothing));
    await tester.pumpAndSettle();
    expect(find.text('Nada planejado nesse período'), findsOneWidget);
  });

  testWidgets('planejado mas sem preço convida a informar', (tester) async {
    await tester.pumpWidget(_host((_) => const PlanCost(
          totalCents: 0,
          recipes: [
            RecipeSpend(recipeId: 'r1', name: 'Bolo', cents: 0, times: 1),
          ],
          ingredients: [],
          missingNames: ['Farinha'],
        )));
    await tester.pumpAndSettle();

    expect(find.text('Falta informar os preços'), findsOneWidget);
    await tester.tap(find.text('Informar preços'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA ING'), findsOneWidget);
  });

  testWidgets('trocar para Mês e navegar muda o período pedido',
      (tester) async {
    final asked = <CostPeriod>[];
    await tester.pumpWidget(_host((p) {
      asked.add(p);
      return _nothing;
    }));
    await tester.pumpAndSettle();
    expect(asked.last.kind, CostKind.week);

    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(asked.last.kind, CostKind.month);
    expect(asked.last.start, DateTime.utc(2026, 10));

    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 9));
  });

  testWidgets('tocar numa receita abre a receita', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salada'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA RECEITA r2'), findsOneWidget);
  });
}
