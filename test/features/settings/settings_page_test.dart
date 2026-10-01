import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/screens/settings_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host({AppSettings initial = const AppSettings()}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const Text('ROTA WELCOME')),
      GoRoute(path: '/tags', builder: (_, __) => const Text('ROTA TAGS')),
    ],
  );
  return ProviderScope(
    overrides: [initialAppSettingsProvider.overrideWithValue(initial)],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('as preferências voltam do disco como foram salvas', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appSettingsProvider.notifier);

    await notifier.setTextSize(TextSizeStep.larger);
    await notifier.setHighContrast(true);
    final at = DateTime(2026, 10, 1, 9, 30);
    await notifier.markBackedUp(at);

    final loaded = await loadAppSettings();
    expect(loaded.textSize, TextSizeStep.larger);
    expect(loaded.highContrast, isTrue);
    expect(loaded.lastBackupAt, at);
  });

  test('sem nada salvo, vale o padrão', () async {
    final loaded = await loadAppSettings();
    expect(loaded, const AppSettings());
  });

  testWidgets('mostra as seções e o aviso de que ainda não há backup',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('APARÊNCIA'), findsOneWidget);
    expect(find.text('TIMERS DO MODO COZINHA'), findsOneWidget);
    expect(find.text('SEUS DADOS'), findsOneWidget);
    expect(find.text('ZONA DE RISCO'), findsOneWidget);
    expect(find.text('Você ainda não fez backup'), findsOneWidget);
  });

  testWidgets('mostra a data do último backup quando há', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host(initial: AppSettings(lastBackupAt: DateTime(2026, 9, 12, 8, 5))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Último: 12/09/2026 às 08:05'), findsOneWidget);
  });

  testWidgets('escolher um tamanho de texto atualiza a configuração',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Normal'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Texto Maior'));
    await tester.pumpAndSettle();

    expect(find.text('Maior'), findsOneWidget);
  });

  testWidgets('o interruptor de alto contraste liga e desliga', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    final finder = find.byType(Switch).first;
    expect(tester.widget<Switch>(finder).value, isFalse);

    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(finder).value, isTrue);
  });

  testWidgets('"Ver a introdução de novo" leva às boas-vindas', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver a introdução de novo'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA WELCOME'), findsOneWidget);
  });
}
