import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/theme/app_theme.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Widget host() => ProviderScope(
        overrides: [
          recipesViewModelProvider.overrideWithValue(
            RecipesViewModel(
              RecipeRepository(db.recipeDao, clock: () => DateTime.utc(2026)),
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
      );

  testWidgets('inicia em Receitas com as 3 abas', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.byType(RecipesPage), findsOneWidget);
    for (final label in ['Receitas', 'Semana', 'Compras']) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }
    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('trocar de aba mostra o placeholder e o estado é preservado',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsOneWidget);

    expect(find.byType(RecipesPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Receitas'));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsNothing);
  });
}
