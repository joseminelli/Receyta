/// Detector de receita repetida no import (link ou foto): compara o que está
/// chegando com o que a pessoa já tem. Dart puro — quem chama monta as
/// receitas existentes. Só avisa; quem decide é o usuário.
library;

import 'package:receyta/domain/engine/fuzzy_match.dart';
import 'package:receyta/domain/engine/ingredient_normalizer.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';

/// Parecidas a partir daqui (Jaccard dos ingredientes), com pelo menos
/// [kMinIngredientsForMatch] de cada lado — menos que isso casa à toa.
const kIngredientOverlapThreshold = 0.7;
const kMinIngredientsForMatch = 3;

enum DuplicateReason { sameLink, sameName, sameIngredients }

/// Uma receita que a pessoa já tem, no formato que o detector precisa.
class ExistingRecipe {
  const ExistingRecipe({
    required this.id,
    required this.name,
    this.sourceUrl,
    this.ingredientKeys = const {},
  });

  final String id;
  final String name;
  final String? sourceUrl;

  /// `normalizedKey` dos ingredientes que ela usa.
  final Set<String> ingredientKeys;
}

class DuplicateMatch {
  const DuplicateMatch({
    required this.recipeId,
    required this.name,
    required this.reason,
  });

  final String recipeId;
  final String name;
  final DuplicateReason reason;
}

/// `normalizedKey` de cada linha de ingrediente de um rascunho de import
/// (mesmo caminho que o salvamento: parser, depois normalizador).
Set<String> ingredientKeysOf(Iterable<String> lines) {
  final keys = <String>{};
  for (final line in lines) {
    final key = normalize(parseIngredientLine(line).name);
    if (key.isNotEmpty) keys.add(key);
  }
  return keys;
}

/// Link sem esquema, `www.`, parâmetros, âncora e barra final — duas formas
/// de escrever o mesmo endereço comparam iguais.
String? canonicalUrl(String? url) {
  if (url == null) return null;
  var s = url.trim().toLowerCase();
  if (s.isEmpty) return null;
  s = s.replaceFirst(RegExp(r'^[a-z]+://'), '').replaceFirst('www.', '');
  s = s.split('#').first.split('?').first;
  s = s.replaceFirst(RegExp(r'/+$'), '');
  return s.isEmpty ? null : s;
}

/// A receita já existente que mais se parece com a que está chegando, ou
/// `null`. Prioridade: mesmo link, depois nome igual/parecido, depois
/// ingredientes quase iguais (o de maior sobreposição).
DuplicateMatch? findDuplicate({
  required String name,
  String? sourceUrl,
  Set<String> ingredientKeys = const {},
  required Iterable<ExistingRecipe> existing,
}) {
  final url = canonicalUrl(sourceUrl);
  final nameKey = normalize(name);

  DuplicateMatch? byName;
  DuplicateMatch? byIngredients;
  var bestOverlap = 0.0;

  for (final r in existing) {
    if (url != null && canonicalUrl(r.sourceUrl) == url) {
      return DuplicateMatch(
        recipeId: r.id,
        name: r.name,
        reason: DuplicateReason.sameLink,
      );
    }

    final otherKey = normalize(r.name);
    if (byName == null &&
        nameKey.isNotEmpty &&
        otherKey.isNotEmpty &&
        (nameKey == otherKey || isCloseMatch(nameKey, otherKey))) {
      byName = DuplicateMatch(
        recipeId: r.id,
        name: r.name,
        reason: DuplicateReason.sameName,
      );
    }

    if (ingredientKeys.length >= kMinIngredientsForMatch &&
        r.ingredientKeys.length >= kMinIngredientsForMatch) {
      final overlap = _jaccard(ingredientKeys, r.ingredientKeys);
      if (overlap >= kIngredientOverlapThreshold && overlap > bestOverlap) {
        bestOverlap = overlap;
        byIngredients = DuplicateMatch(
          recipeId: r.id,
          name: r.name,
          reason: DuplicateReason.sameIngredients,
        );
      }
    }
  }
  return byName ?? byIngredients;
}

double _jaccard(Set<String> a, Set<String> b) {
  final inter = a.intersection(b).length;
  final union = a.length + b.length - inter;
  return union == 0 ? 0 : inter / union;
}
