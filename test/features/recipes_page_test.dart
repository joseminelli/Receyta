import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/sample_recipes.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/folder_tile.dart';
import 'package:receyta/widgets/recipe_card.dart';

Widget _host() => MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: RecipesPage()),
    );

void main() {
  testWidgets('renderiza cabeçalho, pastas e recentes', (tester) async {
    await tester.pumpWidget(_host());

    expect(find.text('$kSampleRecipeCount RECEITAS'), findsOneWidget);
    expect(find.byType(FolderTile), findsNWidgets(kSampleFolders.length));
    expect(find.text('Recentes'), findsOneWidget);
    expect(find.byType(FeaturedRecipeCard), findsOneWidget);
    expect(find.text(kSampleFeatured.name), findsOneWidget);
  });

  testWidgets('a grade de recentes traz todas as receitas de exemplo',
      (tester) async {
    await tester.pumpWidget(_host());

    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text(kSampleRecents.first.name),
      240,
      scrollable: scroll,
    );
    expect(find.byType(RecipeCard), findsWidgets);

    await tester.scrollUntilVisible(
      find.text(kSampleRecents.last.name),
      240,
      scrollable: scroll,
    );
    expect(find.text(kSampleRecents.last.name), findsOneWidget);
  });

  testWidgets('tocar num filtro muda a seleção', (tester) async {
    await tester.pumpWidget(_host());
    final lime = AppColors.light.lime;

    Color chipColor(String label) => tester
        .widget<Material>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Material))
              .first,
        )
        .color!;

    expect(chipColor('Todas'), lime);
    expect(chipColor('Massas'), isNot(lime));

    await tester.tap(find.text('Massas'));
    await tester.pump();

    expect(chipColor('Massas'), lime);
    expect(chipColor('Todas'), isNot(lime));
  });
}
