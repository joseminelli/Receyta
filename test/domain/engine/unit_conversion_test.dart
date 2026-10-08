import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/unit_conversion.dart';

String? eq(double qty, String? unit, String name) =>
    equivalentMeasure(quantity: qty, unitId: unit, name: name);

void main() {
  group('equivalentMeasure', () {
    test('volume com densidade vira gramas', () {
      expect(eq(2, 'xicara', 'Farinha de trigo'), '≈ 240 g');
      expect(eq(1, 'colher_sopa', 'Manteiga'), '≈ 14 g');
      expect(eq(1, 'xicara', 'Leite condensado'), '≈ 300 g');
    });

    test('a entrada mais específica vence', () {
      expect(eq(1, 'xicara', 'leite'), '≈ 245 g');
      expect(eq(1, 'xicara', 'creme de leite'), '≈ 240 g');
    });

    test('gramas viram xícara/colher em frações de cozinha', () {
      expect(eq(200, 'g', 'Açúcar'), '≈ 1 xícara');
      expect(eq(100, 'g', 'Farinha de trigo'), '≈ ¾ xícara');
      expect(eq(1000, 'g', 'Farinha de trigo'), '≈ 8 ⅓ xícaras');
      expect(eq(14, 'g', 'Manteiga'), '≈ 1 colher de sopa');
    });

    test('medida de cozinha sem densidade vira ml', () {
      expect(eq(1, 'xicara', 'Chá de hibisco'), '≈ 240 ml');
      expect(eq(2, 'colher_sopa', 'Chá de hibisco'), '≈ 30 ml');
    });

    test('sem equivalência útil devolve null', () {
      expect(eq(500, 'ml', 'Caldo'), isNull);
      expect(eq(500, 'g', 'Caldo'), isNull);
      expect(eq(3, 'unidade', 'Ovo'), isNull);
      expect(eq(1, 'a_gosto', 'Sal'), isNull);
      expect(eq(1, null, 'Sal'), isNull);
      expect(eq(1, 'xicara', 'Arroz cozido'), isNull);
    });
  });

  group('annotateTemperatures', () {
    test('Celsius ganha Fahrenheit', () {
      expect(annotateTemperatures('Asse a 180°C por 30 minutos'),
          'Asse a 180°C (≈ 355 °F) por 30 minutos');
      expect(annotateTemperatures('forno a 180ºC'), 'forno a 180ºC (≈ 355 °F)');
      expect(annotateTemperatures('180 graus'), '180 graus (≈ 355 °F)');
    });

    test('Fahrenheit ganha Celsius', () {
      expect(annotateTemperatures('350 °F'), '350 °F (≈ 175 °C)');
      expect(annotateTemperatures('350°'), '350° (≈ 175 °C)');
    });

    test('faixa converte as duas pontas', () {
      expect(annotateTemperatures('180-200°C'), '180-200°C (≈ 355–390 °F)');
    });

    test('não mexe em ordinal nem em conversão que já está escrita', () {
      expect(annotateTemperatures('1º passo'), '1º passo');
      expect(annotateTemperatures('180°C (350°F)'), '180°C (350°F)');
      expect(annotateTemperatures('10º dia'), '10º dia');
    });
  });
}
