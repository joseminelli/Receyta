import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return ProviderScope(
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('começa como "não visto" e vira "visto" depois de marcado', () async {
    expect(await loadOnboardingSeen(), isFalse);
    await markOnboardingSeen();
    expect(await loadOnboardingSeen(), isTrue);
  });

  testWidgets('abertura, três recursos e final: Próximo avança até o tour',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Receitas do seu jeito'), findsOneWidget);
    await tester.tap(find.text('Vamos lá'));
    await tester.pumpAndSettle();
    expect(find.text('Suas receitas, num lugar só'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Planeje a semana'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Compras sem conta de cabeça'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Tudo pronto!'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);

    await tester.tap(find.text('Começar o tour'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(await loadOnboardingSeen(), isTrue);
  });

  testWidgets('"Agora não" vai pra home e marca visto', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text(i == 0 ? 'Vamos lá' : 'Próximo'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Agora não, entrar no app'));
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
