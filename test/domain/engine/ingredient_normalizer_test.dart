import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/ingredient_normalizer.dart';

void main() {
  test('minúsculas, remove acento e pontuação', () {
    expect(normalize('Farinha de Trigo!'), 'farinha trigo');
  });

  test('"tomates" e "tomate" viram a mesma chave', () {
    expect(normalize('tomates'), normalize('tomate'));
  });

  test('remove qualificador de uma palavra', () {
    expect(normalize('alho picado'), 'alho');
  });

  test('remove qualificador de duas palavras', () {
    expect(normalize('sal a gosto'), 'sal');
  });

  test('singulariza plural em -ões', () {
    expect(normalize('limões'), 'limao');
  });

  test('singulariza plural em -res', () {
    expect(normalize('colheres'), 'colher');
  });

  test('ignora espaços extras nas pontas e no meio', () {
    expect(normalize('  farinha   de   trigo  '), 'farinha trigo');
  });
}
