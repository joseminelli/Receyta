import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_style_picker.dart';

void main() {
  testWidgets('mostra as quatro cores do app e, à parte, as opcionais',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TileStylePicker(
            color: null,
            motif: null,
            onChanged: (_, __) {},
          ),
        ),
      ),
    ));

    expect(find.text('COR'), findsOneWidget);
    expect(find.text('MAIS CORES'), findsOneWidget);
    for (final c in TileColor.values) {
      expect(find.bySemanticsLabel('Cor ${c.label}'), findsOneWidget,
          reason: c.name);
    }
  });

  testWidgets('tocar numa cor opcional escolhe ela e mantém a textura',
      (tester) async {
    TileColor? pickedColor;
    TileMotif? pickedMotif;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TileStylePicker(
            color: TileColor.coral,
            motif: TileMotif.ponto,
            onChanged: (c, m) {
              pickedColor = c;
              pickedMotif = m;
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.bySemanticsLabel('Cor Mar'));
    await tester.pump();

    expect(pickedColor, TileColor.mar);
    expect(pickedMotif, TileMotif.ponto);
  });
}
