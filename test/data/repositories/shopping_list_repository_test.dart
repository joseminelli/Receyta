import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/shopping_list.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository recipeRepo;
  late ShoppingListRepository shoppingRepo;
  late DateTime clock;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clock = DateTime.utc(2026, 1, 1, 12);
    recipeRepo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => clock);
    shoppingRepo = ShoppingListRepository(
      db.shoppingListDao,
      db.recipeDao,
      db.ingredientDao,
      clock: () => clock,
    );
  });

  tearDown(() => db.close());

  Recipe unwrapRecipe(Result<Recipe> r) => (r as Ok<Recipe>).value;
  ShoppingList unwrapList(Result<ShoppingList> r) => (r as Ok<ShoppingList>).value;

  test('lista sai correta a partir de 6 receitas', () async {
    // Farinha aparece em 3 receitas com unidades convertíveis (soma pra
    // kg); alho aparece em 2 com "dente" (soma direto); as outras 3
    // receitas contribuem ingredientes que não se repetem.
    final r1 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Pão',
      ingredientLines: ['500g de farinha de trigo', '2 dentes de alho'],
    ));
    final r2 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['300g de farinha de trigo', '3 ovos'],
    ));
    final r3 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Massa',
      ingredientLines: ['0,5kg de farinha de trigo'],
    ));
    final r4 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Molho',
      ingredientLines: ['1 dente de alho', '400g de tomate'],
    ));
    final r5 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Salada',
      ingredientLines: ['1 cabeça de alface'],
    ));
    final r6 = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Suco',
      ingredientLines: ['500ml de água'],
    ));

    final list = unwrapList(await shoppingRepo.generateFromRecipes(
      [r1.id, r2.id, r3.id, r4.id, r5.id, r6.id],
    ));

    expect(list.name, isNotEmpty);
    expect(list.createdAt, clock);

    final items = await shoppingRepo.itemsOf(list.id);

    // Farinha: 500g + 300g + 500g (0,5kg) = 1300g = 1,3kg, numa linha só.
    final farinha = items.singleWhere((i) => i.displayName.contains('Farinha'));
    expect(farinha.quantity, closeTo(1.3, 0.0001));
    expect(farinha.unitId, 'kg');
    expect(farinha.sources, hasLength(3));
    expect(
      farinha.sources.map((s) => s.recipeId).toSet(),
      {r1.id, r2.id, r3.id},
    );

    // Alho: 2 dentes + 1 dente = 3 dentes, numa linha só.
    final alho = items.singleWhere((i) => i.displayName.contains('Alho'));
    expect(alho.quantity, 3);
    expect(alho.unitId, 'dente');
    expect(alho.sources, hasLength(2));

    // Ingredientes que só aparecem uma vez continuam presentes, cada um
    // com sua própria linha.
    final singleUseNames = items
        .where((i) =>
            i.displayName.contains('Ovo') ||
            i.displayName.contains('Tomate') ||
            i.displayName.contains('Alface') ||
            i.displayName.contains('Água'))
        .map((i) => i.displayName)
        .toSet();
    expect(singleUseNames.length, 4);

    // Total de linhas: farinha + alho + ovo + tomate + alface + água = 6.
    expect(items, hasLength(6));
  });

  test(
      '"meia xícara" e "2 e meia xícara" por extenso somam certo '
      '(achado pelo usuário gerando lista de verdade)', () async {
    final a = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Panqueca',
      ingredientLines: ['meia xícara de farinha'],
    ));
    final b = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['2 e meia xícara de farinha'],
    ));

    final list =
        unwrapList(await shoppingRepo.generateFromRecipes([a.id, b.id]));
    final items = await shoppingRepo.itemsOf(list.id);

    // 0,5 + 2,5 = 3 xícaras = 720ml (abaixo de 1000, não sobe pra litro).
    expect(items, hasLength(1));
    expect(items.single.quantity, closeTo(720, 0.0001));
    expect(items.single.unitId, 'ml');
  });

  test(
      'receita com o mesmo ingrediente em 2 linhas não quebra a PK '
      'composta de shopping_item_sources (achado em produção)', () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Pão caseiro',
      ingredientLines: [
        '1 xícara de farinha',
        '1 xícara de farinha', // pra polvilhar — mesma receita, linha repetida
      ],
    ));

    // Não deve lançar `SqliteException` de UNIQUE constraint.
    final list = unwrapList(
      await shoppingRepo.generateFromRecipes([recipe.id]),
    );
    final items = await shoppingRepo.itemsOf(list.id);

    expect(items, hasLength(1));
    expect(items.single.quantity, closeTo(480, 0.0001)); // 2 xícaras = 480ml
    expect(items.single.sources, hasLength(1));
    expect(items.single.sources.single.recipeId, recipe.id);
  });

  test('recusa lista sem receita nenhuma', () async {
    final result = await shoppingRepo.generateFromRecipes(const []);
    expect(result, isA<Err<ShoppingList>>());
  });

  test('recusa quando nenhuma receita selecionada tem ingrediente', () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(name: 'Vazia'));
    final result = await shoppingRepo.generateFromRecipes([recipe.id]);
    expect(result, isA<Err<ShoppingList>>());
  });

  test('nome customizado é respeitado; sem nome cai no padrão com a data',
      () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Café',
      ingredientLines: ['200g de pó de café'],
    ));

    final named = unwrapList(await shoppingRepo.generateFromRecipes(
      [recipe.id],
      name: 'Compras da semana',
    ));
    expect(named.name, 'Compras da semana');

    final unnamed =
        unwrapList(await shoppingRepo.generateFromRecipes([recipe.id]));
    expect(unnamed.name, contains('01/01'));
  });

  test('itens vêm com o corredor; avulso digitado entra no fim, parseado',
      () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['300g de farinha de trigo', '2 tomates'],
    ));
    final list =
        unwrapList(await shoppingRepo.generateFromRecipes([recipe.id]));

    final added = await shoppingRepo.addManualItem(list.id, '2 caixas de leite');
    expect(added, isA<Ok<void>>());

    final items = await shoppingRepo.itemsOf(list.id);
    expect(items, hasLength(3));
    final bySlug = {for (final i in items) i.displayName: i.categorySlug};
    expect(bySlug['Farinha de Trigo'], 'mercearia');
    expect(bySlug['Tomates'], 'hortifruti');

    final manual = items.last;
    expect(manual.displayName, 'Leite');
    expect(manual.quantity, 2);
    expect(manual.categorySlug, 'frios_laticinios');
    expect(manual.sources, isEmpty);
    expect(manual.position, 2);
  });

  test('clearChecked apaga só os marcados e diz quantos', () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['1 ovo', '300g de farinha de trigo', '2 tomates'],
    ));
    final list =
        unwrapList(await shoppingRepo.generateFromRecipes([recipe.id]));
    final items = await shoppingRepo.itemsOf(list.id);
    await shoppingRepo.setChecked(items[0].id, true);
    await shoppingRepo.setChecked(items[1].id, true);

    final result = await shoppingRepo.clearChecked(list.id);
    expect((result as Ok<int>).value, 2);

    final left = await shoppingRepo.itemsOf(list.id);
    expect(left.single.id, items[2].id);
  });

  test('avulso vazio é recusado', () async {
    final recipe = unwrapRecipe(await recipeRepo.saveDetail(
      name: 'Bolo',
      ingredientLines: ['1 ovo'],
    ));
    final list =
        unwrapList(await shoppingRepo.generateFromRecipes([recipe.id]));
    expect(await shoppingRepo.addManualItem(list.id, '  '), isA<Err<void>>());
  });
}
