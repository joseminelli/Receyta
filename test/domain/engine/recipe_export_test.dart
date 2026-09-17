import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_export.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1, 10);
  final updatedAt = DateTime.utc(2026, 2, 2, 11);
  final exportedAt = DateTime.utc(2026, 9, 17, 14, 30);

  RecipeDetail buildDetail({
    String? sourceUrl,
    List<RecipeIngredient> ingredients = const [],
  }) {
    return RecipeDetail(
      recipe: Recipe(
        id: 'r1',
        name: 'Frango ao curry',
        createdAt: createdAt,
        updatedAt: updatedAt,
        about: 'Rápido, para dias de semana',
        prepMinutes: 15,
        cookMinutes: 25,
        servings: 4,
        sourceUrl: sourceUrl,
        notes: 'Fica melhor no dia seguinte',
      ),
      ingredients: ingredients,
      steps: const [
        RecipeStep(
          id: 's1',
          recipeId: 'r1',
          text: 'Tempere o frango...',
          position: 0,
        ),
      ],
      tags: const [Tag(id: 't1', name: 'Frango'), Tag(id: 't2', name: 'Rápido')],
    );
  }

  test('monta o envelope com schemaVersion, exportedAt e kind "recipes"', () {
    final json = buildRecipeExportJson(
      buildDetail(),
      ingredientNames: const {},
      clock: () => exportedAt,
    );

    expect(json['schemaVersion'], 1);
    expect(json['exportedAt'], '2026-09-17T14:30:00.000Z');
    expect(json['app'], 'receyta');
    expect(json['kind'], 'recipes');
    expect(json['recipes'], hasLength(1));
  });

  test('campos da receita e datas em ISO 8601', () {
    final json = buildRecipeExportJson(
      buildDetail(sourceUrl: 'https://example.com/receita'),
      ingredientNames: const {},
      clock: () => exportedAt,
    );

    final recipe = json['recipes'][0] as Map<String, dynamic>;
    expect(recipe['name'], 'Frango ao curry');
    expect(recipe['about'], 'Rápido, para dias de semana');
    expect(recipe['prepMinutes'], 15);
    expect(recipe['cookMinutes'], 25);
    expect(recipe['servings'], 4);
    expect(recipe['sourceUrl'], 'https://example.com/receita');
    expect(recipe['notes'], 'Fica melhor no dia seguinte');
    expect(recipe['tags'], ['Frango', 'Rápido']);
    expect(recipe['createdAt'], createdAt.toIso8601String());
    expect(recipe['updatedAt'], updatedAt.toIso8601String());
  });

  test('ingrediente resolvido usa o nome do catálogo, não o rawText', () {
    final json = buildRecipeExportJson(
      buildDetail(
        ingredients: const [
          RecipeIngredient(
            id: 'i1',
            recipeId: 'r1',
            rawText: '500g de peito de frango em cubos',
            position: 0,
            ingredientId: 'ing1',
            quantity: 500,
            unitId: 'g',
            qualifier: 'em cubos',
          ),
        ],
      ),
      ingredientNames: const {'ing1': 'peito de frango'},
      clock: () => exportedAt,
    );

    final ingredient =
        (json['recipes'][0]['ingredients'] as List)[0] as Map<String, dynamic>;
    expect(ingredient['position'], 0);
    expect(ingredient['rawText'], '500g de peito de frango em cubos');
    expect(ingredient['quantity'], 500);
    expect(ingredient['unit'], 'g');
    expect(ingredient['name'], 'peito de frango');
    expect(ingredient['qualifier'], 'em cubos');
  });

  test('ingrediente sem ingredientId cai pro nome que o parser extrai', () {
    final json = buildRecipeExportJson(
      buildDetail(
        ingredients: const [
          RecipeIngredient(
            id: 'i1',
            recipeId: 'r1',
            rawText: '2 xícaras de farinha de trigo',
            position: 0,
          ),
        ],
      ),
      ingredientNames: const {},
      clock: () => exportedAt,
    );

    final ingredient =
        (json['recipes'][0]['ingredients'] as List)[0] as Map<String, dynamic>;
    expect(ingredient['name'], 'farinha de trigo');
  });

  test('ingrediente sem nada aproveitável cai pro rawText cru', () {
    final json = buildRecipeExportJson(
      buildDetail(
        ingredients: const [
          RecipeIngredient(
            id: 'i1',
            recipeId: 'r1',
            rawText: 'de',
            position: 0,
          ),
        ],
      ),
      ingredientNames: const {},
      clock: () => exportedAt,
    );

    final ingredient =
        (json['recipes'][0]['ingredients'] as List)[0] as Map<String, dynamic>;
    expect(ingredient['name'], 'de');
  });

  test('passos preservam position, groupLabel e text', () {
    final json = buildRecipeExportJson(
      buildDetail(),
      ingredientNames: const {},
      clock: () => exportedAt,
    );

    final step = (json['recipes'][0]['steps'] as List)[0] as Map<String, dynamic>;
    expect(step['position'], 0);
    expect(step['groupLabel'], isNull);
    expect(step['text'], 'Tempere o frango...');
  });
}
