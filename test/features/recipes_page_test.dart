import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/recipe_card.dart';

Recipe _recipe(String id, String name) {
  final t = DateTime.utc(2026);
  return Recipe(id: id, name: name, createdAt: t, updatedAt: t);
}

Widget _host({
  required List<Recipe> recipes,
  RecipesViewModel? viewModel,
}) {
  return ProviderScope(
    overrides: [
      recipesStreamProvider.overrideWith((ref) => Stream.value(recipes)),
      if (viewModel != null)
        recipesViewModelProvider.overrideWithValue(viewModel),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: RecipesPage()),
    ),
  );
}

void main() {
  testWidgets('sem receitas mostra o estado vazio', (tester) async {
    await tester.pumpWidget(_host(recipes: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma receita ainda'), findsOneWidget);
    expect(find.text('0 RECEITAS'), findsOneWidget);
    expect(find.byType(FeaturedRecipeCard), findsNothing);
  });

  testWidgets('primeira receita vira o destaque, o resto vai pra grade',
      (tester) async {
    await tester.pumpWidget(_host(recipes: [
      _recipe('a', 'Sopa de abóbora'),
      _recipe('b', 'Risoto de limão'),
      _recipe('c', 'Farofa de ovo'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('3 RECEITAS'), findsOneWidget);
    expect(find.text('Recentes'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeaturedRecipeCard),
        matching: find.text('Sopa de abóbora'),
      ),
      findsOneWidget,
    );
    expect(find.byType(RecipeCard), findsNWidgets(2));
  });

  testWidgets('criar receita só com nome grava pelo view model', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = RecipeRepository(db.recipeDao, clock: () => DateTime.utc(2026));

    await tester.pumpWidget(_host(
      recipes: const [],
      viewModel: RecipesViewModel(repo),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Farofa de ovo  ');
    await tester.pump();
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    final saved = await tester.runAsync(() => repo.watchAll().first);
    expect(saved!.map((r) => r.name), ['Farofa de ovo']);
  });

  testWidgets('Criar fica desabilitado enquanto o nome está vazio',
      (tester) async {
    await tester.pumpWidget(_host(recipes: const []));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    PillButton criar() =>
        tester.widget<PillButton>(find.widgetWithText(PillButton, 'Criar'));
    expect(criar().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Pão');
    await tester.pump();
    expect(criar().onPressed, isNotNull);
  });
}
