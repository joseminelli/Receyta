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

  test('conectivo sozinho no fim não vira nome nem quebra a sugestão', () {
    final r = parseIngredientLine('7 colheres de');
    expect(r.name, isNot('de'));
    expect(r.unitCode, 'colher_sopa');
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

  test('"meia" por extenso (achado gerando lista de compras)', () {
    final r = parseIngredientLine('meia xícara de farinha');
    expect(r.quantity, 0.5);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha');
  });

  test('"meio" por extenso (concordância com substantivo masculino)', () {
    final r = parseIngredientLine('meio copo de leite');
    expect(r.quantity, 0.5);
    expect(r.unitCode, 'copo');
    expect(r.name, 'leite');
  });

  test('número misto com "e meia" por extenso', () {
    final r = parseIngredientLine('2 e meia xícara de farinha');
    expect(r.quantity, 2.5);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha');
  });

  test('"meia" não vira quantidade quando é prefixo de outra palavra', () {
    final r = parseIngredientLine('meiota de queijo');
    expect(r.quantity, isNull);
    expect(r.name, 'meiota de queijo');
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

  test('mistura com "e" por extenso ("1 e 1/2")', () {
    final r = parseIngredientLine('1 e 1/2 xícaras de farinha de trigo');
    expect(r.quantity, 1.5);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha de trigo');
  });

  test('mistura com "e" e fração unicode ("2 e ½")', () {
    final r = parseIngredientLine('2 e ½ colheres de sopa de açúcar');
    expect(r.quantity, 2.5);
    expect(r.unitCode, 'colher_sopa');
    expect(r.name, 'açúcar');
  });

  test('unidade sem acento ainda casa (usuário digita "xicaras")', () {
    final r = parseIngredientLine('2 xicaras de farinha');
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha');
  });

  test('qualificador sem acento ainda casa e preserva o que foi digitado', () {
    final r = parseIngredientLine('cebola media');
    expect(r.qualifier, 'media');
    expect(r.name, 'cebola');
  });

  test('fração com espaço em volta da barra ("1 / 4") no início', () {
    final r = parseIngredientLine('1 / 4 xícara de farinha');
    expect(r.quantity, 0.25);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha');
  });

  test('quantidade no fim da linha (comum em OCR, C8)', () {
    final r = parseIngredientLine('farinha de trigo 1/4 xícara');
    expect(r.quantity, 0.25);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha de trigo');
  });

  test('quantidade no meio, com espaço na barra', () {
    final r = parseIngredientLine('farinha 1 / 4 xícara');
    expect(r.quantity, 0.25);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'farinha');
  });

  test('"xícara de chá" casa como unidade própria, não sobra "chá" no nome',
      () {
    final r = parseIngredientLine('2 xícaras de chá de farinha de trigo');
    expect(r.quantity, 2);
    expect(r.unitCode, 'xicara_cha');
    expect(r.name, 'farinha de trigo');
  });

  test('"xícara de café" também casa como unidade própria', () {
    final r = parseIngredientLine('1 xícara de café de leite');
    expect(r.unitCode, 'xicara_cafe');
    expect(r.name, 'leite');
  });

  test('sem quantidade em lugar nenhum continua caindo no fallback', () {
    final r = parseIngredientLine('farinha de trigo integral');
    expect(r.quantity, isNull);
    expect(r.name, 'farinha de trigo integral');
  });

  test(
      '"I" maiúsculo no lugar de "1" (fonte sem serifa, comum em OCR, C8) '
      'ainda vira quantidade 1', () {
    final r = parseIngredientLine('I colher de sopa de farinha de aveia');
    expect(r.quantity, 1);
    expect(r.unitCode, 'colher_sopa');
    expect(r.name, 'farinha de aveia');
  });

  test('"I" colado direto na unidade, sem espaço (também comum em OCR)', () {
    final r = parseIngredientLine('Icolher de sopa de azeite');
    expect(r.quantity, 1);
    expect(r.unitCode, 'colher_sopa');
    expect(r.name, 'azeite');
  });

  test('"I e 1/2" (número misto) com o "1" inicial lido como "I"', () {
    final r = parseIngredientLine('I e 1/2 colher de chá de alho moído');
    expect(r.quantity, 1.5);
    expect(r.unitCode, 'colher_cha');
  });

  test('"I" no fim da linha, junto com a unidade (comum em OCR, C8)', () {
    final r = parseIngredientLine('sal marinho I colher de chá');
    expect(r.quantity, 1);
    expect(r.unitCode, 'colher_cha');
    expect(r.name, 'sal marinho');
  });

  test('palavra de verdade começando com "I"/"l" não vira quantidade à toa',
      () {
    expect(parseIngredientLine('Iogurte natural').quantity, isNull);
    expect(parseIngredientLine('leite').quantity, isNull);
    expect(parseIngredientLine('laranja').quantity, isNull);
  });

  test(
      '"1" também vira "T" às vezes (mais raro que I/l, mas acontece), '
      'grudado direto na fração', () {
    final r = parseIngredientLine('T/4 de xícara de água morna');
    expect(r.quantity, 0.25);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'água morna');
  });

  test('palavra de verdade começando com "T" não vira quantidade à toa', () {
    expect(parseIngredientLine('Tâmaras picadas').quantity, isNull);
    expect(parseIngredientLine('Trigo sarraceno').quantity, isNull);
  });

  test(
      'número misto "1 e 1/4" grudado ("Ie l/4xícara", "1" e "e" sem '
      'espaço entre si e o numerador também virou letra)', () {
    final r = parseIngredientLine('Ie l/4xícara de polvilho doce');
    expect(r.quantity, 1.25);
    expect(r.unitCode, 'xicara');
    expect(r.name, 'polvilho doce');
  });

  test(
      'fração inteira ilegível ("1/3" virou algo como "IB") não trava o '
      'parser — fica sem quantidade/unidade pro usuário ajustar na revisão',
      () {
    final r = parseIngredientLine('IB de xícara de azeite');
    expect(r.quantity, isNull);
    expect(
        () => parseIngredientLine('IB de xícara de azeite'), returnsNormally);
  });

  group('medidas entre parênteses, "e meia" e restos de embalagem', () {
    test('"xícara (chá)" e "colher (sopa)" são só a unidade', () {
      final a = parseIngredientLine('1 xícara (chá) de açúcar');
      expect(a.quantity, 1);
      expect(a.unitCode, 'xicara');
      expect(a.name, 'açúcar');

      final b = parseIngredientLine('2 colheres (sopa) de manteiga');
      expect(b.quantity, 2);
      expect(b.unitCode, 'colher_sopa');
      expect(b.name, 'manteiga');

      final c = parseIngredientLine('1 colher (café) de canela');
      expect(c.unitCode, 'colher_cafe');
      expect(c.name, 'canela');
    });

    test('"colher (chá) rasa" e "(sopa) bem cheia" não sujam o nome', () {
      final a = parseIngredientLine('1 colher (chá) rasa de sal');
      expect(a.unitCode, 'colher_cha');
      expect(a.qualifier, 'rasa');
      expect(a.name, 'sal');

      final b = parseIngredientLine('1 colher (sopa) bem cheia de manteiga');
      expect(b.unitCode, 'colher_sopa');
      expect(b.qualifier, 'bem cheia');
      expect(b.name, 'manteiga');
    });

    test('colher (sobremesa) cai na de sopa, sem entrar no nome', () {
      final r = parseIngredientLine('1 colher (sobremesa) de fermento químico');
      expect(r.unitCode, 'colher_sopa');
      expect(r.name, 'fermento químico');
    });

    test('"2 xícaras e meia" soma 2,5', () {
      final r = parseIngredientLine('2 xícaras e meia de farinha');
      expect(r.quantity, 2.5);
      expect(r.unitCode, 'xicara');
      expect(r.name, 'farinha');
    });

    test('"1 xícara (chá) e meia" e "e 1/4" somam, na ordem que vier', () {
      final a = parseIngredientLine('1 xícara (chá) e meia de açúcar');
      expect(a.quantity, 1.5);
      expect(a.unitCode, 'xicara');
      expect(a.name, 'açúcar');

      final b = parseIngredientLine('2 xícaras e 1/4 de leite');
      expect(b.quantity, 2.25);
      expect(b.name, 'leite');
    });

    test('número por extenso, só quando vem uma unidade', () {
      final a = parseIngredientLine('uma xícara e meia de leite');
      expect(a.quantity, 1.5);
      expect(a.name, 'leite');

      final b = parseIngredientLine('duas colheres (sopa) de óleo');
      expect(b.quantity, 2);
      expect(b.unitCode, 'colher_sopa');

      final c = parseIngredientLine('um pouco de sal');
      expect(c.quantity, isNull);
    });

    test('número entre parênteses vira número solto', () {
      final r = parseIngredientLine('(50) g de queijo parmesão');
      expect(r.quantity, 50);
      expect(r.unitCode, 'g');
      expect(r.name, 'queijo parmesão');
    });

    test('tamanho da embalagem, ® e marca não viram outro ingrediente', () {
      final a = parseIngredientLine('1 lata de leite condensado (395g)');
      expect(a.unitCode, 'lata');
      expect(a.name, 'leite condensado');

      final b = parseIngredientLine('1 lata de leite condensado Moça®');
      expect(b.name, 'leite condensado');

      final c = parseIngredientLine('1 caixa de creme de leite Nestlé®');
      expect(c.name, 'creme de leite');
    });

    test('a linha de antes continua igual', () {
      final r = parseIngredientLine('2 xícaras de farinha de trigo');
      expect(r.quantity, 2);
      expect(r.name, 'farinha de trigo');
    });
  });

  group('formatos vistos em receitas importadas', () {
    test('"Colheres(sopa)" sem espaço antes do parêntese', () {
      final r = parseIngredientLine('5 Colheres(sopa) de Óleo');
      expect(r.quantity, 5);
      expect(r.unitCode, 'colher_sopa');
      expect(r.name, 'Óleo');
    });

    test('"colher(sopa) cheias de polvilho azedo"', () {
      final r = parseIngredientLine('8 colher(sopa) cheias de polvilho azedo');
      expect(r.unitCode, 'colher_sopa');
      expect(r.qualifier, 'cheias');
      expect(r.name, 'polvilho azedo');
    });

    test('"1 pacote de (50) g de queijo parmesão, ralado"', () {
      final r =
          parseIngredientLine('1 pacote de (50) g de queijo parmesão, ralado');
      expect(r.quantity, 1);
      expect(r.unitCode, 'pacote');
      expect(r.qualifier, 'ralado');
      expect(r.name, 'queijo parmesão');
    });

    test('"(50 g) de queijo" no começo do nome', () {
      final r = parseIngredientLine('1 pacote (50 g) de queijo ralado');
      expect(r.unitCode, 'pacote');
      expect(r.name, 'queijo');
    });

    test(
        'letra solta no lugar da quantidade: tira a letra, sem inventar número',
        () {
      final r = parseIngredientLine('A de xicara de pasta de gergelim');
      expect(r.quantity, isNull);
      expect(r.unitCode, 'xicara');
      expect(r.name, 'pasta de gergelim');
    });
  });
}
