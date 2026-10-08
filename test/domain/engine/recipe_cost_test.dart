import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

Ingredient _ing(String id, String name, [IngredientPrice? price]) => Ingredient(
      id: id,
      displayName: name,
      normalizedKey: name.toLowerCase(),
      price: price,
    );

RecipeIngredient _line(
  String ingredientId, {
  double? qty,
  String? unit,
  String name = '',
  String raw = '',
}) =>
    RecipeIngredient(
      id: 'l-$ingredientId-${qty ?? 0}-$unit',
      recipeId: 'r',
      rawText: raw.isEmpty ? name : raw,
      position: 0,
      ingredientId: ingredientId,
      ingredientName: name.isEmpty ? null : name,
      quantity: qty,
      unitId: unit,
    );

void main() {
  final catalog = {
    'farinha':
        _ing('farinha', 'Farinha de trigo', const IngredientPrice(600, 'kg')),
    'ovo': _ing('ovo', 'Ovo', const IngredientPrice(100, 'unidade')),
    'leite': _ing('leite', 'Leite', const IngredientPrice(500, 'l')),
    'sal': _ing('sal', 'Sal', const IngredientPrice(300, 'kg')),
    'alho': _ing('alho', 'Alho', const IngredientPrice(4000, 'kg')),
    'caldo': _ing('caldo', 'Caldo'),
    'milho': _ing(
      'milho',
      'Milho',
      const IngredientPrice(450, 'g', 500),
    ),
    'cheiro': _ing(
      'cheiro',
      'Cheiro-verde',
      const IngredientPrice(300, 'maco'),
    ),
    'alho2': _ing(
      'alho2',
      'Alho (cabeça)',
      const IngredientPrice(60, 'dente'),
    ),
  };

  group('costOfRecipe', () {
    test('massa × preço por kg', () {
      final c = costOfRecipe(
        [_line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo')],
        catalog,
      );
      expect(c.totalCents, 300);
      expect(c.complete, isTrue);
    });

    test('volume vira massa pela densidade quando o preço é por kg', () {
      // 2 xícaras de farinha = 480 ml × 0,5 g/ml = 240 g → R$ 1,44
      final c = costOfRecipe(
        [_line('farinha', qty: 2, unit: 'xicara', name: 'Farinha de trigo')],
        catalog,
      );
      expect(c.totalCents, 144);
    });

    test('preço por unidade vale pra "3 ovos" (sem unidade) e "unidade"', () {
      expect(
        costOfRecipe([_line('ovo', qty: 3, name: 'Ovo')], catalog).totalCents,
        300,
      );
      expect(
        costOfRecipe(
                [_line('ovo', qty: 2, unit: 'unidade', name: 'Ovo')], catalog)
            .totalCents,
        200,
      );
    });

    test('preço por litro: volume direto, e massa via densidade', () {
      expect(
        costOfRecipe([_line('leite', qty: 1, unit: 'xicara', name: 'Leite')],
                catalog)
            .totalCents,
        120, // 240 ml × R$ 5,00/L
      );
      // 245 g de leite ÷ 1,0208 g/ml ≈ 240 ml
      expect(
        costOfRecipe(
                [_line('leite', qty: 245, unit: 'g', name: 'Leite')], catalog)
            .totalCents,
        120,
      );
    });

    test('preço de embalagem: "R\$ 4,50 por 500 g"', () {
      final c = costOfRecipe(
        [_line('milho', qty: 250, unit: 'g', name: 'Milho')],
        catalog,
      );
      expect(c.totalCents, 225);
      final kg = costOfRecipe(
        [_line('milho', qty: 1, unit: 'kg', name: 'Milho')],
        catalog,
      );
      expect(kg.totalCents, 900);
    });

    test('preço por contagem casa com a mesma contagem da receita', () {
      expect(
        costOfRecipe(
                [_line('cheiro', qty: 2, unit: 'maco', name: 'Cheiro-verde')],
                catalog)
            .totalCents,
        600,
      );
      expect(
        costOfRecipe(
                [_line('alho2', qty: 3, unit: 'dente', name: 'Alho (cabeça)')],
                catalog)
            .totalCents,
        180,
      );
      // maço na receita, dente no preço: não converte.
      final c = costOfRecipe(
        [_line('alho2', qty: 1, unit: 'maco', name: 'Alho (cabeça)')],
        catalog,
      );
      expect(c.gaps.single.gap, CostGap.cannotConvert);
    });

    test('suggestedPriceUnit', () {
      expect(suggestedPriceUnit('g'), 'kg');
      expect(suggestedPriceUnit('xicara'), 'l');
      expect(suggestedPriceUnit('dente'), 'dente');
      expect(suggestedPriceUnit(null), 'unidade');
      expect(suggestedPriceUnit('a_gosto'), 'unidade');
    });

    test('isPriceUnit', () {
      expect(isPriceUnit('kg'), isTrue);
      expect(isPriceUnit('maco'), isTrue);
      expect(isPriceUnit('a_gosto'), isFalse);
      expect(isPriceUnit('nada'), isFalse);
    });

    test('o fator das porções escala a conta', () {
      final c = costOfRecipe(
        [_line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo')],
        catalog,
        factor: 2,
      );
      expect(c.totalCents, 600);
    });

    test('"a gosto" não entra nem conta como lacuna', () {
      final c = costOfRecipe(
        [
          _line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo'),
          _line('sal', qty: 1, unit: 'a_gosto', name: 'Sal'),
        ],
        catalog,
      );
      expect(c.totalCents, 300);
      expect(c.gaps, isEmpty);
      expect(c.complete, isTrue);
    });

    test('sem preço e sem conversão viram lacunas, fora da soma', () {
      final c = costOfRecipe(
        [
          _line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo'),
          _line('caldo', qty: 1, unit: 'xicara', name: 'Caldo'),
          _line('alho', qty: 2, unit: 'dente', name: 'Alho'),
        ],
        catalog,
      );
      expect(c.totalCents, 300);
      expect(c.complete, isFalse);
      expect(
        {for (final g in c.gaps) g.name: g.gap},
        {'Caldo': CostGap.noPrice, 'Alho': CostGap.cannotConvert},
      );
    });

    test('linha sem ingrediente ligado conta como sem preço', () {
      final c = costOfRecipe(
        [
          const RecipeIngredient(
            id: 'x',
            recipeId: 'r',
            rawText: 'um pouco de nada',
            position: 0,
            quantity: 1,
          ),
        ],
        catalog,
      );
      expect(c.isEmpty, isTrue);
      expect(c.gaps.single.gap, CostGap.noPrice);
    });

    test('custo por porção', () {
      final c = costOfRecipe(
        [_line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo')],
        catalog,
      );
      expect(c.perServing(4), 75);
      expect(c.perServing(null), isNull);
      expect(c.perServing(0), isNull);
    });
  });

  group('costOfPlan', () {
    test('soma, agrupa por receita e ordena do mais caro', () {
      final bolo = PlannedRecipe(
        recipeId: 'bolo',
        name: 'Bolo',
        lines: [
          _line('farinha', qty: 500, unit: 'g', name: 'Farinha de trigo'),
          _line('ovo', qty: 3, name: 'Ovo'),
        ],
      );
      final omelete = PlannedRecipe(
        recipeId: 'omelete',
        name: 'Omelete',
        lines: [
          _line('ovo', qty: 2, name: 'Ovo'),
          _line('caldo', qty: 1, name: 'Caldo'),
        ],
      );
      final plan = costOfPlan([bolo, omelete, bolo], catalog);

      expect(plan.totalCents, (300 + 300) * 2 + 200);
      expect(plan.recipes.first.recipeId, 'bolo');
      expect(plan.recipes.first.times, 2);
      expect(plan.recipes.first.cents, 1200);
      expect(plan.ingredients.first.name, 'Ovo');
      expect(plan.ingredients.first.cents, 3 * 100 * 2 + 200);
      expect(plan.missingNames, ['Caldo']);
    });

    test('receita com preço faltando não entra no ranking de mais cara', () {
      // "Festa" tem o maior valor parcial, mas falta o preço do caldo.
      final festa = PlannedRecipe(
        recipeId: 'festa',
        name: 'Festa',
        lines: [
          _line('farinha', qty: 2, unit: 'kg', name: 'Farinha de trigo'),
          _line('caldo', qty: 1, name: 'Caldo'),
        ],
      );
      final omelete = PlannedRecipe(
        recipeId: 'omelete',
        name: 'Omelete',
        lines: [_line('ovo', qty: 2, name: 'Ovo')],
      );
      final plan = costOfPlan([festa, omelete], catalog);

      expect(plan.recipes.first.recipeId, 'festa');
      expect(plan.recipes.first.complete, isFalse);
      expect(plan.rankable.map((r) => r.recipeId), ['omelete']);
      expect(plan.unrankedCount, 1);
      // O que ela gastou nos ingredientes COM preço ainda conta no total.
      expect(plan.totalCents, 1200 + 200);
    });

    test('planejamento sem preço nenhum fica vazio', () {
      final plan = costOfPlan(
        [
          PlannedRecipe(
            recipeId: 'a',
            name: 'A',
            lines: [_line('caldo', qty: 1, name: 'Caldo')],
          ),
        ],
        catalog,
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.missingNames, ['Caldo']);
    });
  });

  group('dinheiro', () {
    test('formatMoney', () {
      expect(formatMoney(0), 'R\$ 0,00');
      expect(formatMoney(5), 'R\$ 0,05');
      expect(formatMoney(2340), 'R\$ 23,40');
      expect(formatMoney(123456), 'R\$ 1.234,56');
    });

    test('parseMoneyToCents', () {
      expect(parseMoneyToCents('8,50'), 850);
      expect(parseMoneyToCents('8.50'), 850);
      expect(parseMoneyToCents('R\$ 8,50'), 850);
      expect(parseMoneyToCents('1.250,90'), 125090);
      expect(parseMoneyToCents('1.250'), 125000);
      expect(parseMoneyToCents('12'), 1200);
      expect(parseMoneyToCents('0'), isNull);
      expect(parseMoneyToCents('abc'), isNull);
      expect(parseMoneyToCents(''), isNull);
    });
  });
}
