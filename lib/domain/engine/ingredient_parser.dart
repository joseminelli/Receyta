/// Parser de linha livre de ingrediente (§8.1, RF-03.1). Dart puro — sem
/// Flutter, sem Drift — para ficar testável com unit tests rápidos. Nunca
/// lança exceção: na dúvida, devolve o texto bruto como nome e quantidade
/// nula.
library;

import '../../data/database/seed_data.dart';

/// Resultado do parser para uma linha de ingrediente.
class ParsedIngredientLine {
  const ParsedIngredientLine({
    required this.rawText,
    required this.name,
    this.quantity,
    this.unitCode,
    this.qualifier,
  });

  final String rawText;

  /// Em intervalos ("2 a 3"), fica com o mínimo.
  final double? quantity;

  /// Bate com `Units.id` / `SeedUnit.code`.
  final String? unitCode;

  final String? qualifier;

  /// Ainda não resolvido contra o catálogo — isso é o C2 (`getOrCreate`).
  final String name;
}

const _connectors = {'de', 'da', 'do'};

const _fractionChars = {
  '½': 1 / 2,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '¼': 1 / 4,
  '¾': 3 / 4,
  '⅕': 1 / 5,
  '⅖': 2 / 5,
  '⅗': 3 / 5,
  '⅘': 4 / 5,
  '⅙': 1 / 6,
  '⅚': 5 / 6,
  '⅛': 1 / 8,
  '⅜': 3 / 8,
  '⅝': 5 / 8,
  '⅞': 7 / 8,
};

final _rangeRegex =
    RegExp(r'^(\d+(?:[.,]\d+)?)\s+a\s+(\d+(?:[.,]\d+)?)\s*', caseSensitive: false);
final _mixedAsciiFractionRegex = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)\s*');
final _asciiFractionRegex = RegExp(r'^(\d+)\s*/\s*(\d+)\s*');
final _mixedUnicodeFractionRegex =
    RegExp('^(\\d+)\\s*([${_fractionChars.keys.join()}])\\s*');
final _unicodeFractionRegex = RegExp('^([${_fractionChars.keys.join()}])\\s*');
final _decimalRegex = RegExp(r'^(\d+[.,]\d+)\s*');
final _integerRegex = RegExp(r'^(\d+)\s*');

double _parseDecimal(String s) => double.parse(s.replaceAll(',', '.'));

ParsedIngredientLine parseIngredientLine(
  String rawText, {
  List<SeedUnit> units = kSeedUnits,
  List<SeedNormalizerTerm>? normalizerTerms,
}) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) {
    return ParsedIngredientLine(rawText: rawText, name: '');
  }

  final (quantity, afterQuantity) = _extractQuantity(trimmed);
  final (unitCode, afterUnit) = _matchUnit(afterQuantity, units);
  final afterConnector = _stripLeadingConnector(afterUnit);
  final (qualifier, afterQualifier) = _extractQualifier(
    afterConnector,
    normalizerTerms ?? kSeedNormalizerTerms,
  );

  final name = afterQualifier.trim();
  return ParsedIngredientLine(
    rawText: rawText,
    quantity: quantity,
    unitCode: unitCode,
    qualifier: qualifier,
    name: name.isEmpty ? trimmed : name,
  );
}

(double?, String) _extractQuantity(String text) {
  var m = _rangeRegex.firstMatch(text);
  if (m != null) {
    return (_parseDecimal(m.group(1)!), text.substring(m.end));
  }

  m = _mixedAsciiFractionRegex.firstMatch(text);
  if (m != null) {
    final whole = int.parse(m.group(1)!);
    final num = int.parse(m.group(2)!);
    final den = int.parse(m.group(3)!);
    return (den == 0 ? null : whole + num / den, text.substring(m.end));
  }

  m = _asciiFractionRegex.firstMatch(text);
  if (m != null) {
    final num = int.parse(m.group(1)!);
    final den = int.parse(m.group(2)!);
    return (den == 0 ? null : num / den, text.substring(m.end));
  }

  m = _mixedUnicodeFractionRegex.firstMatch(text);
  if (m != null) {
    final whole = int.parse(m.group(1)!);
    return (whole + _fractionChars[m.group(2)!]!, text.substring(m.end));
  }

  m = _unicodeFractionRegex.firstMatch(text);
  if (m != null) {
    return (_fractionChars[m.group(1)!]!, text.substring(m.end));
  }

  m = _decimalRegex.firstMatch(text);
  if (m != null) {
    return (_parseDecimal(m.group(1)!), text.substring(m.end));
  }

  m = _integerRegex.firstMatch(text);
  if (m != null) {
    return (double.parse(m.group(1)!), text.substring(m.end));
  }

  return (null, text);
}

(String?, String) _matchUnit(String text, List<SeedUnit> units) {
  final rest = text.trimLeft();
  final lowerRest = rest.toLowerCase();

  final candidates = <String, String>{};
  for (final u in units) {
    candidates[u.displayName.toLowerCase()] = u.code;
    candidates[u.plural.toLowerCase()] = u.code;
  }
  final sortedKeys = candidates.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final key in sortedKeys) {
    if (!lowerRest.startsWith(key)) continue;
    final boundaryOk = lowerRest.length == key.length ||
        lowerRest[key.length] == ' ' ||
        lowerRest[key.length] == ',';
    if (boundaryOk) {
      return (candidates[key], rest.substring(key.length).trimLeft());
    }
  }
  return (null, rest);
}

String _stripLeadingConnector(String text) {
  final rest = text.trimLeft();
  final lowerRest = rest.toLowerCase();
  for (final c in _connectors) {
    if (lowerRest.startsWith('$c ')) {
      return rest.substring(c.length).trimLeft();
    }
  }
  return rest;
}

(String?, String) _extractQualifier(
  String text,
  List<SeedNormalizerTerm> terms,
) {
  final commaIndex = text.indexOf(',');
  if (commaIndex != -1) {
    final name = text.substring(0, commaIndex).trim();
    final qualifier = text.substring(commaIndex + 1).trim();
    return (qualifier.isEmpty ? null : qualifier, name);
  }

  final qualifierTerms = terms
      .where((t) => t.kind == 'qualifier')
      .map((t) => t.term)
      .toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final lowerText = text.toLowerCase();
  for (final term in qualifierTerms) {
    if (lowerText == term) continue;
    if (!lowerText.endsWith(term)) continue;
    final boundaryIndex = lowerText.length - term.length;
    if (boundaryIndex > 0 && lowerText[boundaryIndex - 1] == ' ') {
      return (term, text.substring(0, boundaryIndex).trim());
    }
  }
  return (null, text);
}
