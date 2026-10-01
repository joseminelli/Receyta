import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/theme/tokens.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  const c = AppColors.highContrast;

  final pairs = <String, (Color, Color)>{
    'ink sobre paper': (c.ink, c.paper),
    'textBody sobre paper': (c.textBody, c.paper),
    'textBody sobre paperSoft': (c.textBody, c.paperSoft),
    'textMuted sobre paper': (c.textMuted, c.paper),
    'textMuted sobre paperSoft': (c.textMuted, c.paperSoft),
    'ink sobre paperSoft': (c.ink, c.paperSoft),
    'onSaturated sobre coral': (c.onSaturated, c.coral),
    'onSaturated sobre violet': (c.onSaturated, c.violet),
    'coralMuted sobre coral': (c.coralMuted, c.coral),
    'violetMuted sobre violet': (c.violetMuted, c.violet),
    'ink sobre lime': (c.ink, c.lime),
    'lime sobre ink': (c.lime, c.ink),
    'lime sobre inkSoft': (c.lime, c.inkSoft),
    'onSaturated sobre ink': (c.onSaturated, c.ink),
    'danger sobre paper': (c.danger, c.paper),
    'danger sobre paperSoft': (c.danger, c.paperSoft),
    'onSaturated sobre danger': (c.onSaturated, c.danger),
  };

  group('alto contraste passa em AA (4,5:1) nos pares usados no app', () {
    for (final entry in pairs.entries) {
      test(entry.key, () {
        expect(_ratio(entry.value.$1, entry.value.$2), greaterThanOrEqualTo(4.5));
      });
    }
  });

  test('o alto contraste é mais forte que o tema padrão no texto apagado', () {
    expect(
      _ratio(c.textMuted, c.paper),
      greaterThan(_ratio(AppColors.light.textMuted, AppColors.light.paper)),
    );
  });
}
