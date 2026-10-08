import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/screens/costs_page.dart';
import 'package:receyta/theme/app_theme.dart';

final _now = DateTime(2026, 10, 15);

Widget _host(
  PlanCost Function(CostPeriod) build, {
  List<LibraryRecipeCost> library = const [],
}) {
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
      libraryCostsProvider.overrideWith((ref) async => library),
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

LibraryRecipeCost _lib(String id, String name, int cents, {int? perServing}) =>
    LibraryRecipeCost(
      recipe: Recipe(
        id: id,
        name: name,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      cents: cents,
      perServing: perServing,
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

  testWidgets('total no alto, o que falta e o ranking por receita',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    expect(find.text('ESTIMATIVA MÍNIMA'), findsOneWidget);
    expect(find.text('R\$ 123,40'), findsOneWidget);
    expect(find.text('2 refeições planejadas'), findsOneWidget);
    expect(find.text('Falta o preço de 1 ingrediente'), findsOneWidget);

    expect(find.text('Onde foi o dinheiro'), findsOneWidget);
    expect(find.text('Lasanha ×2'), findsOneWidget);
    expect(find.text('MAIS CARA'), findsOneWidget);
    expect(find.text('R\$ 80,00'), findsOneWidget);
    expect(find.text('Salada'), findsOneWidget);
    // Os avisos longos ficam atrás de "como é calculado".
    expect(find.textContaining('Valor estimado.'), findsNothing);
  });

  testWidgets('"como é calculado" abre as duas notas', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Estimativa · como é calculado'));
    await tester.tap(find.text('Estimativa · como é calculado'));
    await tester.pumpAndSettle();

    expect(find.text('Como é calculado'), findsOneWidget);
    expect(find.textContaining('Valor estimado.'), findsOneWidget);
    expect(find.textContaining('só neste aparelho'), findsOneWidget);

    await tester.tap(find.text('Entendi'));
    await tester.pumpAndSettle();
    expect(find.text('Como é calculado'), findsNothing);
  });

  testWidgets('trocar para "Por ingrediente" mostra o outro ranking',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Por ingrediente'));
    await tester.pumpAndSettle();

    expect(find.text('Queijo'), findsOneWidget);
    expect(find.text('R\$ 60,00'), findsOneWidget);
    expect(find.text('Tomate'), findsOneWidget);
    expect(find.text('Lasanha ×2'), findsNothing);
  });

  testWidgets('receita incompleta some do ranking, sem grupo à parte',
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

    expect(find.text('Festa'), findsNothing);
    expect(find.text('SEM PREÇO COMPLETO'), findsNothing);
    expect(find.text('faltam preços'), findsNothing);
    expect(find.text('Salada'), findsOneWidget);
    // Sozinha no ranking, a Salada não ganha a etiqueta de "mais cara".
    expect(find.text('MAIS CARA'), findsNothing);
    expect(find.text('R\$ 10,00'), findsOneWidget);
  });

  testWidgets('nenhuma planejada completa: o ranking explica e não lista',
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

    expect(
      find.text(
        'Nenhuma receita planejada tem o preço de todos os ingredientes ainda.',
      ),
      findsOneWidget,
    );
    expect(find.text('Bolo'), findsNothing);
    expect(find.text('MAIS CARA'), findsNothing);
  });

  testWidgets('"Mais caras" lista a biblioteca, mesmo sem planejar',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host(
      (_) => _nothing,
      library: [
        _lib('r1', 'Lasanha', 8000, perServing: 2000),
        _lib('r2', 'Salada', 1500),
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Nada planejado nesse período'), findsOneWidget);

    await tester.tap(find.text('Mais caras'));
    await tester.pumpAndSettle();

    expect(find.text('2 receitas com preço completo'), findsOneWidget);
    expect(find.text('Lasanha'), findsOneWidget);
    expect(find.text('MAIS CARA'), findsOneWidget);
    expect(find.text('R\$ 80,00'), findsOneWidget);
    expect(find.text('R\$ 20,00 por porção'), findsOneWidget);
    expect(find.text('Salada'), findsOneWidget);
    // O seletor de período é do planejado, não daqui.
    expect(find.byTooltip('Período anterior'), findsNothing);

    await tester.tap(find.text('Salada'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA RECEITA r2'), findsOneWidget);
  });

  testWidgets('sem nenhuma receita completa na biblioteca, convida a informar',
      (tester) async {
    await tester.pumpWidget(_host((_) => _nothing));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mais caras'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma receita com preço completo'), findsOneWidget);

    await tester.tap(find.text('Informar preços'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA ING'), findsOneWidget);
  });

  testWidgets('sem nada faltando o rótulo é "total estimado"', (tester) async {
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
    expect(find.textContaining('Falta'), findsNothing);
    expect(find.text('1 refeição planejada'), findsOneWidget);
  });

  testWidgets('"Informar" leva pra tela de ingredientes', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(_host((_) => _full));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Informar'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA ING'), findsOneWidget);
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

  testWidgets('a faixa de períodos: semana/mês e pular direto pra um período',
      (tester) async {
    final asked = <CostPeriod>[];
    await tester.pumpWidget(_host((p) {
      asked.add(p);
      return _nothing;
    }));
    await tester.pumpAndSettle();
    expect(asked.last.kind, CostKind.week);
    expect(asked.last.start, DateTime.utc(2026, 10, 12));
    expect(find.byKey(const Key('period-chip-2026-10-12')), findsOneWidget);

    // Um toque na semana anterior pula pra ela.
    await tester.tap(find.byKey(const Key('period-chip-2026-10-05')));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 10, 5));

    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(asked.last.kind, CostKind.month);
    expect(asked.last.start, DateTime.utc(2026, 10));

    await tester.tap(find.byKey(const Key('period-chip-2026-09-01')));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 9));
  });

  testWidgets('alternar Semana/Mês várias vezes não faz o período derivar',
      (tester) async {
    final asked = <CostPeriod>[];
    await tester.pumpWidget(_host((p) {
      asked.add(p);
      return _nothing;
    }));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 10, 12));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Mês'));
      await tester.pumpAndSettle();
      expect(asked.last.start, DateTime.utc(2026, 10));

      await tester.tap(find.text('Semana'));
      await tester.pumpAndSettle();
      expect(asked.last.start, DateTime.utc(2026, 10, 12));
    }
  });

  testWidgets('alternar a partir de uma semana antiga volta pra ela',
      (tester) async {
    final asked = <CostPeriod>[];
    await tester.pumpWidget(_host((p) {
      asked.add(p);
      return _nothing;
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('period-chip-2026-10-05')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 10));

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    expect(asked.last.start, DateTime.utc(2026, 10, 5));
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
