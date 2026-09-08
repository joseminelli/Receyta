import 'package:flutter/material.dart';
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

  test('os quatro módulos aparecem para ids diferentes', () {
    final seen = <TileMotif>{};
    for (var i = 0; i < 200; i++) {
      seen.add(tileMotifForId('recipe-$i'));
    }
    expect(seen, hasLength(TileMotif.values.length));
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
    expect(tilePatternCacheLength, TileMotif.values.length);

    await tester.fling(find.byType(ListView), const Offset(0, -3000), 1000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tilePatternCacheLength, TileMotif.values.length);
  });
}
