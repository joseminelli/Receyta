import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:receyta/features/recipes/screens/global_timers_bar.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_alarm_driver.dart';
import '../../helpers/fake_timer_notifications.dart';

DateTime _now = DateTime.utc(2026, 10, 1, 12);
final _opened = <String>[];

/// Como o `main.dart` monta: a faixa no `builder`, por cima do `Navigator`.
Widget _host() => ProviderScope(
      overrides: [
        cookingClockProvider.overrideWithValue(() => _now),
        cookingAlertProvider.overrideWithValue(() {}),
        alarmDriverProvider.overrideWithValue(_driver),
        timerNotificationsProvider.overrideWithValue(_notifications),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => GlobalTimersBar(
          onOpenRecipe: _opened.add,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Text(
              'topo=${MediaQuery.paddingOf(context).top}',
            ),
          ),
        ),
      ),
    );

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold)));

CookingTimersNotifier _timers(WidgetTester tester) =>
    _container(tester).read(cookingTimersProvider.notifier);

/// Desmonta: o `ProviderScope` descarta o notifier e cancela o relógio de 1 s.
Future<void> _close(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

final _driver = FakeAlarmDriver();
final _notifications = FakeTimerNotifications();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _now = DateTime.utc(2026, 10, 1, 12);
    _opened.clear();
    _driver.calls.clear();
    _notifications.calls.clear();
    _notifications.runningDetails.clear();
    _notifications.tapCallback = null;
  });

  testWidgets('sem timers não há faixa e a tela mantém o topo seguro',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 72); // 24 lógicos
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.text('topo=24.0'), findsOneWidget);
  });

  testWidgets('com timer: faixa no topo com receita, passo e relógio',
      (tester) async {
    tester.view.padding = const FakeViewPadding(top: 72);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_host());

    _timers(tester).start(
      recipeId: 'r1',
      recipeName: 'Frango ao curry',
      label: 'Passo 2',
      duration: const Duration(minutes: 20),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frango ao curry · Passo 2'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    // A faixa já cobre a barra de status: a tela de baixo perde o topo seguro.
    expect(find.text('topo=0.0'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('relógio anda, pausa e retoma pela faixa', (tester) async {
    await tester.pumpWidget(_host());
    _timers(tester).start(
      recipeId: 'r1',
      label: 'Cozimento',
      duration: const Duration(minutes: 10),
    );
    await tester.pumpAndSettle();

    _now = _now.add(const Duration(minutes: 3));
    _timers(tester).tick();
    await tester.pump();
    expect(find.text('07:00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.byIcon(Icons.pause), findsOneWidget);
    await _close(tester);
  });

  testWidgets('tocar no timer abre o modo cozinha da receita', (tester) async {
    await tester.pumpWidget(_host());
    _timers(tester).start(
      recipeId: 'r7',
      recipeName: 'Bolo',
      label: 'Cozimento',
      duration: const Duration(minutes: 40),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bolo · Cozimento'));
    await tester.pump();

    expect(_opened, ['r7']);
    await _close(tester);
  });

  testWidgets('esconde os timers da receita cujo modo cozinha está aberto',
      (tester) async {
    await tester.pumpWidget(_host());
    final timers = _timers(tester);
    timers.start(
      recipeId: 'r1',
      recipeName: 'Frango',
      label: 'Passo 1',
      duration: const Duration(minutes: 5),
    );
    timers.start(
      recipeId: 'r2',
      recipeName: 'Bolo',
      label: 'Passo 3',
      duration: const Duration(minutes: 9),
    );
    await tester.pumpAndSettle();
    expect(find.text('Frango · Passo 1'), findsOneWidget);
    expect(find.text('Bolo · Passo 3'), findsOneWidget);

    _container(tester).read(cookingModeRecipeIdProvider.notifier).state = 'r1';
    await tester.pumpAndSettle();
    expect(find.text('Frango · Passo 1'), findsNothing);
    expect(find.text('Bolo · Passo 3'), findsOneWidget);

    _container(tester).read(cookingModeRecipeIdProvider.notifier).state = null;
    await tester.pumpAndSettle();
    expect(find.text('Frango · Passo 1'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('ao acabar vira "Pronto!"; Parar tira a faixa', (tester) async {
    await tester.pumpWidget(_host());
    _timers(tester).start(
      recipeId: 'r1',
      recipeName: 'Frango',
      label: 'Passo 2',
      duration: const Duration(minutes: 1),
    );
    await tester.pumpAndSettle();

    _now = _now.add(const Duration(minutes: 2));
    _timers(tester).tick();
    await tester.pump();

    expect(find.text('Frango · Passo 2 · Pronto!'), findsOneWidget);
    expect(find.byIcon(Icons.replay), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.textContaining('Passo 2'), findsNothing);
    await _close(tester);
  });

  testWidgets('chaves de vibrar e som: som começa desligado e em vermelho',
      (tester) async {
    await tester.pumpWidget(_host());
    _timers(tester).start(
      recipeId: 'r1',
      label: 'Cozimento',
      duration: const Duration(minutes: 5),
    );
    await tester.pumpAndSettle();

    CookingAlertSettings settings() =>
        _container(tester).read(cookingAlertSettingsProvider);
    Color? colorOf(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;

    // Padrão: vibra, não toca. Ligado em lime, desligado em vermelho.
    expect(settings().vibrate, isTrue);
    expect(settings().sound, isFalse);
    expect(find.byIcon(Icons.vibration), findsOneWidget);
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(colorOf(Icons.vibration), AppColors.light.lime);
    expect(colorOf(Icons.volume_off), AppColors.light.danger);

    // Ligar o som: amostra, ícone muda e deixa de ser vermelho.
    await tester.tap(find.byIcon(Icons.volume_off));
    await tester.pump();
    expect(settings().sound, isTrue);
    expect(_driver.calls, ['previewSound']);
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
    expect(colorOf(Icons.volume_up), AppColors.light.lime);

    // Desligar a vibração: o ícone fica vermelho e a vibração corta na hora.
    _driver.calls.clear();
    await tester.tap(find.byIcon(Icons.vibration));
    await tester.pump();
    expect(settings().vibrate, isFalse);
    expect(_driver.calls, ['stopVibration']);
    expect(colorOf(Icons.phone_android), AppColors.light.danger);

    // Desligar o som de novo: volta ao vermelho e o som corta na hora.
    _driver.calls.clear();
    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(settings().sound, isFalse);
    expect(_driver.calls, ['stopSound']);
    expect(colorOf(Icons.volume_off), AppColors.light.danger);
    await _close(tester);
  });

  group('largura do nome na pílula (responsiva)', () {
    test('um timer: ganha o que sobra, entre o mínimo e o teto', () {
      double w(double bar) => pillTitleWidth(barWidth: bar, timerCount: 1);
      expect(w(320), 80); // celular pequeno: sobra pouco
      expect(w(360), 120);
      expect(w(390), 150);
      expect(w(700), 240); // tablet: teto
      expect(w(200), 72); // absurdo: mínimo legível
    });

    test('vários timers: nome mais curto, a faixa rola', () {
      double w(double bar) => pillTitleWidth(barWidth: bar, timerCount: 3);
      expect(w(360), 120);
      expect(w(390), 140); // teto menor
      expect(w(700), 140);
    });

    test('cresce junto com a tela, nunca diminui ao alargar', () {
      var last = 0.0;
      for (var bar = 280.0; bar <= 800; bar += 20) {
        final w = pillTitleWidth(barWidth: bar, timerCount: 1);
        expect(w, greaterThanOrEqualTo(last));
        last = w;
      }
    });
  });

  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets(
        'com um timer a pílula termina antes da margem direita '
        '(tela de ${width.toInt()} px)', (tester) async {
      tester.view.physicalSize = Size(width * 3, 1800);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host());
      _timers(tester).start(
        recipeId: 'r1',
        recipeName: 'Frango ao curry com legumes e arroz',
        label: 'Cozimento',
        duration: const Duration(minutes: 25),
      );
      await tester.pumpAndSettle();

      final pill = find.ancestor(
        of: find.byIcon(Icons.pause),
        matching: find.byType(Container),
      );
      final right = tester.getRect(pill.first).right;
      expect(
        right,
        lessThanOrEqualTo(width - AppSpacing.screen + 0.5),
        reason: 'a pílula passou da margem direita em ${width.toInt()} px',
      );
      await _close(tester);
    });
  }

  group('app minimizado', () {
    testWidgets('minimizar vira notificação; voltar tira', (tester) async {
      await tester.pumpWidget(_host());
      _timers(tester).start(
        recipeId: 'r1',
        recipeName: 'Frango',
        label: 'Passo 2',
        duration: const Duration(minutes: 20),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(_notifications.calls.where((c) => c.startsWith('running:')),
          hasLength(1)); // só uma vez, mesmo com hidden + paused

      _notifications.calls.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(_notifications.calls.where((c) => c.startsWith('cancel:')),
          hasLength(1));
      await _close(tester);
    });

    testWidgets('inactive (gaveta de notificações, diálogo) não minimiza',
        (tester) async {
      await tester.pumpWidget(_host());
      _timers(tester).start(
        recipeId: 'r1',
        label: 'x',
        duration: const Duration(minutes: 5),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(
          _notifications.calls.where((c) => c.startsWith('running:')), isEmpty);
      await _close(tester);
    });

    testWidgets('tocar numa notificação abre o modo cozinha da receita',
        (tester) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      expect(_notifications.calls, contains('init'));
      _notifications.tapCallback!('r42');
      expect(_opened, ['r42']);
    });
  });
}
