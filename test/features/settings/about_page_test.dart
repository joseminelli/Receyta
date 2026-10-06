import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/settings/screens/about_page.dart';
import 'package:receyta/theme/app_theme.dart';

void main() {
  testWidgets('mostra o app, o FAQ abre uma pergunta por vez', (tester) async {
    tester.view.physicalSize = const Size(1170, 7200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const AboutPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SOBRE O APP'), findsOneWidget);
    expect(find.text('Perguntas frequentes'), findsOneWidget);
    expect(find.textContaining('A conta é opcional'), findsNothing);

    await tester.tap(find.text('Preciso de conta para usar o Receyta?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A conta é opcional'), findsOneWidget);

    await tester.tap(find.text('Como apago meus dados?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('A conta é opcional'), findsNothing);
    expect(find.textContaining('Zona de risco'), findsOneWidget);
  });
}
