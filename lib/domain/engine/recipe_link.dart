/// O link de receita: `https://receyta.whisklinestudio.com/r#<dados>`. A
/// receita inteira (sem foto) vai no trecho depois do `#`: JSON compacto,
/// gzip e base64url. O trecho nunca chega ao servidor; o site decodifica no
/// navegador e o app, no import.
library;

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

const recipeLinkHost = 'receyta.whisklinestudio.com';
const _maxFragmentChars = 6000;

/// Nulo quando a receita não cabe num link; aí o caminho é o arquivo.
String? recipeLink(RecipeDetail detail) {
  final r = detail.recipe;
  final map = <String, Object>{
    'v': 1,
    'n': r.name,
    if (r.about != null) 'a': r.about!,
    if (r.prepMinutes != null) 'p': r.prepMinutes!,
    if (r.cookMinutes != null) 'c': r.cookMinutes!,
    if (r.servings != null) 's': r.servings!,
    if (r.sourceUrl != null) 'u': r.sourceUrl!,
    'i': _withHeadings([
      for (final i in detail.ingredients) (i.rawText, i.groupLabel),
    ]),
    'm': _withHeadings([
      for (final s in detail.steps) (s.text, s.groupLabel),
    ]),
  };
  final bytes = gzip.encode(utf8.encode(jsonEncode(map)));
  final fragment = base64Url.encode(bytes).replaceAll('=', '');
  if (fragment.length > _maxFragmentChars) return null;
  return 'https://$recipeLinkHost/r#$fragment';
}

/// A receita dentro de um link de receita, ou nulo se [text] não é um.
ImportedRecipe? recipeFromLink(String text) {
  final match = RegExp(
    'https://${RegExp.escape(recipeLinkHost)}/r#([A-Za-z0-9_-]+)',
    caseSensitive: false,
  ).firstMatch(text.trim());
  final fragment = match?.group(1);
  if (fragment == null || fragment.length > _maxFragmentChars) return null;
  try {
    final json = utf8.decode(
      gzip.decode(base64Url.decode(base64Url.normalize(fragment))),
    );
    final map = jsonDecode(json);
    if (map is! Map || map['v'] != 1) return null;
    final name = map['n'];
    if (name is! String || name.trim().isEmpty) return null;
    return ImportedRecipe(
      name: name.trim(),
      about: map['a'] as String?,
      prepMinutes: (map['p'] as num?)?.toInt(),
      cookMinutes: (map['c'] as num?)?.toInt(),
      servings: (map['s'] as num?)?.toInt(),
      sourceUrl: map['u'] as String?,
      ingredientLines: _strings(map['i']),
      stepLines: _strings(map['m']),
    );
  } catch (_) {
    return null;
  }
}

List<String> _strings(Object? raw) =>
    raw is List ? [for (final e in raw) if (e is String) e] : const [];

List<String> _withHeadings(List<(String, String?)> items) {
  final out = <String>[];
  String? current;
  for (final (text, group) in items) {
    if (group != null && group != current) out.add('$group:');
    current = group;
    out.add(text);
  }
  return out;
}
