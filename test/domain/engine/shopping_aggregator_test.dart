import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/shopping_aggregator.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

RecipeIngredient _line({
  required String recipeId,
  String? ingredientId = 'alho',
  String? ingredientName = 'Alho',
  String rawText = '1 dente de alho',
  double? quantity,
  String? unitId,
}) {
  return RecipeIngredient(
    id: '$recipeId-${rawText.hashCode}',
    recipeId: recipeId,
    rawText: rawText,
    position: 0,
    ingredientId: ingredientId,
    ingredientName: ingredientName,
    quantity: quantity,
    unitId: unitId,
  );
}

void main() {
  test('mesma unidade exata soma direto', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', quantity: 2, unitId: 'dente'),
      _line(recipeId: 'r2', quantity: 3, unitId: 'dente'),
    ]);

    expect(result, hasLength(1));
    expect(result.single.quantity, 5);
    expect(result.single.unitCode, 'dente');
    expect(result.single.sourceRecipeIds, ['r1', 'r2']);
  });

  test('500g + 800g vira 1,3kg', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'farinha',
        ingredientName: 'Farinha de trigo',
        quantity: 500,
        unitId: 'g',
      ),
      _line(
        recipeId: 'r2',
        ingredientId: 'farinha',
        ingredientName: 'Farinha de trigo',
        quantity: 800,
        unitId: 'g',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.quantity, closeTo(1.3, 0.0001));
    expect(result.single.unitCode, 'kg');
  });

  test('700ml + 500ml vira 1,2l', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'leite',
        ingredientName: 'Leite',
        quantity: 700,
        unitId: 'ml',
      ),
      _line(
        recipeId: 'r2',
        ingredientId: 'leite',
        ingredientName: 'Leite',
        quantity: 500,
        unitId: 'ml',
      ),
    ]);

    expect(result.single.quantity, closeTo(1.2, 0.0001));
    expect(result.single.unitCode, 'l');
  });

  test('soma cruzando unidade da mesma família sem passar de 1000 não converte', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'farinha',
        quantity: 300,
        unitId: 'g',
      ),
      _line(
        recipeId: 'r2',
        ingredientId: 'farinha',
        quantity: 200,
        unitId: 'g',
      ),
    ]);

    expect(result.single.quantity, 500);
    expect(result.single.unitCode, 'g');
  });

  test('kg soma com g na mesma base', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'acucar', quantity: 1, unitId: 'kg'),
      _line(recipeId: 'r2', ingredientId: 'acucar', quantity: 200, unitId: 'g'),
    ]);

    expect(result.single.quantity, closeTo(1.2, 0.0001));
    expect(result.single.unitCode, 'kg');
  });

  test('unidades incompatíveis do mesmo ingrediente ficam em linhas separadas', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'manteiga',
        quantity: 200,
        unitId: 'g',
      ),
      _line(
        recipeId: 'r2',
        ingredientId: 'manteiga',
        quantity: 2,
        unitId: 'unidade',
      ),
    ]);

    expect(result, hasLength(2));
    final units = result.map((r) => r.unitCode).toSet();
    expect(units, {'g', 'unidade'});
  });

  test('duas unidades de contagem diferentes não se misturam (dente x cabeça)', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'alho', quantity: 2, unitId: 'dente'),
      _line(recipeId: 'r2', ingredientId: 'alho', quantity: 1, unitId: 'cabeca'),
    ]);

    expect(result, hasLength(2));
    expect(result.every((r) => r.sourceRecipeIds.length == 1), isTrue);
  });

  test('ingredientes diferentes nunca se misturam', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'alho', quantity: 2, unitId: 'dente'),
      _line(recipeId: 'r2', ingredientId: 'cebola', quantity: 1, unitId: 'unidade'),
    ]);

    expect(result, hasLength(2));
    expect(result.map((r) => r.ingredientKey).toSet(), {'alho', 'cebola'});
  });

  test('sem quantidade reconhecida vira linha própria sem número', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'sal',
        rawText: 'sal a gosto',
        quantity: null,
        unitId: null,
      ),
    ]);

    expect(result.single.quantity, isNull);
    expect(result.single.sourceRecipeIds, ['r1']);
  });

  test('linha nunca resolvida agrupa pelo rawText normalizado', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: null,
        ingredientName: null,
        rawText: '  Ervas Finas  ',
        quantity: 1,
        unitId: 'unidade',
      ),
      _line(
        recipeId: 'r2',
        ingredientId: null,
        ingredientName: null,
        rawText: 'ervas finas',
        quantity: 1,
        unitId: 'unidade',
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.quantity, 2);
    expect(result.single.unitCode, 'unidade');
  });

  test('lista vazia devolve lista vazia', () {
    expect(aggregateIngredients(const []), isEmpty);
  });
}
