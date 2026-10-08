/// Equivalência de medidas (g ↔ xícara/colher, °C ↔ °F): só aritmética sobre
/// o que a receita já guarda, nada é gravado. Valores são aproximados.
library;

import 'package:receyta/data/database/seed_data.dart';
import 'package:receyta/domain/engine/ingredient_normalizer.dart';
import 'package:receyta/domain/engine/text_normalize.dart';

const _cupMl = 240.0;

/// Gramas em 1 xícara (240 ml) rasa, de tabelas de equivalência comuns.
const Map<String, double> _gramsPerCup = {
  'farinha de trigo': 120,
  'farinha de trigo integral': 120,
  'farinha de rosca': 110,
  'farinha de mandioca': 130,
  'farinha de amêndoas': 100,
  'amido de milho': 130,
  'fécula de batata': 140,
  'polvilho': 120,
  'fubá': 130,
  'aveia': 80,
  'açúcar': 180,
  'açúcar cristal': 200,
  'açúcar de confeiteiro': 120,
  'açúcar mascavo': 160,
  'sal': 280,
  'fermento em pó': 190,
  'bicarbonato de sódio': 220,
  'canela em pó': 125,
  'chocolate em pó': 90,
  'cacau em pó': 90,
  'achocolatado': 120,
  'coco ralado': 85,
  'parmesão': 100,
  'arroz': 190,
  'feijão': 190,
  'lentilha': 200,
  'grão de bico': 190,
  'amendoim': 150,
  'nozes': 110,
  'uva passa': 160,
  'manteiga': 220,
  'margarina': 220,
  'óleo': 216,
  'azeite': 216,
  'água': 240,
  'leite': 245,
  'leite em pó': 100,
  'leite condensado': 300,
  'leite de coco': 235,
  'creme de leite': 240,
  'iogurte': 245,
  'requeijão': 240,
  'ricota': 240,
  'maionese': 220,
  'mel': 340,
  'extrato de tomate': 260,
  'ketchup': 255,
  'molho de soja': 275,
  'vinagre': 240,
  'suco': 245,
};

typedef _Density = ({Set<String> tokens, double gPerMl});

/// Mais específico primeiro ("leite condensado" antes de "leite").
final List<_Density> _densities = () {
  final list = <_Density>[
    for (final e in _gramsPerCup.entries)
      (
        tokens: normalize(e.key).split(' ').where((t) => t.isNotEmpty).toSet(),
        gPerMl: e.value / _cupMl,
      ),
  ]..removeWhere((d) => d.tokens.isEmpty);
  list.sort((a, b) => b.tokens.length.compareTo(a.tokens.length));
  return list;
}();

final Map<String, SeedUnit> _unitByCode = {
  for (final u in kSeedUnits) u.code: u,
};

/// g/ml do ingrediente, ou `null` se não está na tabela. "Cozido" não casa:
/// arroz cozido não pesa o mesmo que o cru.
double? densityFor(String ingredientName) {
  if (stripAccents(ingredientName.toLowerCase()).contains('cozid')) return null;
  final tokens = normalize(ingredientName)
      .split(' ')
      .where((t) => t.isNotEmpty)
      .toSet();
  if (tokens.isEmpty) return null;
  for (final d in _densities) {
    if (tokens.containsAll(d.tokens)) return d.gPerMl;
  }
  return null;
}

/// "≈ 240 g" / "≈ ¾ xícara" / "≈ 240 ml" pra uma medida, ou `null` quando
/// não há equivalência útil (contagem, "a gosto", ml→ml, sem densidade).
String? equivalentMeasure({
  required double quantity,
  required String? unitId,
  required String name,
}) {
  final unit = unitId == null ? null : _unitByCode[unitId];
  if (unit == null || quantity <= 0) return null;
  final density = densityFor(name);
  final toBase = unit.factorToBase ?? 1;

  if (unit.kind == 'volume') {
    final ml = quantity * toBase;
    if (density != null) return '≈ ${_formatGrams(ml * density)}';
    if (unit.code == 'ml' || unit.code == 'l') return null;
    return '≈ ${_formatMl(ml)}';
  }
  if (unit.kind == 'mass' && density != null && unit.code != 'mg') {
    final text = _mlToSpoons(quantity * toBase / density);
    return text == null ? null : '≈ $text';
  }
  return null;
}

String _formatGrams(double g) {
  if (g >= 1000) return '${_fmt(g / 1000, 2)} kg';
  final r = g >= 100 ? (g / 5).round() * 5 : g.round();
  return '${r < 1 ? 1 : r} g';
}

String _formatMl(double ml) {
  if (ml >= 1000) return '${_fmt(ml / 1000, 2)} L';
  return '${ml.round()} ml';
}

String _fmt(double v, int decimals) {
  var s = v.toStringAsFixed(decimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// ml → xícara (≥ ¼), senão colher de sopa (≥ ¾ colher), senão colher de chá.
/// Acima de 10 xícaras ou abaixo de ¼ de colher de chá não vale a pena.
String? _mlToSpoons(double ml) {
  if (ml >= _cupMl / 4) {
    if (ml / _cupMl > 10) return null;
    return _withUnit(ml / _cupMl, 'xicara');
  }
  if (ml >= 11) return _withUnit(ml / 15, 'colher_sopa');
  if (ml >= 1.25) return _withUnit(ml / 5, 'colher_cha');
  return null;
}

String _withUnit(double amount, String code) {
  final q = _kitchenFraction(amount);
  final u = _unitByCode[code]!;
  return '${_fractionText(q)} ${q <= 1 ? u.displayName : u.plural}';
}

const _fractionGrid = [0.0, 0.25, 1 / 3, 0.5, 2 / 3, 0.75, 1.0];

/// Arredonda pra fração que se mede na cozinha (¼ ⅓ ½ ⅔ ¾).
double _kitchenFraction(double x) {
  final whole = x.floor();
  final frac = x - whole;
  var best = _fractionGrid.first;
  for (final f in _fractionGrid) {
    if ((f - frac).abs() < (best - frac).abs()) best = f;
  }
  final out = whole + best;
  return out < 0.25 ? 0.25 : out;
}

String _fractionText(double q) {
  const glyphs = [
    (0.25, '¼'),
    (1 / 3, '⅓'),
    (0.5, '½'),
    (2 / 3, '⅔'),
    (0.75, '¾'),
  ];
  final whole = q.floor();
  final frac = q - whole;
  String? g;
  for (final (value, glyph) in glyphs) {
    if ((frac - value).abs() < 0.01) g = glyph;
  }
  if (g == null) return '$whole';
  return whole == 0 ? g : '$whole $g';
}

final _temperature = RegExp(
  r'(\d{2,3})(?:\s*(?:a|à|-|–|—)\s*(\d{2,3}))?'
  r'(?:\s*[°º˚]\s*([CcFf])?(?![A-Za-zÀ-ÿ])'
  r'|\s+graus?(?:\s+(?:de\s+)?(celsius|fahrenheit|[CcFf])(?![A-Za-zÀ-ÿ]))?)',
  caseSensitive: false,
);
final _tempAfter = RegExp(r'^\s*[(/]?\s*(?:ou\s+)?\d{2,3}\s*[°º˚]');
final _tempBefore = RegExp(r'[°º˚]\s*[CcFf]?\s*[(/]\s*$');

/// Põe a outra escala ao lado de cada temperatura do texto: "180°C" →
/// "180°C (≈ 355 °F)". Não mexe se já houver a conversão escrita.
String annotateTemperatures(String text) {
  return text.replaceAllMapped(_temperature, (m) {
    final a = int.parse(m.group(1)!);
    final b = m.group(2) == null ? null : int.parse(m.group(2)!);
    final letter = (m.group(3) ?? m.group(4))?.toLowerCase();
    final isF = letter == null ? a > 320 : letter.startsWith('f');
    final lo = isF ? 90 : 30;
    final hi = isF ? 620 : 320;
    bool ok(int n) => n >= lo && n <= hi;
    if (!ok(a) || (b != null && !ok(b))) return m.group(0)!;
    if (_tempAfter.hasMatch(text.substring(m.end))) return m.group(0)!;
    if (_tempBefore.hasMatch(text.substring(0, m.start))) return m.group(0)!;

    String conv(int n) =>
        isF ? '${_round5((n - 32) * 5 / 9)}' : '${_round5(n * 9 / 5 + 32)}';
    final target = b == null ? conv(a) : '${conv(a)}–${conv(b)}';
    return '${m.group(0)} (≈ $target °${isF ? 'C' : 'F'})';
  });
}

int _round5(double v) => (v / 5).round() * 5;
