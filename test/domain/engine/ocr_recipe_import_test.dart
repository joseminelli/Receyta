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

  test('print de post do Instagram: nome de conta, tempo, local, botão '
      '"Seguir", contadores e "Responder" não entram no resultado', () {
    final r = parseOcrLines([
      '18:52',
      'Você',
      'há 3 d',
      'mais_receitas_',
      'Seguir',
      'Neightbours • Home (s',
      'Pão de batata',
      'Ingredientes',
      '2 ovos',
      '1 xícara de leite morno (xícara de 240ml)',
      '50ml de óleo',
      '10g de fermento biológico seco',
      '1 e 1/2 colher de sopa de açúcar',
      '1 colher de manteiga ou margarina',
      '1 batata cozida e amassada',
      'mais ou menos 500 g de farinha de trigo',
      '1/2 colher de sopa de sal',
      '1 gema de ovo para pincelar por cima',
      'Modo de preparo: no vídeo',
      '859 mil',
      '3.854',
      '6.940',
      '365 mil',
      'Responder a você',
      'Curtido por profkarina_geo e outras 859.063',
      'pessoas',
    ]);

    expect(r!.name, 'Pão de batata');
    expect(r.ingredientLines, [
      '2 ovos',
      '1 xícara de leite morno (xícara de 240ml)',
      '50ml de óleo',
      '10g de fermento biológico seco',
      '1 e 1/2 colher de sopa de açúcar',
      '1 colher de manteiga ou margarina',
      '1 batata cozida e amassada',
      'mais ou menos 500 g de farinha de trigo',
      '1/2 colher de sopa de sal',
      '1 gema de ovo para pincelar por cima',
      'Modo de preparo: no vídeo',
    ]);
  });

  test('cabeçalho "Ingredientes:"/"Modo de Preparo:" com dois-pontos ainda '
      'divide as seções (sem isso tudo cai dentro de ingredientes)', () {
    final r = parseOcrLines([
      'Bolo',
      'Ingredientes:',
      'Farinha',
      'Modo de Preparo:',
      'Asse.',
    ]);
    expect(r!.ingredientLines, ['Farinha']);
    expect(r.stepLines, ['Asse.']);
  });

  test('print de "Visão geral" de IA do Google: aba de busca e selo de IA '
      'somem, nome vira o título de verdade (não o resumo gerado por IA, '
      'nem a aba "Modo IA"), e o resumo + descrição do card viram sobre',
      () {
    final r = parseOcrLines([
      'Modo IA',
      'Tudo Shopping',
      'Visão geral criada por IA',
      'Esta é uma receita de cookie de maçã com farinha de aveia, focada em '
          'ser saudável, sem açúcar refinado e sem farinha de trigo.',
      'Cookie Saudável de Maçã e Aveia (Sem Açúcar) •',
      'Esta versão utiliza a própria maçã e tâmaras/passas para adoçar.',
      'Ingredientes:',
      '2 maçãs médias descascadas e picadas ou raladas.',
      '150g de farinha de aveia.',
      'Modo de Preparo:',
      '1. Prepare a maçã: rale ou corte em cubos.',
      '2. Misture os ingredientes.',
    ]);

    expect(r!.name, 'Cookie Saudável de Maçã e Aveia (Sem Açúcar)');
    expect(
      r.about,
      'Esta é uma receita de cookie de maçã com farinha de aveia, focada em '
      'ser saudável, sem açúcar refinado e sem farinha de trigo. Esta '
      'versão utiliza a própria maçã e tâmaras/passas para adoçar.',
    );
    expect(r.ingredientLines, [
      '2 maçãs médias descascadas e picadas ou raladas.',
      '150g de farinha de aveia.',
    ]);
    expect(r.stepLines, [
      'Prepare a maçã: rale ou corte em cubos.',
      'Misture os ingredientes.',
    ]);
  });
}
