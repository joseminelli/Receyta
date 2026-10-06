import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_appearance.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test(
      'as quatro cores do app e as opcionais cobrem o enum inteiro, sem repetir',
      () {
    final all = [...kBaseTileColors, ...kExtraTileColors];

    expect(all.toSet(), TileColor.values.toSet());
    expect(all.length, TileColor.values.length);
    expect(kBaseTileColors.every((c) => !c.isExtra), isTrue);
    expect(kExtraTileColors.every((c) => c.isExtra), isTrue);
  });

  test('os nomes guardados no banco continuam voltando ao mesmo valor', () {
    for (final c in TileColor.values) {
      expect(tileColorFromName(c.name), c);
    }
    expect(tileColorFromName('azul_inventado'), isNull);
    expect(tileColorFromName(null), isNull);
  });

  test('as quatro cores do app não mudaram', () {
    const c = AppColors.light;

    expect(
        resolveTileAppearance(c, color: TileColor.coral).background, c.coral);
    expect(
        resolveTileAppearance(c, color: TileColor.violet).background, c.violet);
    expect(resolveTileAppearance(c, color: TileColor.ink).background, c.ink);
    expect(resolveTileAppearance(c, color: TileColor.lime).background, c.lime);
    expect(resolveTileAppearance(c, color: TileColor.lime).onColor, c.ink);
    expect(resolveTileAppearance(c, color: TileColor.coral).onColor,
        c.onSaturated);
  });

  test('toda cor tem fundo, padrão e texto, e o padrão difere do fundo', () {
    for (final colors in [AppColors.light, AppColors.highContrast]) {
      for (final c in TileColor.values) {
        final t = resolveTileAppearance(colors, color: c);
        expect(t.background, isNot(t.patternColor), reason: c.name);
        expect(t.onColor, anyOf(colors.ink, colors.onSaturated));
        expect(t.motif, isNotNull);
      }
    }
  });

  test('cores opcionais: texto legível no modo normal (≥ 3:1, texto grande)',
      () {
    for (final c in kExtraTileColors) {
      final t = resolveTileAppearance(AppColors.light, color: c);
      expect(_ratio(t.onColor, t.background), greaterThanOrEqualTo(3.0),
          reason: c.name);
    }
  });

  test('cores opcionais: alto contraste passa de 4,5:1 (AA)', () {
    for (final c in kExtraTileColors) {
      final t = resolveTileAppearance(AppColors.highContrast, color: c);
      expect(_ratio(t.onColor, t.background), greaterThanOrEqualTo(4.5),
          reason: c.name);
    }
  });

  test('alto contraste aprofunda as opcionais em vez de repetir o tom normal',
      () {
    final normal =
        resolveTileAppearance(AppColors.light, color: TileColor.mar).background;
    final strong =
        resolveTileAppearance(AppColors.highContrast, color: TileColor.mar)
            .background;

    expect(strong, isNot(normal));
  });

  test('só a cor, sem textura: cada opcional ganha uma textura de par', () {
    final motifs = {
      for (final c in kExtraTileColors)
        resolveTileAppearance(AppColors.light, color: c).motif,
    };

    expect(motifs.length, greaterThan(1));
  });

  test('mostarda usa texto escuro, como a lima', () {
    final t = resolveTileAppearance(AppColors.light, color: TileColor.mostarda);

    expect(t.onColor, AppColors.light.ink);
  });
}
