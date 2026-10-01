import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/features/onboarding/controllers/onboarding_seen.dart';
import 'package:receyta/features/onboarding/screens/welcome_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host() {
  final router = GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomePage()),
      GoRoute(path: '/', builder: (_, __) => const Text('HOME')),
    ],
  );
  return MaterialApp.router(theme: AppTheme.light(), routerConfig: router);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('começa como "não visto" e vira "visto" depois de marcado', () async {
    expect(await loadOnboardingSeen(), isFalse);
    await markOnboardingSeen();
    expect(await loadOnboardingSeen(), isTrue);
  });

  testWidgets('três telas: Próximo avança e Começar leva à home e marca visto',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Suas receitas, num lugar só'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Planeje a semana'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Compras sem conta de cabeça'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(await loadOnboardingSeen(), isTrue);
  });

  testWidgets('Pular vai direto pra home e marca visto', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(await loadOnboardingSeen(), isTrue);
  });
}
