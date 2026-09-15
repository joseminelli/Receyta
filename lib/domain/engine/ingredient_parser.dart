/// Parser de linha livre de ingrediente (§8.1, RF-03.1). Dart puro — sem
/// Flutter, sem Drift — para ficar testável com unit tests rápidos. Nunca
/// lança exceção: na dúvida, devolve o texto bruto como nome e quantidade
/// nula.
library;

import '../../data/database/seed_data.dart';
import 'text_normalize.dart';

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

const _unitSynonyms = {
  'colher': 'colher_sopa',
  'colheres': 'colher_sopa',
};

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

final _rangeRegex = RegExp(r'^(\d+(?:[.,]\d+)?)\s+a\s+(\d+(?:[.,]\d+)?)\s*',
    caseSensitive: false);
final _mixedAsciiFractionWithERegex =
    RegExp(r'^(\d+)\s+e\s+(\d+)\s*/\s*(\d+)\s*', caseSensitive: false);
final _mixedAsciiFractionRegex = RegExp(r'^(\d+)\s+(\d+)\s*/\s*(\d+)\s*');
final _asciiFractionRegex = RegExp(r'^(\d+)\s*/\s*(\d+)\s*');
final _mixedUnicodeFractionWithERegex = RegExp(
  '^(\\d+)\\s+e\\s+([${_fractionChars.keys.join()}])\\s*',
  caseSensitive: false,
);
final _mixedUnicodeFractionRegex =
    RegExp('^(\\d+)\\s*([${_fractionChars.keys.join()}])\\s*');
final _unicodeFractionRegex = RegExp('^([${_fractionChars.keys.join()}])\\s*');
final _decimalRegex = RegExp(r'^(\d+[.,]\d+)\s*');
final _integerRegex = RegExp(r'^(\d+)\s*');

double _parseDecimal(String s) => double.parse(s.replaceAll(',', '.'));

/// Reescreve na própria linha o "1" que o OCR (C8) leu como "I"/"l"/"T" —
/// não só acerta por baixo dos panos a quantidade extraída
/// ([parseIngredientLine]), mas também limpa o texto bruto que aparece na
/// tela de revisão ("I dente de alho" → "1 dente de alho"). Usada tanto em
/// linha de ingrediente quanto de passo (pode repetir a quantidade, "misture
/// I xícara de farinha..."). Só troca a 1ª ocorrência achada na linha — uma
/// receita raramente tem duas quantidades erradas na mesma linha.
String fixOcrDigitLetterConfusion(
  String text, {
  List<SeedUnit> units = kSeedUnits,
}) {
  for (final m in _wordStart.allMatches(text)) {
    final tail = text.substring(m.start);
    final fixed = _fixOcrOneMisreadAsLetter(tail, units);
    if (fixed != tail) {
      return text.substring(0, m.start) + fixed;
    }
  }
  return text;
}

ParsedIngredientLine parseIngredientLine(
  String rawText, {
  List<SeedUnit> units = kSeedUnits,
  List<SeedNormalizerTerm>? normalizerTerms,
}) {
  final trimmed = rawText.trim();
  if (trimmed.isEmpty) {
    return ParsedIngredientLine(rawText: rawText, name: '');
  }

  var (quantity, afterQuantity) = _extractQuantity(
    _fixOcrOneMisreadAsLetter(trimmed, units),
  );
  var prefix = '';
  if (quantity == null) {
    // Não achou no início — tenta achar em qualquer ponto da linha (comum
    // em OCR, C8: "Farinha de trigo 1/4 xícara", quantidade no fim).
    final elsewhere = _extractQuantityAnywhere(trimmed, units);
    if (elsewhere != null) {
      quantity = elsewhere.quantity;
      prefix = elsewhere.before;
      afterQuantity = elsewhere.after;
    }
  }

  var (unitCode, afterUnit) = _matchUnit(afterQuantity, units);
  if (unitCode == null) {
    // Fração fala "de" antes da unidade ("1/4 DE xícara") — diferente do
    // "de" que liga unidade e nome ("xícara DE farinha"), já tratado
    // embaixo. Sem isso a unidade nunca casava e vazava pro nome.
    final (retryCode, retryAfter) =
        _matchUnit(_stripLeadingConnector(afterQuantity), units);
    if (retryCode != null) {
      unitCode = retryCode;
      afterUnit = retryAfter;
    }
  }
  final afterConnector = _stripLeadingConnector(afterUnit);
  final (qualifier, afterQualifier) = _extractQualifier(
    afterConnector,
    normalizerTerms ?? kSeedNormalizerTerms,
  );

  final rest = afterQualifier.trim();
  final name = [prefix, rest].where((s) => s.isNotEmpty).join(' ');
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

  m = _mixedAsciiFractionWithERegex.firstMatch(text);
  if (m != null) {
    final whole = int.parse(m.group(1)!);
    final num = int.parse(m.group(2)!);
    final den = int.parse(m.group(3)!);
    return (den == 0 ? null : whole + num / den, text.substring(m.end));
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

  m = _mixedUnicodeFractionWithERegex.firstMatch(text);
  if (m != null) {
    final whole = int.parse(m.group(1)!);
    return (whole + _fractionChars[m.group(2)!]!, text.substring(m.end));
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

final _wordStart = RegExp(r'\S+');

/// "1" vira "I", "l" ou (mais raro) "T" no OCR (C8) — em fonte sem serifa
/// ficam parecidos ou idênticos, e às vezes a letra ainda cola direto na
/// unidade ("Icolher") ou na fração ("T/4"). Só troca de volta quando o
/// resto da palavra, tirando essa letra, ainda parece continuação de
/// quantidade (unidade reconhecida logo depois, ou fração) — assim
/// "Iogurte"/"leite"/"laranja"/"Tâmaras" não viram "1ogurte"/"1eite"/
/// "1aranja"/"1âmaras" à toa.
const _ocrDigitLetters = {'I', 'l', 'T'};

final _quantityContinuation = RegExp(
  '^\\s*(e\\s+\\d|[/${_fractionChars.keys.join()}])',
);

String _fixLeadingLetterDigit(String text, List<SeedUnit> units) {
  if (text.isEmpty || !_ocrDigitLetters.contains(text[0])) return text;
  final rest = text.substring(1);
  final looksLikeQuantity = _quantityContinuation.hasMatch(rest) ||
      _matchUnit(rest.trimLeft(), units).$1 != null;
  return looksLikeQuantity ? '1$rest' : text;
}

/// Número misto ("1 e 1/4") perde o espaço entre o "1" e o "e" quando os
/// dois viram letra ("Ie l/4xícara") — sem tratar isso à parte, o "e" cola
/// no número seguinte e o "1 e" inteiro vaza pro nome do ingrediente em vez
/// de virar quantidade 1.25.
String _fixOcrOneMisreadAsLetter(String text, List<SeedUnit> units) {
  if (text.length >= 3 &&
      _ocrDigitLetters.contains(text[0]) &&
      text[1] == 'e' &&
      text[2] == ' ') {
    final fraction = _fixLeadingLetterDigit(text.substring(3), units);
    return '1 e $fraction';
  }
  return _fixLeadingLetterDigit(text, units);
}

/// Quantidade fora do início da linha — testa cada palavra como possível
/// começo de número (assim "1 / 4" com espaço na barra ainda casa inteiro,
/// já que a partir do "1" a mesma `_extractQuantity` consome "1 / 4"). Pega
/// a primeira que bater, senão devolve `null`.
({double quantity, String before, String after})? _extractQuantityAnywhere(
  String text,
  List<SeedUnit> units,
) {
  for (final m in _wordStart.allMatches(text)) {
    final fixed = _fixOcrOneMisreadAsLetter(text.substring(m.start), units);
    final (qty, after) = _extractQuantity(fixed);
    if (qty != null) {
      return (
        quantity: qty,
        before: text.substring(0, m.start).trim(),
        after: after,
      );
    }
  }
  return null;
}

(String?, String) _matchUnit(String text, List<SeedUnit> units) {
  final rest = text.trimLeft();
  final lowerRest = stripAccents(rest.toLowerCase());

  final candidates = <String, String>{};

  for (final u in units) {
    candidates[stripAccents(u.displayName.toLowerCase())] = u.code;
    candidates[stripAccents(u.plural.toLowerCase())] = u.code;
  }

  candidates.addAll(_unitSynonyms);

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
    if (lowerRest == c) return '';
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
      .map((t) => stripAccents(t.term.toLowerCase()))
      .toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final lowerText = stripAccents(text.toLowerCase());
  for (final term in qualifierTerms) {
    if (lowerText == term) continue;
    if (!lowerText.endsWith(term)) continue;
    final boundaryIndex = lowerText.length - term.length;
    if (boundaryIndex > 0 && lowerText[boundaryIndex - 1] == ' ') {
      return (
        text.substring(boundaryIndex).trim(),
        text.substring(0, boundaryIndex).trim(),
      );
    }
  }
  return (null, text);
}
