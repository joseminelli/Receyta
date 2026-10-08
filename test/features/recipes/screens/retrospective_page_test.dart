import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/features/recipes/controllers/retrospective_view_model.dart';
import 'package:receyta/features/recipes/screens/retrospective_page.dart';
import 'package:receyta/theme/app_theme.dart';

final _now = DateTime(2026, 10, 15);

Retrospective _full(RetroPeriod period) => Retrospective(
      period: period,
      cookCount: 12,
      distinctRecipes: 5,
      totalMinutes: 870,
      bestStreak: 3,
      newRecipes: 2,
      topRecipe: const RetroTopRecipe(id: 'r1', name: 'Lasanha', times: 4),
      topTag: const RetroTopTag(name: 'Massas', times: 7),
      busiestWeekday: DateTime.sunday,
    );

Retrospective _empty(RetroPeriod period) => Retrospective(
      period: period,
      cookCount: 0,
      distinctRecipes: 0,
      totalMinutes: 0,
      bestStreak: 0,
      newRecipes: 0,
    );

Widget _host({required Retrospective Function(RetroPeriod) build}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => RetrospectivePage(clock: () => _now),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('ROTA RECEITA ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      retrospectiveProvider.overrideWith(
        (ref, period) => AsyncData(build(period)),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('mostra o resumo do mês atual', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(build: _full));
    await tester.pumpAndSettle();

    expect(find.text('Outubro 2026'.toUpperCase()), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('vezes que você cozinhou em outubro'), findsOneWidget);
    expect(find.text('14 h 30 min'), findsOneWidget);
    expect(find.text('Domingo'), findsOneWidget);
    expect(find.text('3 dias'), findsOneWidget);
    expect(find.text('Lasanha'), findsOneWidget);
    expect(find.text('feita 4 vezes'), findsOneWidget);
    expect(find.text('Tag favorita: Massas (7×)'), findsOneWidget);
    expect(find.text('2 receitas novas salvas'), findsOneWidget);
  });

  testWidgets('mês vazio avisa em vez de mostrar zeros', (tester) async {
    await tester.pumpWidget(_host(build: _empty));
    await tester.pumpAndSettle();

    expect(find.text('Nada cozinhado em outubro'), findsOneWidget);
    expect(find.text('Compartilhar imagem'), findsNothing);
  });

  testWidgets('setas navegam, e o futuro fica travado', (tester) async {
    final seen = <RetroPeriod>[];
    await tester.pumpWidget(_host(build: (p) {
      seen.add(p);
      return _empty(p);
    }));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Período anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Nada cozinhado em setembro'), findsOneWidget);

    await tester.tap(find.byTooltip('Próximo período'));
    await tester.pumpAndSettle();
    expect(find.text('Nada cozinhado em outubro'), findsOneWidget);

    await tester.tap(find.byTooltip('Próximo período'));
    await tester.pumpAndSettle();
    expect(find.text('Nada cozinhado em outubro'), findsOneWidget);
  });

  testWidgets('trocar para Ano mostra o ano', (tester) async {
    await tester.pumpWidget(_host(build: _empty));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();
    expect(find.text('Nada cozinhado em 2026'), findsOneWidget);

    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();
    expect(find.text('Nada cozinhado em outubro'), findsOneWidget);
  });

  testWidgets('tocar na receita campeã abre a receita', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host(build: _full));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lasanha'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA RECEITA r1'), findsOneWidget);
  });
}
