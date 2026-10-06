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

  testWidgets('texturas: as quatro originais e, à parte, as opcionais',
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

    expect(find.text('TEXTURA'), findsOneWidget);
    expect(find.text('MAIS TEXTURAS'), findsOneWidget);
    for (final m in TileMotif.values) {
      expect(find.bySemanticsLabel('Textura ${m.label}'), findsOneWidget,
          reason: m.name);
    }
  });

  testWidgets('tocar numa textura opcional escolhe ela e mantém a cor',
      (tester) async {
    TileColor? pickedColor;
    TileMotif? pickedMotif;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: TileStylePicker(
            color: TileColor.mar,
            motif: null,
            onChanged: (c, m) {
              pickedColor = c;
              pickedMotif = m;
            },
          ),
        ),
      ),
    ));

    await tester.tap(find.bySemanticsLabel('Textura Onda'));
    await tester.pump();

    expect(pickedMotif, TileMotif.onda);
    expect(pickedColor, TileColor.mar);
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

  testWidgets('folha de aparência rola em tela baixa até a última textura',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    TileMotif? picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppearanceSheet(
              context,
              title: 'Aparência',
              color: null,
              motif: null,
              fallbackColor: TileColor.coral,
              onChanged: (_, m) => picked = m,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Textura Círculos'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.bySemanticsLabel('Textura Círculos'));
    await tester.pump();

    expect(picked, TileMotif.circulo);
  });
}
