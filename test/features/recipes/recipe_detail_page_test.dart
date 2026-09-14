import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipe_detail_page.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';

RecipeDetail _detail() {
  final t = DateTime.utc(2026);
  return RecipeDetail(
    recipe: Recipe(
      id: 'r1',
      name: 'Frango ao curry',
      createdAt: t,
      updatedAt: t,
      about: 'rápido para a semana',
      prepMinutes: 15,
      cookMinutes: 25,
      servings: 4,
      notes: 'melhor no dia seguinte',
    ),
    ingredients: const [
      RecipeIngredient(
        id: 'i1',
        recipeId: 'r1',
        rawText: '500g de frango',
        position: 0,
        quantity: 500,
        unitId: 'g',
      ),
      RecipeIngredient(
        id: 'i2',
        recipeId: 'r1',
        rawText: '2 dentes de alho',
        position: 1,
        quantity: 2,
        unitId: 'dente',
      ),
    ],
    steps: const [
      RecipeStep(id: 's1', recipeId: 'r1', text: 'Tempere o frango', position: 0),
      RecipeStep(id: 's2', recipeId: 'r1', text: 'Refogue o alho', position: 1),
    ],
    tags: const [Tag(id: 't1', name: 'Rápido'), Tag(id: 't2', name: 'Frango')],
  );
}

Widget _host({RecipeDetail? detail}) {
  final router = GoRouter(
    initialLocation: '/recipe/r1',
    routes: [
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => RecipeDetailPage(recipeId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/recipe/:id/edit',
        builder: (_, __) => const Text('ROTA EDIT'),
      ),
      GoRoute(
        path: '/recipe/:id/cook',
        builder: (_, __) => const Text('ROTA COZINHA'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeDetailProvider.overrideWith((ref, id) => Stream.value(detail)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('mostra nome, métricas, ingredientes e passos', (tester) async {
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    expect(find.text('Frango ao curry'), findsOneWidget);
    expect(find.text('rápido para a semana'), findsOneWidget);
    expect(find.text('Ingredientes'), findsOneWidget);
    expect(find.text('2 itens'), findsOneWidget);
    expect(find.text('500 g', findRichText: true), findsOneWidget);
    expect(find.text('frango', findRichText: true), findsOneWidget);
    expect(find.text('2 dentes', findRichText: true), findsOneWidget);
    expect(find.text('alho', findRichText: true), findsOneWidget);
    expect(find.text('Preparo'), findsOneWidget);
    expect(find.text('Tempere o frango'), findsOneWidget);
    expect(find.text('melhor no dia seguinte'), findsOneWidget);
    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('Frango'), findsOneWidget);
    expect(find.text('Modo cozinha'), findsOneWidget);
  });

  testWidgets('sem passos, não mostra "Modo cozinha"', (tester) async {
    await tester.pumpWidget(_host(
      detail: RecipeDetail(
        recipe: Recipe(
          id: 'r1',
          name: 'Vitamina',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Modo cozinha'), findsNothing);
  });

  testWidgets('"Modo cozinha" abre o modo cozinha', (tester) async {
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modo cozinha'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA COZINHA'), findsOneWidget);
  });

  testWidgets('receita inexistente mostra aviso', (tester) async {
    await tester.pumpWidget(_host(detail: null));
    await tester.pumpAndSettle();

    expect(find.text('Receita não encontrada'), findsOneWidget);
  });

  testWidgets('botão editar abre o formulário de edição', (tester) async {
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('ROTA EDIT'), findsOneWidget);
  });
}
