import 'package:flutter_test/flutter_test.dart';

import 'package:receyta/domain/engine/serving_scale.dart';

void main() {
  group('servingFactor', () {
    test('dobrar as porções dobra o fator', () {
      expect(servingFactor(base: 4, chosen: 8), 2);
      expect(servingFactor(base: 4, chosen: 2), 0.5);
    });

    test('sem rendimento na receita ou sem escolha, não escala', () {
      expect(servingFactor(base: null, chosen: 8), 1);
      expect(servingFactor(base: 0, chosen: 8), 1);
      expect(servingFactor(base: 4, chosen: null), 1);
    });
  });

  group('clampServings', () {
    test('igual ao rendimento original volta a "sem escala"', () {
      expect(clampServings(4, base: 4), isNull);
    });

    test('respeita o mínimo e o máximo', () {
      expect(clampServings(0, base: 4), kMinServings);
      expect(clampServings(500, base: 4), kMaxServings);
    });
  });

  group('niceQuantity (modo cozinha)', () {
    test('de 100 pra cima, de 5 em 5', () {
      expect(niceQuantity(833.33), 835);
      expect(niceQuantity(750), 750);
      expect(niceQuantity(101.9), 100);
    });

    test('de 10 a 100, inteira', () {
      expect(niceQuantity(37.5), 38);
      expect(niceQuantity(10.2), 10);
    });

    test('abaixo de 10, em quartos', () {
      expect(niceQuantity(2.3333), 2.25);
      expect(niceQuantity(1.5), 1.5);
      expect(niceQuantity(0.375), 0.5);
    });

    test('nunca zera uma quantidade pequena', () {
      expect(niceQuantity(0.05), 0.25);
    });
  });

  group('roundUpForShopping', () {
    test('contáveis e g/ml sobem pro inteiro', () {
      expect(roundUpForShopping(4.5), 5);
      expect(roundUpForShopping(1.2, unitId: 'g'), 2);
      expect(roundUpForShopping(0.1), 1);
    });

    test('número já inteiro não sobe (sem erro de ponto flutuante)', () {
      expect(roundUpForShopping(3), 3);
      expect(roundUpForShopping(3.0000000001), 3);
      expect(roundUpForShopping(1.5 * 2), 3);
    });

    test('kg e litro sobem de meio em meio', () {
      expect(roundUpForShopping(1.125, unitId: 'kg'), 1.5);
      expect(roundUpForShopping(0.75, unitId: 'l'), 1);
      expect(roundUpForShopping(2, unitId: 'kg'), 2);
      expect(roundUpForShopping(0.1, unitId: 'kg'), 0.5);
    });
  });
}
