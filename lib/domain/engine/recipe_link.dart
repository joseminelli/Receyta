/// Links de receita. O texto da receita (sem foto) é JSON compacto, gzip e
/// base64url. Ele pode ir inteiro no link longo,
/// `https://receyta.whisklinestudio.com/r#<texto>` (o trecho depois do `#` não
/// chega ao servidor), ou ficar guardado no servidor e o link levar só o
/// token, `https://receyta.whisklinestudio.com/r/<token>`.
library;

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/domain/models/recipe_detail.dart';

const recipeLinkHost = 'receyta.whisklinestudio.com';
const _maxLongLinkChars = 6000;
const _maxStoredChars = 12000;

/// O texto da receita, ou nulo se passa do que o servidor aceita.
String? recipeFragment(RecipeDetail detail) {
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
  return fragment.length > _maxStoredChars ? null : fragment;
}

/// O link longo, ou nulo se [fragment] é grande demais pra um link.
String? longRecipeLink(String fragment) => fragment.length > _maxLongLinkChars
    ? null
    : 'https://$recipeLinkHost/r#$fragment';

String shortRecipeLink(String token) => 'https://$recipeLinkHost/r/$token';

/// O token dentro de um link curto, ou nulo se [text] não é um.
String? recipeTokenFromLink(String text) {
  final match = RegExp(
    'https://${RegExp.escape(recipeLinkHost)}/r/([0-9a-f]{10})(?![0-9A-Za-z])',
    caseSensitive: false,
  ).firstMatch(text.trim());
  return match?.group(1)?.toLowerCase();
}

/// A receita dentro de um link longo, ou nulo se [text] não é um.
ImportedRecipe? recipeFromLink(String text) {
  final match = RegExp(
    'https://${RegExp.escape(recipeLinkHost)}/r#([A-Za-z0-9_-]+)',
    caseSensitive: false,
  ).firstMatch(text.trim());
  final fragment = match?.group(1);
  if (fragment == null || fragment.length > _maxLongLinkChars) return null;
  return recipeFromFragment(fragment);
}

/// A receita dentro do texto guardado, ou nulo se ele está estragado.
ImportedRecipe? recipeFromFragment(String fragment) {
  if (fragment.length > _maxStoredChars) return null;
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
