import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';

void main() {
  test('quantidade inteira + unidade plural + nome composto', () {
    final r = parseIngredientLine('2 xícaras de farinha de trigo');
    expect(r.quantity, 2);
    expect(r.unitCode, 'xicara');
    expect(r.qualifier, isNull);
    expect(r.name, 'farinha de trigo');
  });

  test('fração ascii', () {
    final r = parseIngredientLine('1/2 colher de chá de sal');
    expect(r.quantity, 0.5);
    expect(r.unitCode, 'colher_cha');
    expect(r.name, 'sal');
  });

  test('fração unicode', () {
    final r = parseIngredientLine('½ limão');
    expect(r.quantity, 0.5);
    expect(r.unitCode, isNull);
    expect(r.name, 'limão');
  });

  test('número misto com fração unicode', () {
    final r = parseIngredientLine('1 ½ xícara de açúcar');
    expect(r.quantity, 1.5);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'açúcar');
  });

  test('decimal com vírgula', () {
    final r = parseIngredientLine('1,5 kg de peito de frango');
    expect(r.quantity, 1.5);
    expect(r.unitCode, 'kg');
    expect(r.name, 'peito de frango');
  });

  test('intervalo fica com o mínimo e consome os dois números', () {
    final r = parseIngredientLine('2 a 3 dentes de alho picados');
    expect(r.quantity, 2);
    expect(r.unitCode, 'dente');
    expect(r.qualifier, 'picados');
    expect(r.name, 'alho');
  });

  test('sem quantidade numérica, unidade subjetiva', () {
    final r = parseIngredientLine('sal a gosto');
    expect(r.quantity, isNull);
    expect(r.unitCode, isNull);
    expect(r.qualifier, 'a gosto');
    expect(r.name, 'sal');
  });

  test('qualificador depois de vírgula', () {
    final r = parseIngredientLine('3 tomates, picados');
    expect(r.quantity, 3);
    expect(r.unitCode, isNull);
    expect(r.qualifier, 'picados');
    expect(r.name, 'tomates');
  });

  test('linha sem quantidade nem unidade não bloqueia', () {
    final r = parseIngredientLine('farinha');
    expect(r.quantity, isNull);
    expect(r.unitCode, isNull);
    expect(r.qualifier, isNull);
    expect(r.name, 'farinha');
  });

  test('linha vazia devolve nome vazio sem lançar exceção', () {
    final r = parseIngredientLine('   ');
    expect(r.quantity, isNull);
    expect(r.name, isEmpty);
  });

  test('raw_text é sempre preservado como veio', () {
    const raw = '  2 xícaras de farinha  ';
    final r = parseIngredientLine(raw);
    expect(r.rawText, raw);
  });

  test('mistura de fração ascii com inteiro ("1 1/2")', () {
    final r = parseIngredientLine('1 1/2 xícara de leite');
    expect(r.quantity, 1.5);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'leite');
  });
}
