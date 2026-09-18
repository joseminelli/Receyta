import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/ingredient_format.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';

void main() {
  RecipeIngredient buildIngredient({
    required String rawText,
    double? quantity,
    String? unitId,
    String? qualifier,
    String? ingredientName,
  }) {
    return RecipeIngredient(
      id: 'i1',
      recipeId: 'r1',
      rawText: rawText,
      position: 0,
      quantity: quantity,
      unitId: unitId,
      qualifier: qualifier,
      ingredientName: ingredientName,
    );
  }

  group('unitDisplayLabel', () {
    test('singular quando quantidade é 1', () {
      expect(unitDisplayLabel('xicara_cha', 1), 'xícara de chá');
    });

    test('plural quando quantidade é diferente de 1', () {
      expect(unitDisplayLabel('xicara_cha', 2), 'xícaras de chá');
    });

    test('null quando o código não bate com nenhuma unidade', () {
      expect(unitDisplayLabel('nao-existe', 1), isNull);
    });

    test('null quando o código é null', () {
      expect(unitDisplayLabel(null, 1), isNull);
    });
  });

  group('formatIngredientLine', () {
    test('sem quantidade reconhecida, devolve o rawText cru', () {
      final i = buildIngredient(rawText: 'sal a gosto');
      expect(formatIngredientLine(i), 'sal a gosto');
    });

    test('com quantidade e unidade, monta "qtd unidade de nome"', () {
      final i = buildIngredient(
        rawText: '500g de farinha de trigo, peneirada',
        quantity: 500,
        unitId: 'g',
        qualifier: 'peneirada',
        ingredientName: 'Farinha de Trigo',
      );
      expect(
        formatIngredientLine(i),
        '500 g de Farinha de Trigo, peneirada',
      );
    });

    test('quantidade fracionária vira decimal com vírgula', () {
      final i = buildIngredient(
        rawText: '1 1/2 xícara de chá de leite',
        quantity: 1.5,
        unitId: 'xicara_cha',
        ingredientName: 'Leite',
      );
      expect(formatIngredientLine(i), '1,5 xícaras de chá de Leite');
    });
  });
}
