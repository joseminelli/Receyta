import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/sample_recipes.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/recipe_card.dart';

Widget _host() => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: RecipesPage()),
      ),
    );

void main() {
  testWidgets('renderiza os cards das receitas de exemplo', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('Receitas'), findsOneWidget);
    expect(find.byType(RecipeCard), findsWidgets);
    expect(find.text(kSampleRecipes.first.name), findsOneWidget);

    // A grade é lazy: rola até a última para confirmar que todas entram.
    await tester.scrollUntilVisible(
      find.text(kSampleRecipes.last.name),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text(kSampleRecipes.last.name), findsOneWidget);
  });

  testWidgets('começa em grade e o toggle troca para lista e volta',
      (tester) async {
    await tester.pumpWidget(_host());

    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.byType(SliverList), findsNothing);

    await tester.tap(find.bySemanticsLabel('Lista'));
    await tester.pumpAndSettle();
    expect(find.byType(SliverList), findsOneWidget);
    expect(find.byType(SliverGrid), findsNothing);

    await tester.tap(find.bySemanticsLabel('Grade'));
    await tester.pumpAndSettle();
    expect(find.byType(SliverGrid), findsOneWidget);
  });
}
