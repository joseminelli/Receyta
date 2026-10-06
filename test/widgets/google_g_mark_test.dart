import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/widgets/google_g_mark.dart';

void main() {
  testWidgets(
      'desenha o G no tamanho pedido, sem anunciar nada ao leitor de tela',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: GoogleGMark(size: 30))),
    );

    expect(tester.getSize(find.byType(GoogleGMark)), const Size.square(30));
    expect(find.bySemanticsLabel(RegExp('G')), findsNothing);
  });
}
