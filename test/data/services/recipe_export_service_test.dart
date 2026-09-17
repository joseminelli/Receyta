import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late FolderRepository folderRepo;
  late RecipeExportService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    folderRepo = FolderRepository(db.folderDao, db.recipeDao);
    service = RecipeExportService(repo, folderRepo, db.ingredientDao);
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

  test('buildFullBackupPayload inclui pastas e todas as receitas ativas',
      () async {
    final folder = (await folderRepo.create(name: 'Massas') as Ok).value;
    final inFolder = (await repo.saveDetail(
      name: 'Lasanha',
      ingredientLines: ['1 caixa de massa'],
    ) as Ok<Recipe>)
        .value;
    await folderRepo.moveRecipe(inFolder.id, folder.id);
    await repo.saveDetail(name: 'Bolo', ingredientLines: ['2 ovos']);

    final payload =
        (await service.buildFullBackupPayload() as Ok).value;

    expect(payload['kind'], 'full');
    expect(payload['folders'], [
      {
        'id': folder.id,
        'parentId': null,
        'name': 'Massas',
        'position': 0,
      },
    ]);

    final recipes = payload['recipes'] as List;
    expect(recipes, hasLength(2));
    final names = recipes.map((r) => r['name']).toSet();
    expect(names, {'Lasanha', 'Bolo'});
    final lasanha =
        recipes.firstWhere((r) => r['name'] == 'Lasanha') as Map;
    expect(lasanha['folderId'], folder.id);
    expect(
      (lasanha['ingredients'] as List)[0]['name'],
      'massa',
    );
  });

  test('buildFullBackupPayload não inclui receita na lixeira', () async {
    final recipe = (await repo.saveDetail(name: 'Descartada') as Ok<Recipe>)
        .value;
    await repo.softDelete(recipe.id);

    final payload =
        (await service.buildFullBackupPayload() as Ok).value;

    expect(payload['recipes'], isEmpty);
  });
}
