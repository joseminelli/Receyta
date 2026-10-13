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
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const c = AppColors.dark;

  final text = <String, (Color, Color)>{
    'onPaper sobre paper': (c.onPaper, c.paper),
    'onPaper sobre paperSoft': (c.onPaper, c.paperSoft),
    'textBody sobre paper': (c.textBody, c.paper),
    'textBody sobre paperSoft': (c.textBody, c.paperSoft),
    'textMuted sobre paper': (c.textMuted, c.paper),
    'textMuted sobre paperSoft': (c.textMuted, c.paperSoft),
    'lime sobre ink': (c.lime, c.ink),
    'lime sobre inkSoft': (c.lime, c.inkSoft),
    'onSaturated sobre ink': (c.onSaturated, c.ink),
    'onSaturated sobre inkSoft': (c.onSaturated, c.inkSoft),
    'onInk sobre ink': (c.onInk, c.ink),
    'ink sobre lime': (c.ink, c.lime),
    'onSaturated sobre violet': (c.onSaturated, c.violet),
    'danger sobre paper': (c.danger, c.paper),
  };

  group('tema escuro: texto legível nos pares usados no app (AA, 4,5:1)', () {
    for (final entry in text.entries) {
      test(entry.key, () {
        expect(
          _ratio(entry.value.$1, entry.value.$2),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  test('branco sobre coral passa em texto grande (3:1)', () {
    expect(_ratio(c.onSaturated, c.coral), greaterThanOrEqualTo(3));
  });

  test('ink continua um bloco escuro, mais fundo que o paper', () {
    expect(_luminance(c.ink), lessThan(_luminance(c.paper)));
    expect(_luminance(c.ink), lessThan(0.05));
  });

  test('onPaper e onInk são claros, ao contrário do tema claro', () {
    expect(_luminance(c.onPaper), greaterThan(0.8));
    expect(_luminance(c.onInk), greaterThan(0.8));
  });

  test('no tema claro onPaper é o próprio ink e onInk o próprio paper', () {
    const l = AppColors.light;
    expect(l.onPaper, l.ink);
    expect(l.onInk, l.paper);
    const h = AppColors.highContrast;
    expect(h.onPaper, h.ink);
    expect(h.onInk, h.paper);
  });
}
