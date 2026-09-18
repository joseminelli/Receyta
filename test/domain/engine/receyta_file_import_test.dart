import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/receyta_file_import.dart';
import 'package:receyta/domain/engine/recipe_export.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1, 10);

  RecipeDetail buildDetail() {
    return RecipeDetail(
      recipe: Recipe(
        id: 'r1',
        folderId: 'f1',
        name: 'Frango ao curry',
        createdAt: createdAt,
        updatedAt: createdAt,
        prepMinutes: 15,
        servings: 4,
        sourceUrl: 'https://example.com',
        notes: 'Fica melhor no dia seguinte',
      ),
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
      steps: const [
        RecipeStep(id: 's1', recipeId: 'r1', text: 'Tempere...', position: 0),
      ],
      tags: const [Tag(id: 't1', name: 'Frango')],
    );
  }

  test('round trip: exporta e reimporta um backup completo com pastas', () {
    final json = buildFullExportJson(
      folders: const [
        Folder(id: 'f1', name: 'Massas', position: 0),
        Folder(id: 'f2', name: 'Sobremesas', parentId: 'f1', position: 1),
      ],
      recipes: [buildDetail()],
      ingredientNames: const {'ing1': 'peito de frango'},
      clock: () => createdAt,
    );

    final parsed = parseReceytaFile(jsonEncode(json));

    expect(parsed, isNotNull);
    expect(parsed!.schemaVersion, 1);
    expect(parsed.kind, 'full');
    expect(parsed.folders, hasLength(2));
    expect(parsed.folders[0].sourceId, 'f1');
    expect(parsed.folders[0].parentSourceId, isNull);
    expect(parsed.folders[1].parentSourceId, 'f1');

    expect(parsed.recipes, hasLength(1));
    final recipe = parsed.recipes.single;
    expect(recipe.sourceId, 'r1');
    expect(recipe.name, 'Frango ao curry');
    expect(recipe.folderSourceId, 'f1');
    expect(recipe.prepMinutes, 15);
    expect(recipe.servings, 4);
    expect(recipe.sourceUrl, 'https://example.com');
    expect(recipe.tags, ['Frango']);

    final ingredient = recipe.ingredients.single;
    expect(ingredient.name, 'peito de frango');
    expect(ingredient.rawText, '500g de peito de frango em cubos');
    expect(ingredient.quantity, 500);
    expect(ingredient.unit, 'g');
    expect(ingredient.qualifier, 'em cubos');

    expect(recipe.steps.single.text, 'Tempere...');
  });

  test('round trip: export de uma receita só (kind "recipes") sem pastas',
      () {
    final json = buildRecipeExportJson(
      buildDetail(),
      ingredientNames: const {'ing1': 'peito de frango'},
      clock: () => createdAt,
    );

    final parsed = parseReceytaFile(jsonEncode(json));

    expect(parsed, isNotNull);
    expect(parsed!.kind, 'recipes');
    expect(parsed.folders, isEmpty);
    expect(parsed.recipes, hasLength(1));
  });

  test('JSON inválido devolve null', () {
    expect(parseReceytaFile('{ isso não é json'), isNull);
  });

  test('sem schemaVersion devolve null', () {
    expect(parseReceytaFile(jsonEncode({'kind': 'recipes', 'recipes': []})),
        isNull);
  });

  test('schemaVersion não suportada devolve null', () {
    expect(
      parseReceytaFile(jsonEncode({
        'schemaVersion': 99,
        'kind': 'recipes',
        'recipes': [],
      })),
      isNull,
    );
  });

  test('sem a lista "recipes" devolve null', () {
    expect(
      parseReceytaFile(jsonEncode({'schemaVersion': 1, 'kind': 'recipes'})),
      isNull,
    );
  });

  test('receita sem "name" é descartada, resto da lista sobrevive', () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'recipes',
      'recipes': [
        {'about': 'sem nome'},
        {'name': 'Bolo'},
      ],
    }));

    expect(parsed, isNotNull);
    expect(parsed!.recipes, hasLength(1));
    expect(parsed.recipes.single.name, 'Bolo');
  });

  test('nome da receita normaliza pra Title Case, igual a tag', () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'recipes',
      'recipes': [
        {'name': 'BOLO DE FUBÁ'},
      ],
    }));

    expect(parsed!.recipes.single.name, 'Bolo de Fubá');
  });

  test('ingrediente sem "name" ou "rawText" é descartado', () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'recipes',
      'recipes': [
        {
          'name': 'Bolo',
          'ingredients': [
            {'rawText': '2 ovos'},
            {'rawText': '1 xícara de farinha', 'name': 'farinha'},
          ],
        },
      ],
    }));

    final ingredients = parsed!.recipes.single.ingredients;
    expect(ingredients, hasLength(1));
    expect(ingredients.single.name, 'farinha');
  });

  test('posição do ingrediente/passo cai pro índice quando falta no JSON',
      () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'recipes',
      'recipes': [
        {
          'name': 'Bolo',
          'ingredients': [
            {'rawText': '2 ovos', 'name': 'ovo'},
            {'rawText': '1 xícara de farinha', 'name': 'farinha'},
          ],
          'steps': [
            {'text': 'Bata os ovos'},
            {'text': 'Adicione a farinha'},
          ],
        },
      ],
    }));

    final recipe = parsed!.recipes.single;
    expect(recipe.ingredients.map((i) => i.position), [0, 1]);
    expect(recipe.steps.map((s) => s.position), [0, 1]);
  });

  test('receita sem "id" no JSON vira sourceId nulo (sempre nova no import)',
      () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'recipes',
      'recipes': [
        {'name': 'Bolo'},
      ],
    }));

    expect(parsed!.recipes.single.sourceId, isNull);
  });

  test('pasta sem "id" ou "name" é descartada', () {
    final parsed = parseReceytaFile(jsonEncode({
      'schemaVersion': 1,
      'kind': 'full',
      'folders': [
        {'parentId': null, 'name': 'Sem id'},
        {'id': 'f1', 'name': 'Massas'},
      ],
      'recipes': [
        {'name': 'Bolo'},
      ],
    }));

    expect(parsed!.folders, hasLength(1));
    expect(parsed.folders.single.sourceId, 'f1');
  });
}
