import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_pdf.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);

  RecipeDetail buildDetail({
    List<RecipeIngredient> ingredients = const [],
    List<RecipeStep> steps = const [],
  }) {
    return RecipeDetail(
      recipe: Recipe(
        id: 'r1',
        name: 'Frango ao curry',
        createdAt: createdAt,
        updatedAt: createdAt,
        about: 'Rápido, para dias de semana',
        prepMinutes: 15,
        cookMinutes: 25,
        servings: 4,
        notes: 'Fica melhor no dia seguinte',
      ),
      ingredients: ingredients,
      steps: steps,
      tags: const [Tag(id: 't1', name: 'Frango')],
    );
  }

  test('gera bytes de um PDF válido (assinatura %PDF)', () async {
    final bytes = await buildRecipePdf(buildDetail());
    expect(bytes.length, greaterThan(0));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('não lança exceção sem ingredientes/passos/notas', () async {
    final detail = RecipeDetail(
      recipe: Recipe(
        id: 'r2',
        name: 'Receita mínima',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    final bytes = await buildRecipePdf(detail);
    expect(bytes.length, greaterThan(0));
  });

  test('gera com ingredientes e passos agrupados sem lançar', () async {
    final detail = buildDetail(
      ingredients: const [
        RecipeIngredient(
          id: 'i1',
          recipeId: 'r1',
          rawText: '500g de farinha de trigo',
          position: 0,
          groupLabel: 'Massa',
          quantity: 500,
          unitId: 'g',
          ingredientName: 'Farinha de Trigo',
        ),
        RecipeIngredient(
          id: 'i2',
          recipeId: 'r1',
          rawText: '2 ovos',
          position: 1,
          groupLabel: 'Massa',
          quantity: 2,
          unitId: 'unidade',
          ingredientName: 'Ovo',
        ),
      ],
      steps: const [
        RecipeStep(
          id: 's1',
          recipeId: 'r1',
          text: 'Misture os secos.',
          position: 0,
          groupLabel: 'Massa',
        ),
        RecipeStep(
          id: 's2',
          recipeId: 'r1',
          text: 'Adicione os ovos.',
          position: 1,
          groupLabel: 'Massa',
        ),
      ],
    );
    final bytes = await buildRecipePdf(detail);
    expect(bytes.length, greaterThan(0));
  });
}
