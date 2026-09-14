import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/ocr_recipe_import.dart';

void main() {
  test('divide nome, ingredientes e passos por cabeçalho de seção', () {
    final r = parseOcrLines([
      'Bolo de fubá',
      'Ingredientes',
      '2 xícaras de fubá',
      '3 ovos',
      '1 xícara de açúcar',
      'Modo de preparo',
      'Misture tudo',
      'Asse por 40 minutos',
    ]);

    expect(r, isNotNull);
    expect(r!.name, 'Bolo de fubá');
    expect(r.ingredientLines,
        ['2 xícaras de fubá', '3 ovos', '1 xícara de açúcar']);
    expect(r.stepLines, ['Misture tudo', 'Asse por 40 minutos']);
  });

  test('cabeçalho de seção sem acento e maiúsculo também é reconhecido', () {
    final r = parseOcrLines([
      'Sopa',
      'INGREDIENTES',
      'Água',
      'INSTRUCOES',
      'Ferva a água',
    ]);
    expect(r!.ingredientLines, ['Água']);
    expect(r.stepLines, ['Ferva a água']);
  });

  test('linhas extras antes dos ingredientes viram sobre', () {
    final r = parseOcrLines([
      'Torta de limão',
      'Rende 8 porções',
      'Ingredientes',
      'Massa',
    ]);
    expect(r!.name, 'Torta de limão');
    expect(r.about, 'Rende 8 porções');
  });

  test('junta linhas quebradas do mesmo passo numerado', () {
    final r = parseOcrLines([
      'Receita',
      'Ingredientes',
      'Sal',
      'Modo de preparo',
      '1. Tempere o frango com sal e pimenta,',
      'deixando descansar por 10 minutos.',
      '2. Leve ao forno por 40 minutos.',
    ]);
    expect(r!.stepLines, [
      'Tempere o frango com sal e pimenta, deixando descansar por 10 minutos.',
      'Leve ao forno por 40 minutos.',
    ]);
  });

  test('passos sem numeração viram uma linha cada (melhor esforço)', () {
    final r = parseOcrLines([
      'Receita',
      'Ingredientes',
      'Sal',
      'Preparo',
      'Tempere o frango.',
      'Leve ao forno.',
    ]);
    expect(r!.stepLines, ['Tempere o frango.', 'Leve ao forno.']);
  });

  test('sem nenhum marcador de seção, cai no melhor esforço', () {
    final r = parseOcrLines(['Bolo simples', 'farinha', 'açúcar', 'ovos']);
    expect(r!.name, 'Bolo simples');
    expect(r.ingredientLines, ['farinha', 'açúcar', 'ovos']);
    expect(r.stepLines, isEmpty);
  });

  test('só ingredientes, sem seção de passos', () {
    final r = parseOcrLines(['Salada', 'Ingredientes', 'Alface', 'Tomate']);
    expect(r!.ingredientLines, ['Alface', 'Tomate']);
    expect(r.stepLines, isEmpty);
  });

  test('linhas vazias são ignoradas', () {
    final r = parseOcrLines(['Bolo', '', '  ', 'Ingredientes', 'Farinha']);
    expect(r!.name, 'Bolo');
    expect(r.ingredientLines, ['Farinha']);
  });

  test('tira marcador de lista do início da linha, sem mexer na barra da fração', () {
    final r = parseOcrLines([
      'Bolo',
      'Ingredientes',
      '• 2 ovos',
      '- 1/2 xícara de leite',
      '* 1/4 xícara de açúcar',
      '– farinha',
    ]);
    expect(r!.ingredientLines, [
      '2 ovos',
      '1/2 xícara de leite',
      '1/4 xícara de açúcar',
      'farinha',
    ]);
  });

  test('linha que é só o marcador de lista some (fica vazia)', () {
    final r = parseOcrLines(['Bolo', 'Ingredientes', '•', 'Farinha']);
    expect(r!.ingredientLines, ['Farinha']);
  });

  test('sem texto nenhum devolve null', () {
    expect(parseOcrLines([]), isNull);
    expect(parseOcrLines(['', '  ']), isNull);
  });

  test('descarta ruído de interface de rede social (print de TikTok)', () {
    final r = parseOcrLines([
      '@chefreceitas',
      'Bolo de fubá',
      'Seguir',
      '1,2 mil curtidas',
      'Ingredientes',
      '2 xícaras de fubá',
      '#receitafacil',
      '340 comentários',
      'Modo de preparo',
      'Misture tudo',
      'Compartilhar',
    ]);

    expect(r!.name, 'Bolo de fubá');
    expect(r.ingredientLines, ['2 xícaras de fubá']);
    expect(r.stepLines, ['Misture tudo']);
  });

  test('ruído de rede social sozinho não quebra nada (só some)', () {
    final r = parseOcrLines(['Seguir', '@fulano', 'Bolo', 'Farinha']);
    expect(r!.name, 'Bolo');
    expect(r.ingredientLines, ['Farinha']);
  });

  test('print de site de receita: barra de status, abas, legenda e anúncio '
      'no fim não entram no resultado', () {
    final r = parseOcrLines([
      '22:11 O',
      'Resumo Ingredientes Modo de preparo Comentários',
      'Bolo de nozes — Foto: Receitas',
      'Ingredientes',
      '3 claras',
      '3 gemas',
      '2 xícaras de chá de açúcar',
      '2 xícaras de chá de farinha de trigo',
      '1 xícara de chá de leite',
      '1 colher de sopa de fermento em pó',
      '1 xícara de chá de nozes trituradas',
      'Faltou algo? Tenta essas',
      'globoplay',
      'BELEZA VERDADEIRA',
      'Assista',
      'I 59%',
    ]);

    expect(r!.name, 'Bolo de nozes');
    expect(r.about, isNull);
    expect(r.ingredientLines, [
      '3 claras',
      '3 gemas',
      '2 xícaras de chá de açúcar',
      '2 xícaras de chá de farinha de trigo',
      '1 xícara de chá de leite',
      '1 colher de sopa de fermento em pó',
      '1 xícara de chá de nozes trituradas',
    ]);
  });

  test('cabeçalho de anúncio ("Faltou algo?") sozinho, sem "Ingredientes" '
      'nenhum, ainda corta a lista no melhor esforço', () {
    final r = parseOcrLines([
      'Bolo simples',
      'farinha',
      'açúcar',
      'Faltou algo? Tenta essas',
      'globoplay',
    ]);
    expect(r!.name, 'Bolo simples');
    expect(r.ingredientLines, ['farinha', 'açúcar']);
  });
}
