import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/widgets/tile_pattern.dart';

void main() {
  setUp(clearTilePatternCache);
  tearDown(clearTilePatternCache);

  test('tileMotifForId é determinístico e estável', () {
    for (final id in ['recipe-1', 'abc', 'Frango ao curry', '']) {
      expect(tileMotifForId(id), tileMotifForId(id));
    }
  });

  test('os quatro módulos originais aparecem para ids diferentes', () {
    final seen = <TileMotif>{};
    for (var i = 0; i < 200; i++) {
      seen.add(tileMotifForId('recipe-$i'));
    }
    expect(seen, kBaseTileMotifs.toSet());
  });

  test('a escolha automática nunca sorteia um módulo opcional', () {
    for (var i = 0; i < 500; i++) {
      expect(tileMotifForId('receita-$i').isExtra, isFalse);
    }
  });

  test('a estampa automática das receitas existentes não mudou', () {
    // Valores fixados antes dos módulos opcionais existirem: se mudarem, toda
    // receita sem textura escolhida trocaria de desenho.
    const ids = ['recipe-1', 'abc', 'Frango ao curry', 'bolo', 'x'];
    for (final id in ids) {
      expect(
        tileMotifForId(id),
        TileMotif.values[id.hashCode.abs() % 4],
        reason: id,
      );
    }
  });

  testWidgets('cada módulo pinta sem lançar', (tester) async {
    for (final motif in TileMotif.values) {
      await tester.pumpWidget(
        Center(
          child: SizedBox(
            width: 200,
            height: 120,
            child: TilePattern(
              motif: motif,
              background: const Color(0xFFFF5A38),
              patternColor: const Color(0xFFFF7A5E),
              patternColorAlt: const Color(0xFF37362A),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('60 cards com 4 módulos rasterizam só 4 tiles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 60,
            itemBuilder: (_, i) => SizedBox(
              height: 128,
              child: TilePattern(
                motif: tileMotifForId('recipe-$i'),
                background: const Color(0xFFFF5A38),
                patternColor: const Color(0xFFFF7A5E),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Um tile por (módulo, cor, tile, dpr). Cor/tile/dpr são fixos aqui, então
    // o cache estabiliza no número de módulos — não cresce com o scroll.
    expect(tilePatternCacheLength, kBaseTileMotifs.length);

    await tester.fling(find.byType(ListView), const Offset(0, -3000), 1000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tilePatternCacheLength, kBaseTileMotifs.length);
  });

  testWidgets('cada módulo desenha algo visível, sem cobrir o bloco inteiro',
      (tester) async {
    const bg = Color(0xFF204060);
    const fg = Color(0xFFE0C080);
    for (final motif in TileMotif.values) {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 120,
                height: 120,
                child: TilePattern(
                  motif: motif,
                  background: bg,
                  patternColor: fg,
                  // A diagonal pinta as duas metades; com o segundo tom igual
                  // ao fundo só uma aparece, como nos outros módulos.
                  patternColorAlt: bg,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final bytes = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        return data!.buffer.asUint8List();
      }) as Uint8List;

      var painted = 0;
      for (var i = 0; i < bytes.length; i += 4) {
        // Mais perto do padrão que do fundo (canal vermelho: 0xE0 vs 0x20).
        if (bytes[i] > 0x80) painted++;
      }
      final share = painted / (bytes.length / 4);
      expect(share, greaterThan(0.03), reason: '${motif.name} não desenhou');
      expect(share, lessThan(0.85), reason: '${motif.name} cobriu tudo');
    }
  });
}
