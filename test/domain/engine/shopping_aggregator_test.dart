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
    expect(result.single.sources.map((s) => s.recipeId), ['r1', 'r2']);
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
    // `sources` guarda a quantidade ORIGINAL de cada receita (500g/800g),
    // não a convertida — é o que `ShoppingItemSources` grava (RF-05.8).
    expect(result.single.sources, [
      (recipeId: 'r1', quantity: 500.0, unitId: 'g'),
      (recipeId: 'r2', quantity: 800.0, unitId: 'g'),
    ]);
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

  test('soma cruzando unidade da mesma família sem passar de 1000 não converte',
      () {
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

  test('unidades incompatíveis do mesmo ingrediente ficam em linhas separadas',
      () {
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

  test('duas unidades de contagem diferentes não se misturam (dente x cabeça)',
      () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'alho', quantity: 2, unitId: 'dente'),
      _line(
          recipeId: 'r2', ingredientId: 'alho', quantity: 1, unitId: 'cabeca'),
    ]);

    expect(result, hasLength(2));
    expect(result.every((r) => r.sources.length == 1), isTrue);
  });

  test(
      'a mesma receita repetindo a mesma linha de ingrediente funde numa '
      'única origem (achado em produção: violava a chave única de '
      'shopping_item_sources)', () {
    final result = aggregateIngredients([
      _line(
        recipeId: 'r1',
        ingredientId: 'farinha',
        rawText: '1 xícara de farinha, pra massa',
        quantity: 1,
        unitId: 'xicara',
      ),
      _line(
        recipeId: 'r1',
        ingredientId: 'farinha',
        rawText: '1 xícara de farinha, pra polvilhar',
        quantity: 1,
        unitId: 'xicara',
      ),
    ]);

    expect(result, hasLength(1));
    // 2 xícaras = 480ml — soma as duas linhas antes de virar origem.
    expect(result.single.quantity, closeTo(480, 0.0001));
    expect(result.single.unitCode, 'ml');
    // Uma origem só por receita, mesmo vindo de 2 linhas — senão a
    // inserção em `shopping_item_sources` quebra a PK (item_id, recipe_id).
    expect(result.single.sources, hasLength(1));
    expect(result.single.sources.single.recipeId, 'r1');
    expect(result.single.sources.single.quantity, closeTo(480, 0.0001));
    expect(result.single.sources.single.unitId, 'ml');
  });

  test('ingredientes diferentes nunca se misturam', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'alho', quantity: 2, unitId: 'dente'),
      _line(
          recipeId: 'r2',
          ingredientId: 'cebola',
          quantity: 1,
          unitId: 'unidade'),
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
    expect(result.single.sources.map((s) => s.recipeId), ['r1']);
  });

  test('contagem sem unidade ("3 ovos" + "2 ovos") soma e mantém o número', () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'ovo', quantity: 3, unitId: null),
      _line(recipeId: 'r2', ingredientId: 'ovo', quantity: 2, unitId: null),
      _line(recipeId: 'r2', ingredientId: 'ovo', quantity: 1, unitId: null),
    ]);

    expect(result, hasLength(1));
    expect(result.single.quantity, 6);
    expect(result.single.unitCode, isNull);
    final byRecipe = {
      for (final s in result.single.sources) s.recipeId: s.quantity
    };
    expect(byRecipe, {'r1': 3, 'r2': 3});
  });

  test('contagem sem unidade não mistura com ovo em "unidade" nem em gramas',
      () {
    final result = aggregateIngredients([
      _line(recipeId: 'r1', ingredientId: 'ovo', quantity: 3, unitId: null),
      _line(
          recipeId: 'r2', ingredientId: 'ovo', quantity: 2, unitId: 'unidade'),
    ]);

    expect(result, hasLength(2));
  });

  group('combineQuantities', () {
    test('soma unidades da mesma família e sobe pra kg', () {
      final r = combineQuantities(
        quantityA: 500,
        unitA: 'g',
        quantityB: 0.8,
        unitB: 'kg',
      );
      expect((r?.quantity, r?.unitCode), (1.3, 'kg'));
    });

    test('contagem sem unidade soma; contra unidade real é incompatível', () {
      expect(
        combineQuantities(quantityA: 2, unitA: null, quantityB: 3, unitB: null),
        (quantity: 5.0, unitCode: null),
      );
      expect(
        combineQuantities(quantityA: 2, unitA: null, quantityB: 3, unitB: 'g'),
        isNull,
      );
    });

    test('sem quantidade só combina com outra igual; famílias diferentes não',
        () {
      expect(
        combineQuantities(
            quantityA: null, unitA: null, quantityB: null, unitB: null),
        (quantity: null, unitCode: null),
      );
      expect(
        combineQuantities(
            quantityA: null, unitA: null, quantityB: 1, unitB: 'g'),
        isNull,
      );
      expect(
        combineQuantities(
            quantityA: 1, unitA: 'dente', quantityB: 1, unitB: 'cabeca'),
        isNull,
      );
    });
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
