/// Extração de receita a partir de HTML via JSON-LD schema.org/Recipe (C7,
/// RF-06.9). Dart puro — sem Flutter, sem rede (quem busca a URL é a camada
/// de dados). Não normaliza nem valida os textos: ingredientes e passos
/// saem como linhas cruas, do mesmo jeito que a digitação manual — passam
/// pelo parser (C1) e pelo normalizador (C2) só na hora de salvar.
library;

import 'dart:convert';

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
  });

  final String name;
  final String? about;
  final int? prepMinutes;
  final int? cookMinutes;
  final int? servings;
  final List<String> ingredientLines;
  final List<String> stepLines;
  final String? sourceUrl;
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
    Object? json;
    try {
      json = jsonDecode(text);
    } catch (_) {
      continue;
    }
    final node = _findRecipeNode(json);
    if (node != null) return _parseRecipeNode(node, sourceUrl);
  }
  return null;
}

Map<String, dynamic>? _findRecipeNode(Object? json) {
  if (json is Map<String, dynamic>) {
    if (_isRecipeType(json['@type'])) return json;
    final graph = json['@graph'];
    if (graph is List) {
      for (final node in graph) {
        final found = _findRecipeNode(node);
        if (found != null) return found;
      }
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

bool _isRecipeType(Object? type) {
  if (type is String) return type == 'Recipe';
  if (type is List) return type.contains('Recipe');
  return false;
}

ImportedRecipe _parseRecipeNode(Map<String, dynamic> node, String? sourceUrl) {
  final name = _decodeHtmlEntities((node['name'] ?? '').toString().trim());
  final rawAbout = (node['description'] as Object?)?.toString().trim();
  final about = rawAbout == null ? null : _decodeHtmlEntities(rawAbout);

  return ImportedRecipe(
    name: name.isEmpty ? 'Receita importada' : fixShoutyCase(name),
    about: (about == null || about.isEmpty) ? null : about,
    prepMinutes: _parseIsoDurationMinutes(node['prepTime']),
    cookMinutes: _parseIsoDurationMinutes(node['cookTime']),
    servings: _parseServings(node['recipeYield'] ?? node['yield']),
    ingredientLines:
        _stringList(node['recipeIngredient'] ?? node['ingredients']),
    stepLines: _extractSteps(node['recipeInstructions']),
    sourceUrl: sourceUrl,
  );
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
      if (node['@type'] == 'HowToSection') {
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
  final pieces = text.contains('\n')
      ? text.split('\n')
      : text.split(_sentenceSplitRegex);
  return [for (final p in pieces) p.trim()].where((s) => s.isNotEmpty).toList();
}

/// Domínios de duas partes comuns o bastante pra valer a pena reconhecer —
/// sem isso, "tudogostoso.com.br" resolveria pra "com" em vez de
/// "tudogostoso". Lista curta de propósito: não é uma lista pública de
/// sufixos completa, só cobre os TLDs mais comuns entre sites de receita.
const _twoPartSuffixes = {
  'com.br', 'com.au', 'com.mx', 'com.pt', 'com.ar', 'co.uk', 'co.jp',
  'org.br', 'net.br', 'gov.br', 'edu.br',
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
  final brandIndex =
      _twoPartSuffixes.contains(lastTwo) ? labels.length - 3 : labels.length - 2;
  final brand = brandIndex >= 0 ? labels[brandIndex] : labels.last;
  return canonicalTagName(brand);
}
