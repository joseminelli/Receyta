import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/folder_tile.dart';
import 'package:receyta/widgets/tile_pattern.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: SizedBox(width: 120, child: child))),
    );

void main() {
  testWidgets('mostra contagem e rótulo', (tester) async {
    await tester.pumpWidget(
      _host(const FolderTile(label: 'Semana', count: 12, motif: TileMotif.meiaLua)),
    );
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
    expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
  });

  testWidgets('tile neutro usa reticências', (tester) async {
    await tester.pumpWidget(
      _host(const FolderTile(label: 'Pastas', count: 9)),
    );
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    expect(find.byType(TilePattern), findsNothing);
  });
}
