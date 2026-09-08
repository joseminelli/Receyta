import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/splash.dart';
import 'package:receyta/theme/app_theme.dart';

Widget _host(Splash splash) => MaterialApp(theme: AppTheme.light(), home: splash);

void main() {
  test('o orçamento de abertura fecha em 1,8s', () {
    expect(
      SplashTimings.intro + SplashTimings.outro,
      lessThanOrEqualTo(SplashTimings.budget),
    );
  });

  testWidgets('start quente: intro → outro → onComplete dentro do orçamento',
      (tester) async {
    var done = false;
    await tester.pumpWidget(_host(Splash(
      ready: Future<void>.value(),
      onComplete: () => done = true,
    )));

    // Durante a intro não termina.
    await tester.pump(const Duration(milliseconds: 800));
    expect(done, isFalse);

    // intro (1150) + outro (600) + folga de frame.
    await tester.pump(SplashTimings.intro);
    await tester.pump(SplashTimings.outro);
    await tester.pump(const Duration(milliseconds: 16));

    expect(done, isTrue);
  });

  testWidgets('app lento: segura a saída até `ready` resolver', (tester) async {
    final ready = Completer<void>();
    var done = false;
    await tester.pumpWidget(_host(Splash(
      ready: ready.future,
      onComplete: () => done = true,
    )));

    // Passou da intro, mas `ready` ainda não resolveu → não sai.
    await tester.pump(SplashTimings.intro);
    await tester.pump(const Duration(seconds: 3));
    expect(done, isFalse);

    ready.complete();
    await tester.pumpAndSettle();

    expect(done, isTrue);
  });

  testWidgets('pinta sem lançar em qualquer ponto da animação', (tester) async {
    await tester.pumpWidget(_host(Splash(
      ready: Future<void>.value(),
      onComplete: () {},
    )));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.takeException(), isNull);
    }
  });
}
