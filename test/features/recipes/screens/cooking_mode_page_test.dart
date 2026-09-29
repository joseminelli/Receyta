import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/features/recipes/cooking_mode_page.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';

RecipeDetail _detail({List<RecipeStep> steps = _steps}) => RecipeDetail(
      recipe: Recipe(
        id: 'r1',
        name: 'Frango ao curry',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      ingredients: const [
        RecipeIngredient(
            id: 'i1', recipeId: 'r1', rawText: '500g de frango', position: 0),
        RecipeIngredient(
            id: 'i2', recipeId: 'r1', rawText: '400ml de leite de coco',
            position: 1),
      ],
      steps: steps,
    );

const _steps = [
  RecipeStep(id: 's1', recipeId: 'r1', text: 'Tempere o frango', position: 0),
  RecipeStep(id: 's2', recipeId: 'r1', text: 'Refogue o alho', position: 1),
  RecipeStep(id: 's3', recipeId: 'r1', text: 'Junte o leite de coco', position: 2),
];

Widget _host(RecipeDetail? detail) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/cook'),
              child: const Text('ir'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/cook',
        builder: (_, __) => const CookingModePage(recipeId: 'r1'),
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

Future<void> _open(WidgetTester tester, RecipeDetail? detail) async {
  await tester.pumpWidget(_host(detail));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ir'));
  await tester.pumpAndSettle();
}

Text _stepText(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text));

void main() {
  testWidgets('lista todos os passos e os ingredientes de cara', (tester) async {
    await _open(tester, _detail());

    expect(find.text('Tempere o frango'), findsOneWidget);
    expect(find.text('Refogue o alho'), findsOneWidget);
    expect(find.text('Junte o leite de coco'), findsOneWidget);
    // Ingredientes abertos por padrão.
    expect(find.text('500g de frango'), findsOneWidget);
  });

  testWidgets('recolher os ingredientes some com a lista', (tester) async {
    await _open(tester, _detail());

    await tester.tap(find.text('INGREDIENTES'));
    await tester.pumpAndSettle();

    expect(find.text('500g de frango'), findsNothing);
  });

  testWidgets('tocar num passo risca o texto (marca como feito)',
      (tester) async {
    await _open(tester, _detail());

    expect(
      _stepText(tester, 'Tempere o frango').style?.decoration,
      isNot(TextDecoration.lineThrough),
    );

    await tester.tap(find.text('Tempere o frango'));
    await tester.pumpAndSettle();

    expect(
      _stepText(tester, 'Tempere o frango').style?.decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('sem passos, mostra aviso e mantém ingredientes', (tester) async {
    await _open(tester, _detail(steps: const []));

    expect(find.textContaining('não tem passos'), findsOneWidget);
    expect(find.text('500g de frango'), findsOneWidget);
  });
}
