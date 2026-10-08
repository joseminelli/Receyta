import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/screens/recipe_ocr_flow.dart';
import 'package:receyta/theme/app_theme.dart';

void main() {
  testWidgets('o aviso diz que letra de mão (cursiva) não é lida',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: OcrHandwritingNote()),
    ));

    expect(find.textContaining('texto impresso'), findsOneWidget);
    expect(find.textContaining('cursiva'), findsOneWidget);
    expect(find.byIcon(Icons.draw_outlined), findsOneWidget);
  });
}
