import 'package:receyta/data/services/recipe_image_service.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    expect(
      (result as Ok<ImportSummary>).value,
      (recipes: 1, folders: 0, skipped: 0),
    );

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

  group('reconciliação de pasta por nome+pai (D4)', () {
    test('reimportar as mesmas pastas não duplica a árvore', () async {
      final file = parsedFullFile(
        folders: const [
          ParsedFolderImport(sourceId: 'a', name: 'Massas'),
          ParsedFolderImport(sourceId: 'b', parentSourceId: 'a', name: 'Doces'),
        ],
      );
      await service.importParsedFile(file);
      // Sourceids diferentes de propósito — simula reimportar um arquivo
      // gerado por outra exportação, não byte-a-byte o mesmo.
      await service.importParsedFile(parsedFullFile(
        folders: const [
          ParsedFolderImport(sourceId: 'x', name: 'Massas'),
          ParsedFolderImport(sourceId: 'y', parentSourceId: 'x', name: 'Doces'),
        ],
      ));

      final folders = await folderRepo.watchAll().first;
      expect(folders, hasLength(2));
    });

    test('mesmo nome em pai diferente não reconcilia — são pastas distintas',
        () async {
      await service.importParsedFile(parsedFullFile(folders: const [
        ParsedFolderImport(sourceId: 'a', name: 'Raiz1'),
        ParsedFolderImport(sourceId: 'b', name: 'Raiz2'),
        ParsedFolderImport(sourceId: 'c', parentSourceId: 'a', name: 'Sub'),
        ParsedFolderImport(sourceId: 'd', parentSourceId: 'b', name: 'Sub'),
      ]));

      final folders = await folderRepo.watchAll().first;
      expect(folders.where((f) => f.name == 'Sub'), hasLength(2));
    });
  });

  group('conflito de receita (D4, RF-06.3)', () {
    test('findConflicts acha receita cujo id de origem já existe', () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo'),
      ]));

      final conflicts = await service.findConflicts(parsedFullFile(recipes: [
        const ParsedRecipeImport(sourceId: 'r1', name: 'Bolo v2'),
        const ParsedRecipeImport(sourceId: 'r2', name: 'Torta'),
      ]));

      expect(conflicts, ['Bolo v2']);
    });

    test('sem conflito, a receita nasce com o id de origem', () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo'),
      ]));

      final recipe = (await repo.watchAll().first).single;
      expect(recipe.id, 'r1');
    });

    test('resolution.duplicate cria uma segunda receita com id novo', () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'original'),
      ]));

      final result = await service.importParsedFile(
        parsedFullFile(recipes: const [
          ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'novo'),
        ]),
        resolution: ConflictResolution.duplicate,
      );

      expect((result as Ok<ImportSummary>).value.recipes, 1);
      final all = await repo.watchAll().first;
      expect(all, hasLength(2));
      expect(all.map((r) => r.id).toSet(), hasLength(2));
      final notes = all.map((r) => r.notes).toSet();
      expect(notes, {'original', 'novo'});
    });

    test('resolution.replace sobrescreve a receita existente (mesmo id)',
        () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'original'),
      ]));

      await service.importParsedFile(
        parsedFullFile(recipes: const [
          ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'novo'),
        ]),
        resolution: ConflictResolution.replace,
      );

      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.id, 'r1');
      expect(all.single.notes, 'novo');
    });

    test('resolution.skip não toca na receita existente', () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'original'),
      ]));

      final result = await service.importParsedFile(
        parsedFullFile(recipes: const [
          ParsedRecipeImport(sourceId: 'r1', name: 'Bolo', notes: 'novo'),
        ]),
        resolution: ConflictResolution.skip,
      );

      expect(
        (result as Ok<ImportSummary>).value,
        (recipes: 0, folders: 0, skipped: 1),
      );
      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.notes, 'original');
    });

    test('lote misto: só a receita em conflito é pulada, o resto importa',
        () async {
      await service.importParsedFile(parsedFullFile(recipes: const [
        ParsedRecipeImport(sourceId: 'r1', name: 'Bolo'),
      ]));

      final result = await service.importParsedFile(
        parsedFullFile(recipes: const [
          ParsedRecipeImport(sourceId: 'r1', name: 'Bolo'),
          ParsedRecipeImport(sourceId: 'r2', name: 'Torta'),
        ]),
        resolution: ConflictResolution.skip,
      );

      expect(
        (result as Ok<ImportSummary>).value,
        (recipes: 1, folders: 0, skipped: 1),
      );
      final names = (await repo.watchAll().first).map((r) => r.name).toSet();
      expect(names, {'Bolo', 'Torta'});
    });
  });

  group('parseFileAtPath', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('receyta_import_test');
    });
    tearDown(() => tempDir.delete(recursive: true));

    Future<String> writeFile(String name, Object content) async {
      final file = File('${tempDir.path}/$name');
      await file.writeAsString(jsonEncode(content));
      return file.path;
    }

    test('lê e parseia um .receyta válido do disco', () async {
      final path = await writeFile('receita.receyta', {
        'schemaVersion': 1,
        'kind': 'recipes',
        'recipes': [
          {'name': 'Bolo'},
        ],
      });

      final result = await service.parseFileAtPath(path);

      expect(result, isA<Ok<ParsedReceytaFile>>());
      expect(
          (result as Ok<ParsedReceytaFile>).value.recipes.single.name, 'Bolo');
    });

    test('arquivo sem receita nenhuma devolve Err', () async {
      final path = await writeFile('vazio.receyta', {
        'schemaVersion': 1,
        'kind': 'recipes',
        'recipes': [],
      });

      final result = await service.parseFileAtPath(path);

      expect(result, isA<Err<ParsedReceytaFile>>());
    });

    test('conteúdo que não é um .receyta válido devolve Err', () async {
      final path = await writeFile('lixo.receyta', {'oi': 'tudo bem'});

      final result = await service.parseFileAtPath(path);

      expect(result, isA<Err<ParsedReceytaFile>>());
    });

    test('caminho inexistente devolve Err', () async {
      final result =
          await service.parseFileAtPath('${tempDir.path}/nao-existe.receyta');

      expect(result, isA<Err<ParsedReceytaFile>>());
    });
  });

  group('foto no backup', () {
    late Directory root;
    late RecipeImageService images;
    late ReceytaImportService withImages;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('receyta_backup_photo');
      images = RecipeImageService(
        baseDir: () async => Directory('${root.path}/imgs'),
        compress: (src, dst, {required maxSide, required quality}) =>
            File(src).copy(dst),
      );
      withImages = ReceytaImportService(
        db.recipeDao,
        db.folderDao,
        db.ingredientDao,
        db.tagDao,
        images: images,
      );
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    ParsedRecipeImport recipe({
      String? image,
      String? id,
      String? imageName,
    }) =>
        ParsedRecipeImport(
          sourceId: id,
          name: 'Bolo',
          imageBase64: image,
          imageName: imageName,
        );

    test('restaura a foto do arquivo na pasta do app', () async {
      final photo = base64Encode([1, 2, 3, 4]);
      await withImages.importParsedFile(
        parsedFullFile(recipes: [recipe(image: photo)]),
      );

      final row = (await db.recipeDao.watchActive().first).single;
      expect(row.imagePath, isNotNull);
      final file = await images.fileFor(row.imagePath!);
      expect(await file.readAsBytes(), [1, 2, 3, 4]);
    });

    test(
        'arquivo sem foto, ou com foto corrompida, importa a receita assim mesmo',
        () async {
      await withImages.importParsedFile(parsedFullFile(recipes: [
        recipe(),
        recipe(image: '@@@não é base64@@@'),
      ]));

      final rows = await db.recipeDao.watchActive().first;
      expect(rows, hasLength(2));
      expect(rows.every((r) => r.imagePath == null), isTrue);
    });

    test('substituir sem foto no arquivo mantém a foto que já existia',
        () async {
      await withImages.importParsedFile(parsedFullFile(
        recipes: [
          recipe(id: 'r1', image: base64Encode([9, 9]))
        ],
      ));
      final before = (await db.recipeDao.findById('r1'))!.imagePath;

      await withImages.importParsedFile(
        parsedFullFile(recipes: [recipe(id: 'r1')]),
        resolution: ConflictResolution.replace,
      );

      expect((await db.recipeDao.findById('r1'))!.imagePath, before);
    });

    test('substituir com foto nova troca a foto e mantém o registro de envio',
        () async {
      await withImages.importParsedFile(parsedFullFile(
        recipes: [
          recipe(id: 'r1', image: base64Encode([9, 9]))
        ],
      ));
      await db.recipeDao.setImageSynced(
        'r1',
        (await db.recipeDao.findById('r1'))!.imagePath,
      );
      final old = (await db.recipeDao.findById('r1'))!.imagePath;
      await Future<void>.delayed(const Duration(milliseconds: 3));

      await withImages.importParsedFile(
        parsedFullFile(recipes: [
          recipe(id: 'r1', image: base64Encode([7, 7]))
        ]),
        resolution: ConflictResolution.replace,
      );

      final row = (await db.recipeDao.findById('r1'))!;
      expect(row.imagePath, isNot(old));
      expect(row.imageSyncedPath, old);
    });

    test('restaura com o MESMO nome do arquivo original', () async {
      await withImages.importParsedFile(parsedFullFile(recipes: [
        recipe(image: base64Encode([1, 2, 3]), imageName: 'original_17.jpg'),
      ]));

      final row = (await db.recipeDao.watchActive().first).single;
      expect(row.imagePath, 'original_17.jpg');
      expect(await (await images.fileFor('original_17.jpg')).readAsBytes(),
          [1, 2, 3]);
    });

    test('duas receitas do backup com a mesma foto viram um arquivo só',
        () async {
      final photo = base64Encode([4, 4, 4]);
      await withImages.importParsedFile(parsedFullFile(recipes: [
        recipe(image: photo, imageName: 'mesma.jpg'),
        recipe(image: photo, imageName: 'mesma.jpg'),
      ]));

      final rows = await db.recipeDao.watchActive().first;
      expect(rows.map((r) => r.imagePath).toSet(), {'mesma.jpg'});
      final dir = await images.directory();
      expect(await dir.list().length, 1);
    });

    test('nome do arquivo malicioso é ignorado e a foto vai pra um nome seguro',
        () async {
      await withImages.importParsedFile(parsedFullFile(recipes: [
        recipe(image: base64Encode([7, 7]), imageName: '../../fora.jpg'),
      ]));

      final row = (await db.recipeDao.watchActive().first).single;
      expect(row.imagePath, isNot(contains('..')));
      expect(row.imagePath, matches(RegExp(r'^[0-9a-f]{40}\.jpg$')));
      expect(await File('${root.path}/fora.jpg').exists(), isFalse);
    });

    test('arquivo local que já existe com esse nome não é regravado', () async {
      await images.storeBytes(Uint8List.fromList([1]),
          name: 'ja_existe.jpg', compress: false);

      await withImages.importParsedFile(parsedFullFile(recipes: [
        recipe(image: base64Encode([9, 9]), imageName: 'ja_existe.jpg'),
      ]));

      expect(await (await images.fileFor('ja_existe.jpg')).readAsBytes(), [1]);
    });
  });
}
