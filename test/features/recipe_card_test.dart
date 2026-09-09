import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/recipe_card.dart';

Recipe _recipe({int? prep, int? cook}) {
  final t = DateTime.utc(2026);
  return Recipe(
    id: 'r1',
    name: 'Estrogonofe de frango',
    createdAt: t,
    updatedAt: t,
    prepMinutes: prep,
    cookMinutes: cook,
  );
}

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: 200, child: child))),
    );

void main() {
  testWidgets('mostra o nome', (tester) async {
    await tester.pumpWidget(_host(RecipeCard(recipe: _recipe())));
    expect(find.text('Estrogonofe de frango'), findsOneWidget);
  });

  testWidgets('mostra o tempo total quando há prep/cook', (tester) async {
    await tester.pumpWidget(_host(RecipeCard(recipe: _recipe(prep: 15, cook: 20))));
    expect(find.widgetWithText(HeroNumber, '35'), findsOneWidget);
  });

  testWidgets('sem prep/cook não mostra número', (tester) async {
    await tester.pumpWidget(_host(RecipeCard(recipe: _recipe())));
    expect(find.byType(HeroNumber), findsNothing);
  });

  testWidgets('onTap dispara', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(RecipeCard(recipe: _recipe(), onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(RecipeCard));
    expect(tapped, isTrue);
  });
}
