import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late RecipeExportService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    service = RecipeExportService(repo, db.ingredientDao);
  });
  tearDown(() => db.close());

  test('buildPayload resolve o nome do ingrediente pelo catálogo', () async {
    final recipe = (await repo.saveDetail(
      name: 'Salada',
      ingredientLines: ['3 tomates', '1 pitada de sal'],
      stepLines: ['Corte tudo', 'Misture'],
      tagNames: ['Rápido'],
    ) as Ok<Recipe>)
        .value;

    final payload = (await service.buildPayload(recipe.id) as Ok).value;

    expect(payload['kind'], 'recipes');
    final json = payload['recipes'][0] as Map<String, dynamic>;
    expect(json['name'], 'Salada');
    expect(json['tags'], ['Rápido']);

    final ingredients = json['ingredients'] as List;
    expect(ingredients, hasLength(2));
    expect(ingredients[0]['name'], 'tomates');
    expect(ingredients[0]['unit'], isNull);
    expect(ingredients[1]['name'], 'sal');
    expect(ingredients[1]['unit'], 'pitada');

    final steps = json['steps'] as List;
    expect(steps.map((s) => s['text']), ['Corte tudo', 'Misture']);
  });

  test('buildPayload devolve Err quando a receita não existe', () async {
    final result = await service.buildPayload('inexistente');
    expect(result, isA<Err<Map<String, dynamic>>>());
  });
}
