import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/services/app_info.dart';
import 'package:receyta/features/settings/screens/feedback_sheet.dart';
import 'package:receyta/theme/app_theme.dart';

class _FakeFeedback extends FeedbackService {
  final sent = <({String message, String category, String version})>[];

  @override
  Future<void> send({
    required String message,
    String category = '',
    String version = '',
  }) async {
    sent.add((message: message, category: category, version: version));
  }
}

void main() {
  group('composeFeedback', () {
    test('junta categoria, mensagem e versão', () {
      final text = composeFeedback(
        message: '  Adorei o modo cozinha  ',
        category: 'Elogio',
        version: '1.0.0 (3)',
      );

      expect(text, '[Elogio]\n\nAdorei o modo cozinha\n\n—\nReceyta 1.0.0 (3)');
    });

    test('sem categoria nem versão, só a mensagem e a assinatura', () {
      expect(composeFeedback(message: 'Oi'), 'Oi\n\n—\nReceyta');
    });
  });

  group('folha de feedback', () {
    late _FakeFeedback fake;

    Widget host() => ProviderScope(
          overrides: [feedbackServiceProvider.overrideWithValue(fake)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showFeedbackSheet(context, version: '1.0.0'),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        );

    setUp(() => fake = _FakeFeedback());

    testWidgets('não deixa enviar vazio', (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(fake.sent, isEmpty);
    });

    testWidgets('envia o que a pessoa escreveu, com o tipo escolhido',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Problema'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'O timer não toca');
      await tester.pump();
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(fake.sent, hasLength(1));
      expect(fake.sent.single.message, 'O timer não toca');
      expect(fake.sent.single.category, 'Problema');
      expect(fake.sent.single.version, '1.0.0');
      expect(find.text('Enviar feedback'), findsNothing);
    });
  });
}
