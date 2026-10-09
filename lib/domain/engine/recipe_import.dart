/// Extração de receita a partir de HTML via JSON-LD schema.org/Recipe (C7,
/// RF-06.9). Dart puro — sem Flutter, sem rede (quem busca a URL é a camada
/// de dados). Não normaliza nem valida os textos: ingredientes e passos
/// saem como linhas cruas, do mesmo jeito que a digitação manual — passam
/// pelo parser (C1) e pelo normalizador (C2) só na hora de salvar.
library;

import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/tag_name.dart';

/// O que dá pra puxar de uma página de receita. Sempre revisado pelo
/// usuário no formulário antes de salvar — nunca cria a receita sozinho.
class ImportedRecipe {
  const ImportedRecipe({
    required this.name,
    this.about,
    this.prepMinutes,
    this.cookMinutes,
    this.servings,
    this.ingredientLines = const [],
    this.stepLines = const [],
    this.sourceUrl,
    this.imageUrl,
    this.imagePath,
  });

  final String name;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final List<String> ingredientLines;
  final List<String> stepLines;
  final String? sourceUrl;

  /// Foto da página (`image` do JSON-LD, ou `og:image`), já absoluta. Quem
  /// baixa é a camada de dados.
  final String? imageUrl;

  /// Nome do arquivo da foto já baixada e guardada (preenchido depois do
  /// download, antes de abrir o formulário).
  final String? imagePath;

  ImportedRecipe copyWith({String? imagePath}) => ImportedRecipe(
        name: name,
        about: about,
        prepMinutes: prepMinutes,
        cookMinutes: cookMinutes,
        servings: servings,
        ingredientLines: ingredientLines,
        stepLines: stepLines,
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        imagePath: imagePath ?? this.imagePath,
      );
}

/// Procura um bloco `<script type="application/ld+json">` com
/// `@type: "Recipe"` no HTML (direto, dentro de `@graph`, ou num array) e
/// extrai os campos que o formulário usa. `null` se a página não tiver.
ImportedRecipe? extractRecipeFromHtml(String html, {String? sourceUrl}) {
  final document = html_parser.parse(html);
  final scripts =
      document.querySelectorAll('script[type="application/ld+json"]');

  for (final script in scripts) {
    final text = script.text.trim();
    if (text.isEmpty) continue;
    final json = _decodeLenient(text);
    if (json == null) continue;
    final node = _findRecipeNode(json);
    if (node != null) {
      final ogImage = document
          .querySelector('meta[property="og:image"]')
          ?.attributes['content'];
      return _parseRecipeNode(node, sourceUrl, ogImage);
    }
  }

  final micro = _microdataRecipe(document);
  if (micro == null) return null;
  final ogImage = document
      .querySelector('meta[property="og:image"]')
      ?.attributes['content'];
  return _parseRecipeNode(micro, sourceUrl, ogImage);
}

/// JSON-LD de CMS costuma vir com quebra de linha ou tab crus dentro das
/// strings, o que o JSON rejeita; na segunda tentativa troca por espaço.
Object? _decodeLenient(String text) {
  try {
    return jsonDecode(text);
  } catch (_) {
    try {
      return jsonDecode(text.replaceAll(RegExp(r'[\u0000-\u001F]'), ' '));
    } catch (_) {
      return null;
    }
  }
}

/// Receita marcada como microdata (`itemtype=".../Recipe"`), usada por sites
/// que nunca migraram pra JSON-LD. Devolve no mesmo formato do JSON-LD pra
/// reaproveitar o `_parseRecipeNode`.
Map<String, dynamic>? _microdataRecipe(Document document) {
  final root = document.querySelector('[itemtype*="schema.org/Recipe"]');
  if (root == null) return null;

  String clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
  String? valueOf(Element e) =>
      e.attributes['content'] ?? e.attributes['datetime'] ?? e.text;
  String? one(String prop) {
    final e = root.querySelector('[itemprop="$prop"]');
    final v = e == null ? null : valueOf(e);
    return v == null || clean(v).isEmpty ? null : clean(v);
  }

  List<String> many(String prop) => [
        for (final e in root.querySelectorAll('[itemprop="$prop"]'))
          if (e.querySelectorAll('li').isNotEmpty)
            for (final li in e.querySelectorAll('li')) clean(li.text)
          else
            clean(valueOf(e) ?? ''),
      ].where((s) => s.isNotEmpty).toList();

  final name = one('name');
  if (name == null) return null;
  final img = root.querySelector('[itemprop="image"]');
  return {
    'name': name,
    'description': one('description'),
    'prepTime': one('prepTime'),
    'cookTime': one('cookTime'),
    'recipeYield': one('recipeYield') ?? one('yield'),
    'recipeIngredient': [...many('recipeIngredient'), ...many('ingredients')],
    'recipeInstructions': many('recipeInstructions'),
    'image': img?.attributes['src'] ??
        img?.attributes['content'] ??
        img?.attributes['href'],
  };
}

Map<String, dynamic>? _findRecipeNode(Object? json) {
  if (json is Map<String, dynamic>) {
    if (_isRecipeType(json['@type'])) return json;
    for (final key in const ['@graph', 'mainEntity']) {
      final found = _findRecipeNode(json[key]);
      if (found != null) return found;
    }
    return null;
  }
  if (json is List) {
    for (final node in json) {
      final found = _findRecipeNode(node);
      if (found != null) return found;
    }
  }
  return null;
}

/// Aceita `Recipe`, `recipe` e `https://schema.org/Recipe`.
bool _isRecipeType(Object? type) {
  if (type is String) return type.split('/').last.toLowerCase() == 'recipe';
  if (type is List) return type.any(_isRecipeType);
  return false;
}

ImportedRecipe _parseRecipeNode(
  Map<String, dynamic> node,
  String? sourceUrl,
  String? ogImage,
) {
  final name = _decodeHtmlEntities((node['name'] ?? '').toString().trim());
  final rawAbout = (node['description'] as Object?)?.toString().trim();
  final about = rawAbout == null ? null : _decodeHtmlEntities(rawAbout);

  return ImportedRecipe(
    name: name.isEmpty ? 'Receita importada' : fixShoutyCase(name),
    about: (about == null || about.isEmpty) ? null : about,
    prepMinutes: _parseIsoDurationMinutes(node['prepTime']),
    cookMinutes: _parseIsoDurationMinutes(node['cookTime']),
    servings: _parseServings(node['recipeYield'] ?? node['yield']),
    ingredientLines: _rejoinSplitIngredients(
      _stringList(node['recipeIngredient'] ?? node['ingredients']),
    ),
    stepLines: _extractSteps(node['recipeInstructions']),
    sourceUrl: sourceUrl,
    imageUrl:
        _absoluteHttpUrl(_firstImageUrl(node['image']) ?? ogImage, sourceUrl),
  );
}

final _bareQuantity = RegExp(r'^\d+(?:[.,/]\d+)?(?:\s+\d+/\d+)?$|^[½⅓⅔¼¾⅛]$');

/// Alguns sites (ex.: superkoch.com.br) quebram cada `<li>` na quebra de
/// linha e mandam `"700"`, `"g de frango"` como dois ingredientes. Só junta
/// em pares quando o padrão é inequívoco: lista de tamanho par, com ao menos
/// duas linhas que são só um número, todas em posição par. Uma lista normal
/// nunca tem uma linha que é só "700".
List<String> _rejoinSplitIngredients(List<String> lines) {
  if (lines.length < 4 || lines.length.isOdd) return lines;
  var bare = 0;
  for (var i = 0; i < lines.length; i++) {
    if (!_bareQuantity.hasMatch(lines[i])) continue;
    if (i.isOdd) return lines;
    bare++;
  }
  if (bare < 2) return lines;
  return [
    for (var i = 0; i < lines.length; i += 2) '${lines[i]} ${lines[i + 1]}',
  ];
}

/// `image` pode ser texto, `ImageObject` (`url`/`contentUrl`) ou lista de
/// qualquer um dos dois — fica com o primeiro que tiver endereço.
String? _firstImageUrl(Object? value) {
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is Map) {
    final url = value['url'] ?? value['contentUrl'];
    return url == null ? null : _firstImageUrl(url);
  }
  if (value is List) {
    for (final v in value) {
      final found = _firstImageUrl(v);
      if (found != null) return found;
    }
  }
  return null;
}

/// Resolve [raw] contra a página de origem e só aceita http/https — `data:`,
/// `file:` e afins nunca viram download.
String? _absoluteHttpUrl(String? raw, String? base) {
  if (raw == null || raw.trim().isEmpty) return null;
  var uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  if (!uri.hasScheme) {
    final baseUri = base == null ? null : Uri.tryParse(base);
    if (baseUri == null || !baseUri.hasScheme) return null;
    uri = baseUri.resolveUri(uri);
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri.toString();
}

/// Alguns sites (ex.: tudogostoso.com.br) escapam as entidades HTML do
/// texto duas vezes dentro do próprio JSON-LD (`&amp;aacute;` em vez de
/// `á`). Decodifica em loop até o texto parar de mudar, o que resolve
/// tanto o caso normal (0 entidades, 1 passe sem efeito) quanto o
/// duplamente escapado (2 passes).
String _decodeHtmlEntities(String value) {
  var result = value;
  for (var i = 0; i < 4; i++) {
    final decoded = html_parser.parseFragment(result).text ?? result;
    if (decoded == result) break;
    result = decoded;
  }
  return result;
}

final _durationRegex = RegExp(r'^P(?:\d+D)?T?(?:(\d+)H)?(?:(\d+)M)?');

int? _parseIsoDurationMinutes(Object? value) {
  if (value is! String) return null;
  final match = _durationRegex.firstMatch(value.trim());
  if (match == null) return null;
  final hours = int.tryParse(match.group(1) ?? '') ?? 0;
  final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
  final total = hours * 60 + minutes;
  return total == 0 ? null : total;
}

int? _parseServings(Object? value) {
  String? s;
  if (value is num) return value.round();
  if (value is String) s = value;
  if (value is List && value.isNotEmpty) s = value.first.toString();
  if (s == null) return null;
  final match = RegExp(r'\d+').firstMatch(s);
  return match == null ? null : int.tryParse(match.group(0)!);
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return [for (final v in value) _decodeHtmlEntities(v.toString().trim())]
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (value is String) {
    final s = _decodeHtmlEntities(value.trim());
    return s.isEmpty ? const [] : [s];
  }
  return const [];
}

/// `recipeInstructions` pode ser string, lista de string, lista de
/// `HowToStep` (`{"@type":"HowToStep","text":"..."}`) ou `HowToSection`
/// (`{"@type":"HowToSection","itemListElement":[...]}`) aninhando passos —
/// achata tudo em ordem de leitura.
List<String> _extractSteps(Object? value) {
  final out = <String>[];
  void walk(Object? node, {required bool splitSentences}) {
    if (node is String) {
      final t = _decodeHtmlEntities(node).trim();
      if (t.isEmpty) return;
      if (splitSentences) {
        out.addAll(_splitIntoSentences(t));
      } else {
        out.add(t);
      }
    } else if (node is Map<String, dynamic>) {
      if (node['@type'] == 'HowToSection' ||
          (node['text'] == null && node['itemListElement'] != null)) {
        walk(node['itemListElement'], splitSentences: splitSentences);
      } else {
        final text = node['text'] ?? node['name'];
        if (text is String) walk(text, splitSentences: false);
      }
    } else if (node is List) {
      for (final n in node) {
        walk(n, splitSentences: splitSentences);
      }
    }
  }

  walk(value, splitSentences: true);
  return out;
}

/// Alguns sites (ex.: tudogostoso.com.br) mandam `recipeInstructions` como
/// um parágrafo único em vez de lista de `HowToStep` — sem isso, o passo a
/// passo inteiro cai junto num "passo 1" só. Separa por quebra de linha
/// quando existe; senão, por fim de frase (`.`/`!`/`?` seguido de espaço).
/// Só se aplica a texto solto — um `HowToStep.text` já é um passo
/// individual de verdade e não é resplitado.
final _sentenceSplitRegex = RegExp(r'(?<=[.!?])\s+(?=\S)');

List<String> _splitIntoSentences(String text) {
  final pieces =
      text.contains('\n') ? text.split('\n') : text.split(_sentenceSplitRegex);
  return [for (final p in pieces) p.trim()].where((s) => s.isNotEmpty).toList();
}

/// Domínios de duas partes comuns o bastante pra valer a pena reconhecer —
/// sem isso, "tudogostoso.com.br" resolveria pra "com" em vez de
/// "tudogostoso". Lista curta de propósito: não é uma lista pública de
/// sufixos completa, só cobre os TLDs mais comuns entre sites de receita.
const _twoPartSuffixes = {
  'com.br',
  'com.au',
  'com.mx',
  'com.pt',
  'com.ar',
  'co.uk',
  'co.jp',
  'org.br',
  'net.br',
  'gov.br',
  'edu.br',
};

/// Nome de tag a partir do domínio de onde a receita foi importada (C7) —
/// "tudogostoso.com.br" vira "Tudogostoso", "receitas.globo.com" vira
/// "Globo". `null` se a URL não tiver host.
String? siteTagFromUrl(String? sourceUrl) {
  if (sourceUrl == null) return null;
  var host = Uri.tryParse(sourceUrl)?.host ?? '';
  if (host.startsWith('www.')) host = host.substring(4);
  if (host.isEmpty) return null;

  final labels = host.split('.');
  if (labels.length < 2) return canonicalTagName(host);

  final lastTwo = '${labels[labels.length - 2]}.${labels[labels.length - 1]}';
  final brandIndex = _twoPartSuffixes.contains(lastTwo)
      ? labels.length - 3
      : labels.length - 2;
  final brand = brandIndex >= 0 ? labels[brandIndex] : labels.last;
  return canonicalTagName(brand);
}
