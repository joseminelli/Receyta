import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';

void main() {
  late AppDatabase db;
  late FolderRepository repo;
  late RecipeRepository recipes;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FolderRepository(db.folderDao, db.recipeDao,
        clock: () => DateTime.utc(2026));
    recipes = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => DateTime.utc(2026));
  });
  tearDown(() => db.close());

  Future<String> mkFolder(String name, {String? parent}) async {
    final r = await repo.create(name: name, parentId: parent) as Ok<Folder>;
    return r.value.id;
  }

  Future<String> mkRecipe(String name, {String? folder}) async {
    final r = await recipes.saveDetail(name: name) as Ok<Recipe>;
    if (folder != null) await repo.moveRecipe(r.value.id, folder);
    return r.value.id;
  }

  test('cria pasta e conta receitas diretas e subpastas', () async {
    final doces = await mkFolder('Doces');
    await mkFolder('Bolos', parent: doces);
    await mkRecipe('Brigadeiro', folder: doces);
    await mkRecipe('Beijinho', folder: doces);

    final roots = await repo.watchChildrenWithCounts(null).first;
    expect(roots.map((f) => f.folder.name), ['Doces']);
    expect(roots.single.recipeCount, 2);
    expect(roots.single.subfolders, 1);
  });

  test('nome vazio é rejeitado', () async {
    expect(await repo.create(name: '   '), isA<Err<Folder>>());
  });

  test('renomear troca o nome', () async {
    final id = await mkFolder('Salgados');
    await repo.rename(id, 'Salgadinhos');
    expect((await repo.watchFolder(id).first)!.name, 'Salgadinhos');
  });

  test('excluir sobe subpastas e receitas pro pai', () async {
    final root = await mkFolder('Cozinha');
    final mid = await mkFolder('Massas', parent: root);
    final leaf = await mkFolder('Recheadas', parent: mid);
    final recipeId = await mkRecipe('Canelone', folder: mid);

    await repo.delete(mid);

    expect(await repo.watchFolder(mid).first, isNull);
    expect((await repo.watchFolder(leaf).first)!.parentId, root);
    final moved = (await recipes.getById(recipeId) as Ok<Recipe>).value;
    expect(moved.folderId, root);
  });

  test('excluir pasta de raiz manda o conteúdo pra raiz', () async {
    final root = await mkFolder('Temp');
    final recipeId = await mkRecipe('Solta', folder: root);

    await repo.delete(root);

    final moved = (await recipes.getById(recipeId) as Ok<Recipe>).value;
    expect(moved.folderId, isNull);
  });

  test('mover pra dentro de descendente é recusado', () async {
    final a = await mkFolder('A');
    final b = await mkFolder('B', parent: a);

    final result = await repo.move(a, b);
    expect(result, isA<Err<void>>());
    expect((await repo.watchFolder(a).first)!.parentId, isNull);
  });

  test('mover pasta pra outra pasta funciona', () async {
    final a = await mkFolder('A');
    final b = await mkFolder('B');

    expect(await repo.move(a, b), isA<Ok<void>>());
    expect((await repo.watchFolder(a).first)!.parentId, b);
  });

  test('receita sem pasta fica na raiz (folderId nulo)', () async {
    final id = await mkRecipe('Livre');
    final r = (await recipes.getById(id) as Ok<Recipe>).value;
    expect(r.folderId, isNull);

    expect(await recipes.watchInFolder(null).first, isNotEmpty);
  });
}
