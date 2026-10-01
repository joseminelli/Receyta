import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/screens/recipes_page.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/theme/app_theme.dart';

Widget _host() => ProviderScope(
      overrides: [
        recipesStreamProvider
            .overrideWith((ref) => Stream.value(const <Recipe>[])),
        inUseTagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
        trashedRecipesProvider
            .overrideWith((ref) => Stream.value(const <Recipe>[])),
        hasFavoritesProvider.overrideWith((ref) => Stream.value(false)),
        tagsWithCountsProvider.overrideWith(
          (ref) => Stream.value(const <({Tag tag, int count})>[]),
        ),
        // A aba Compras é montada de cara pelo `IndexedStack`, mesmo sem
        // trocar de aba — sem isto cairia no banco de verdade.
        upcomingEntriesProvider.overrideWith(
          (ref, from) => Stream.value(const <MealPlanEntry>[]),
        ),
        monthEntriesProvider.overrideWith(
          (ref, month) => Stream.value(const <MealPlanEntry>[]),
        ),
        shoppingListsProvider
            .overrideWith((ref) => Stream.value(const <ShoppingListSummary>[])),
        libraryStatsProvider.overrideWithValue(
          const AsyncData((
            recipes: 0,
            folders: 0,
            lists: 0,
            plannedMeals: 0,
            doneMeals: 0,
            topRecipe: null,
            topRecipeCount: 0,
          )),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
    );

/// Tela de celular (390×844): na superfície padrão do teste (800×600) as
/// células quadradas ficam enormes e a grade passa da altura da tela.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('inicia em Receitas com as 4 abas', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byType(RecipesPage), findsOneWidget);
    // RegExp, não igualdade: no slot ativo o label do Semantics funde com o
    // Text visível ("Receitas Receitas").
    for (final label in ['Receitas', 'Semana', 'Compras', 'Conta']) {
      expect(find.bySemanticsLabel(RegExp(label)), findsWidgets);
    }
    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('trocar de aba mostra a semana e o estado da home é preservado',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Semana'));
    await tester.pumpAndSettle();
    expect(find.text('Nada planejado pros próximos dias.'), findsOneWidget);

    expect(find.byType(RecipesPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Receitas'));
    await tester.pumpAndSettle();
    expect(find.text('Nada planejado pros próximos dias.'), findsNothing);
  });

  testWidgets(
      'aba Compras mostra a tela de compras de verdade (não placeholder)',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Compras'));
    await tester.pumpAndSettle();

    expect(find.text('Em breve'), findsNothing);
    expect(find.text('Nenhuma lista ainda'), findsOneWidget);
    expect(find.text('Gerar de receitas'), findsOneWidget);
  });

  testWidgets('aba Conta mostra o perfil local e o botão de config',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('Conta')));
    await tester.pumpAndSettle();

    expect(find.text('Seu nome aqui'), findsOneWidget);
    expect(find.text('Sincronização em breve'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
