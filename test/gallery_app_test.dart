import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/gallery_app.dart';

void main() {
  Future<Finder> revealTile(WidgetTester tester, String title) async {
    final finder = find.text(title);
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    return finder;
  }

  testWidgets('índice lista todas as entradas registradas', (tester) async {
    await tester.pumpWidget(const GalleryApp());

    expect(find.text('Galeria'), findsOneWidget);
    for (final entry in galleryEntries) {
      expect(await revealTile(tester, entry.title), findsOneWidget,
          reason: 'entrada "${entry.title}" sumiu do índice');
    }
  });

  testWidgets('cada entrada abre uma página própria e volta', (tester) async {
    await tester.pumpWidget(const GalleryApp());

    for (final entry in galleryEntries) {
      await tester.tap(await revealTile(tester, entry.title));
      await tester.pumpAndSettle();

      // AppBar da página.
      expect(find.text(entry.title), findsWidgets);
      // Páginas normais repetem o blurb no corpo; as `expand` ocupam a tela.
      if (!entry.expand) {
        expect(find.text(entry.blurb), findsOneWidget);
      }

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('o botão Tema alterna claro/escuro', (tester) async {
    await tester.pumpWidget(const GalleryApp());

    Brightness brightnessOf() => Theme.of(
          tester.element(find.text('Galeria')),
        ).brightness;

    expect(brightnessOf(), Brightness.light);

    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    expect(brightnessOf(), Brightness.dark);
  });
}
