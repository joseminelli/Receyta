import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/receyta_import_service.dart';
import 'package:receyta/domain/engine/receyta_file_import.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late FolderRepository folderRepo;
  late ReceytaImportService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    folderRepo = FolderRepository(db.folderDao, db.recipeDao);
    service = ReceytaImportService(
      db.recipeDao,
      db.folderDao,
      db.ingredientDao,
      db.tagDao,
    );
  });
  tearDown(() => db.close());

  ParsedReceytaFile parsedFullFile({
    List<ParsedFolderImport> folders = const [],
    List<ParsedRecipeImport> recipes = const [],
  }) {
    return ParsedReceytaFile(
      schemaVersion: 1,
      kind: 'full',
      folders: folders,
      recipes: recipes,
    );
  }

  test('importa receita simples com ingrediente, passo e tag', () async {
    final result = await service.importParsedFile(parsedFullFile(recipes: [
      const ParsedRecipeImport(
        name: 'Bolo de fubá',
        about: 'Da vovó',
        prepMinutes: 10,
        servings: 8,
        tags: ['Doce'],
        ingredients: [
          ParsedIngredientImport(
            position: 0,
            rawText: '2 xícaras de fubá',
            quantity: 2,
            unit: 'xicara',
            name: 'fubá',
          ),
        ],
        steps: [ParsedStepImport(position: 0, text: 'Misture tudo')],
      ),
    ]));

    expect(result, isA<Ok<ImportSummary>>());
    expect((result as Ok<ImportSummary>).value, (recipes: 1, folders: 0));

    final all = await repo.watchAll().first;
    expect(all, hasLength(1));
    final detail =
        (await repo.getDetail(all.single.id) as Ok<RecipeDetail>).value;
    expect(detail.recipe.name, 'Bolo de fubá');
    expect(detail.recipe.about, 'Da vovó');
    expect(detail.recipe.prepMinutes, 10);
    expect(detail.tags.map((t) => t.name), ['Doce']);

    final ingredient = detail.ingredients.single;
    expect(ingredient.rawText, '2 xícaras de fubá');
    expect(ingredient.quantity, 2);
    expect(ingredient.unitId, 'xicara');
    expect(ingredient.ingredientId, isNotNull);

    expect(detail.steps.single.text, 'Misture tudo');
  });

  test('reconcilia ingrediente com o catálogo já existente', () async {
    final existing = await db.ingredientDao.getOrCreate('Tomate');

    await service.importParsedFile(parsedFullFile(recipes: [
      const ParsedRecipeImport(
        name: 'Salada',
        ingredients: [
          ParsedIngredientImport(
            position: 0,
            rawText: '3 tomates',
            name: 'tomates',
          ),
        ],
      ),
    ]));

    final rows = await db.select(db.ingredients).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, existing.id);
  });

  test('recria a hierarquia de pastas e liga a receita à pasta certa',
      () async {
    await service.importParsedFile(parsedFullFile(
      folders: const [
        ParsedFolderImport(sourceId: 'src-1', name: 'Massas', position: 0),
        ParsedFolderImport(
          sourceId: 'src-2',
          parentSourceId: 'src-1',
          name: 'Sobremesas',
          position: 1,
        ),
      ],
      recipes: const [
        ParsedRecipeImport(name: 'Pudim', folderSourceId: 'src-2'),
      ],
    ));

    final folders = await folderRepo.watchAll().first;
    expect(folders, hasLength(2));
    final massas = folders.firstWhere((f) => f.name == 'Massas');
    final sobremesas = folders.firstWhere((f) => f.name == 'Sobremesas');
    expect(sobremesas.parentId, massas.id);
    // Ids reais são novos, nunca os do arquivo de origem.
    expect(massas.id, isNot('src-1'));

    final recipe = (await repo.watchAll().first).single;
    expect(recipe.folderId, sobremesas.id);
  });

  test('devolve Err e não cria nada quando o arquivo não tem receita',
      () async {
    final result = await service.importParsedFile(parsedFullFile());

    expect(result, isA<Err<ImportSummary>>());
    expect(await repo.watchAll().first, isEmpty);
  });

  test('recipe sem folderSourceId cai na raiz mesmo com pastas no arquivo',
      () async {
    await service.importParsedFile(parsedFullFile(
      folders: const [
        ParsedFolderImport(sourceId: 'src-1', name: 'Massas'),
      ],
      recipes: const [
        ParsedRecipeImport(name: 'Solta'),
      ],
    ));

    final recipe = (await repo.watchAll().first).single;
    expect(recipe.folderId, isNull);
  });
}
