import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';

Recipe _recipe({int? prep, int? cook, int? servings, bool fav = false}) {
  final t = DateTime.utc(2026);
  return Recipe(
    id: 'f1',
    name: 'Frango ao curry',
    createdAt: t,
    updatedAt: t,
    prepMinutes: prep,
    cookMinutes: cook,
    servings: servings,
    isFavorite: fav,
  );
}

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 340, child: child)),
    );

void main() {
  testWidgets('nome, tempo e chips', (tester) async {
    await tester.pumpWidget(
      _host(FeaturedRecipeCard(
        recipe: _recipe(prep: 15, cook: 25, servings: 4, fav: true),
      )),
    );

    expect(find.text('Frango ao curry'), findsOneWidget);
    expect(find.text('40 min'), findsOneWidget); // chip na faixa preta
    expect(find.text('4 porções'), findsOneWidget);
    expect(find.text('Favorita'), findsOneWidget);
  });

  testWidgets('sem tempo não mostra o chip de minutos', (tester) async {
    await tester.pumpWidget(
      _host(FeaturedRecipeCard(recipe: _recipe(servings: 2))),
    );
    expect(find.textContaining('min'), findsNothing);
    expect(find.text('2 porções'), findsOneWidget);
  });
}
