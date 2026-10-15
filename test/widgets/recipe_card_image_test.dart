import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/widgets/recipe_card_image.dart';

int _u32(Uint8List b, int i) =>
    (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];

RecipeDetail _detail(
    {int ingredients = 3, int? prep, int? cook, int? servings}) {
  final t = DateTime.utc(2026);
  return RecipeDetail(
    recipe: Recipe(
      id: 'r1',
      name: 'Bolo de cenoura com cobertura de chocolate bem cremosa',
      createdAt: t,
      updatedAt: t,
      prepMinutes: prep,
      cookMinutes: cook,
      servings: servings,
    ),
    ingredients: [
      for (var i = 0; i < ingredients; i++)
        RecipeIngredient(
          id: 'i$i',
          recipeId: 'r1',
          rawText: '${i + 1} xícara de ingrediente $i',
          position: i,
        ),
    ],
    tags: const [Tag(id: 't1', name: 'Doces')],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('gera um PNG 1080×1920', (tester) async {
    final png = await tester.runAsync(
      () => renderRecipeCardPng(_detail(prep: 20, cook: 90, servings: 8)),
    );

    expect(png, isNotNull);
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(_u32(png, 16), 1080);
    expect(_u32(png, 20), 1920);
  });

  testWidgets('sem tempos, sem ingredientes e com muitos ingredientes',
      (tester) async {
    for (final d in [_detail(ingredients: 0), _detail(ingredients: 40)]) {
      final png = await tester.runAsync(() => renderRecipeCardPng(d));
      expect(png, isNotNull);
    }
  });

  testWidgets('foto ilegível cai no azulejo em vez de falhar', (tester) async {
    final png = await tester.runAsync(
      () =>
          renderRecipeCardPng(_detail(), photo: Uint8List.fromList([1, 2, 3])),
    );
    expect(png, isNotNull);
  });
}
