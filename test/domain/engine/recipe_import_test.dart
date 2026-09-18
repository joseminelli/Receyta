import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

void main() {
  test('extrai receita de um bloco JSON-LD direto', () {
    const html = '''
<html><head>
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Recipe",
  "name": "Frango ao curry",
  "description": "Rápido para dias de semana.",
  "prepTime": "PT15M",
  "cookTime": "PT25M",
  "recipeYield": "4 porções",
  "recipeIngredient": ["500g de peito de frango", "400ml de leite de coco"],
  "recipeInstructions": [
    {"@type": "HowToStep", "text": "Tempere o frango."},
    {"@type": "HowToStep", "text": "Refogue com o leite de coco."}
  ]
}
</script>
</head><body></body></html>
''';

    final r = extractRecipeFromHtml(html, sourceUrl: 'https://x.com/r');
    expect(r, isNotNull);
    expect(r!.name, 'Frango ao curry');
    expect(r.about, 'Rápido para dias de semana.');
    expect(r.prepMinutes, 15);
    expect(r.cookMinutes, 25);
    expect(r.servings, 4);
    expect(r.ingredientLines,
        ['500g de peito de frango', '400ml de leite de coco']);
    expect(r.stepLines, ['Tempere o frango.', 'Refogue com o leite de coco.']);
    expect(r.sourceUrl, 'https://x.com/r');
  });

  test('acha a receita dentro de @graph', () {
    const html = '''
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@graph": [
    {"@type": "WebSite", "name": "Site"},
    {
      "@type": ["Recipe", "Thing"],
      "name": "Bolo de fubá",
      "recipeIngredient": ["2 xícaras de fubá"],
      "recipeInstructions": "Misture tudo e asse."
    }
  ]
}
</script>
''';

    final r = extractRecipeFromHtml(html);
    expect(r, isNotNull);
    expect(r!.name, 'Bolo de fubá');
    expect(r.ingredientLines, ['2 xícaras de fubá']);
    expect(r.stepLines, ['Misture tudo e asse.']);
  });

  test('acha a receita quando o JSON-LD é um array na raiz', () {
    const html = '''
<script type="application/ld+json">
[
  {"@type": "BreadcrumbList"},
  {"@type": "Recipe", "name": "Salada", "recipeIngredient": ["Alface"]}
]
</script>
''';

    final r = extractRecipeFromHtml(html);
    expect(r, isNotNull);
    expect(r!.name, 'Salada');
  });

  test('achata HowToSection aninhada', () {
    const html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Torta",
  "recipeInstructions": [
    {
      "@type": "HowToSection",
      "name": "Massa",
      "itemListElement": [
        {"@type": "HowToStep", "text": "Misture a farinha."},
        {"@type": "HowToStep", "text": "Adicione a manteiga."}
      ]
    },
    {"@type": "HowToStep", "text": "Asse por 40 minutos."}
  ]
}
</script>
''';

    final r = extractRecipeFromHtml(html);
    expect(r!.stepLines, [
      'Misture a farinha.',
      'Adicione a manteiga.',
      'Asse por 40 minutos.',
    ]);
  });

  test('sem JSON-LD de receita, devolve null', () {
    const html = '<html><head></head><body>Sem nada aqui</body></html>';
    expect(extractRecipeFromHtml(html), isNull);
  });

  test('JSON-LD malformado é ignorado, não lança exceção', () {
    const html = '''
<script type="application/ld+json">{ isso não é json }</script>
<script type="application/ld+json">
{"@type": "Recipe", "name": "Sopa"}
</script>
''';
    final r = extractRecipeFromHtml(html);
    expect(r!.name, 'Sopa');
  });

  test('sem nome, cai num nome padrão em vez de ficar vazio', () {
    const html = '''
<script type="application/ld+json">
{"@type": "Recipe", "recipeIngredient": ["Sal"]}
</script>
''';
    final r = extractRecipeFromHtml(html);
    expect(r!.name, 'Receita importada');
  });

  test('recipeYield numérico e como lista', () {
    const htmlNum = '''
<script type="application/ld+json">
{"@type": "Recipe", "name": "A", "recipeYield": 6}
</script>
''';
    expect(extractRecipeFromHtml(htmlNum)!.servings, 6);

    const htmlList = '''
<script type="application/ld+json">
{"@type": "Recipe", "name": "B", "recipeYield": ["8 servings"]}
</script>
''';
    expect(extractRecipeFromHtml(htmlList)!.servings, 8);
  });

  test('decodifica entidades HTML escapadas duas vezes (bug do tudogostoso)',
      () {
    const html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "P&amp;atilde;o de queijo",
  "description": "Aque&amp;ccedil;a a &amp;aacute;gua.",
  "recipeIngredient": ["&amp;Aacute;gua e &amp;oacute;leo"],
  "recipeInstructions": "Aque&amp;ccedil;a uma frigideira."
}
</script>
''';
    final r = extractRecipeFromHtml(html);
    expect(r!.name, 'Pão de queijo');
    expect(r.about, 'Aqueça a água.');
    expect(r.ingredientLines, ['Água e óleo']);
    expect(r.stepLines, ['Aqueça uma frigideira.']);
  });

  test(
      'recipeInstructions como parágrafo único vira um passo por frase, não '
      'tudo junto', () {
    const html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "Pão de queijo de frigideira",
  "recipeInstructions": "Misture os ingredientes secos. Aqueça a frigideira e frite a massa. Deixe corar."
}
</script>
''';
    final r = extractRecipeFromHtml(html);
    expect(r!.stepLines, [
      'Misture os ingredientes secos.',
      'Aqueça a frigideira e frite a massa.',
      'Deixe corar.',
    ]);
  });

  test('HowToStep.text com frase só não é resplitado', () {
    const html = '''
<script type="application/ld+json">
{
  "@type": "Recipe",
  "name": "A",
  "recipeInstructions": [
    {"@type": "HowToStep", "text": "Preaqueça o forno a 180 graus. Unte a forma."}
  ]
}
</script>
''';
    final r = extractRecipeFromHtml(html);
    expect(r!.stepLines, ['Preaqueça o forno a 180 graus. Unte a forma.']);
  });

  test('duração com horas e minutos', () {
    const html = '''
<script type="application/ld+json">
{"@type": "Recipe", "name": "A", "cookTime": "PT1H30M"}
</script>
''';
    expect(extractRecipeFromHtml(html)!.cookMinutes, 90);
  });

  group('siteTagFromUrl', () {
    test('domínio com sufixo de duas partes usa o nome antes dele', () {
      expect(siteTagFromUrl('https://www.tudogostoso.com.br/receita/1'),
          'Tudogostoso');
      expect(siteTagFromUrl('https://panelinha.com.br/'), 'Panelinha');
    });

    test('subdomínio + domínio comum usa o domínio, não o subdomínio', () {
      expect(siteTagFromUrl('https://receitas.globo.com/x'), 'Globo');
    });

    test('domínio .com simples', () {
      expect(siteTagFromUrl('https://www.allrecipes.com/recipe/1'),
          'Allrecipes');
    });

    test('sem URL ou sem host devolve null', () {
      expect(siteTagFromUrl(null), isNull);
      expect(siteTagFromUrl('não é url'), isNull);
    });
  });
}
