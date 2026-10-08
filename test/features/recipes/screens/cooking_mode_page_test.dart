import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/features/recipes/screens/cooking_mode_page.dart';
import 'package:receyta/data/services/alarm_driver.dart';
import 'package:receyta/data/services/timer_notifications.dart';
import 'package:receyta/features/recipes/controllers/cooking_timers.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/sweep_strike_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_alarm_driver.dart';
import '../../../helpers/fake_timer_notifications.dart';

RecipeDetail _detail({List<RecipeStep> steps = _steps, int? cook}) =>
    RecipeDetail(
      recipe: Recipe(
        id: 'r1',
        name: 'Frango ao curry',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        cookMinutes: cook,
        servings: 4,
      ),
      ingredients: const [
        RecipeIngredient(
          id: 'i1',
          recipeId: 'r1',
          rawText: '500g de frango',
          position: 0,
          quantity: 500,
          unitId: 'g',
        ),
        RecipeIngredient(
            id: 'i2',
            recipeId: 'r1',
            rawText: '400ml de leite de coco',
            position: 1),
      ],
      steps: steps,
    );

const _steps = [
  RecipeStep(id: 's1', recipeId: 'r1', text: 'Tempere o frango', position: 0),
  RecipeStep(id: 's2', recipeId: 'r1', text: 'Refogue o alho', position: 1),
  RecipeStep(
      id: 's3', recipeId: 'r1', text: 'Junte o leite de coco', position: 2),
];

Widget _host(RecipeDetail? detail, {DateTime Function()? clock}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/cook'),
              child: const Text('ir'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/cook',
        builder: (_, __) => const CookingModePage(recipeId: 'r1'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeDetailProvider.overrideWith((ref, id) => Stream.value(detail)),
      if (clock != null) cookingClockProvider.overrideWithValue(clock),
      // Sem vibrar nem tocar nada de verdade no teste.
      cookingAlertProvider.overrideWithValue(() {}),
      alarmDriverProvider.overrideWithValue(_driver),
      timerNotificationsProvider.overrideWithValue(_notifications),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

Future<void> _open(
  WidgetTester tester,
  RecipeDetail? detail, {
  DateTime Function()? clock,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(detail, clock: clock));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ir'));
  await tester.pumpAndSettle();
}

final _driver = FakeAlarmDriver();
final _notifications = FakeTimerNotifications();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('lista todos os passos e os ingredientes de cara',
      (tester) async {
    await _open(tester, _detail());

    expect(find.text('Tempere o frango'), findsOneWidget);
    expect(find.text('Refogue o alho'), findsOneWidget);
    expect(find.text('Junte o leite de coco'), findsOneWidget);
    // Ingredientes abertos por padrão.
    expect(find.text('500g de frango'), findsOneWidget);
  });

  testWidgets('porções: "+" refaz as quantidades e "-" volta ao texto original',
      (tester) async {
    await _open(tester, _detail());

    await tester.tap(find.byTooltip('Mais uma porção'));
    await tester.pumpAndSettle();
    expect(find.text('625 g de frango'), findsOneWidget);

    await tester.tap(find.byTooltip('Menos uma porção'));
    await tester.pumpAndSettle();
    expect(find.text('500g de frango'), findsOneWidget);
  });

  testWidgets('o atalho "Compras" fica ao lado das porções', (tester) async {
    await _open(tester, _detail());

    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('PORÇÕES'), findsOneWidget);
  });

  testWidgets('recolher os ingredientes some com a lista', (tester) async {
    await _open(tester, _detail());

    await tester.tap(find.text('INGREDIENTES'));
    await tester.pumpAndSettle();

    expect(find.text('500g de frango'), findsNothing);
  });

  testWidgets('tela larga: ingredientes e passos lado a lado, sem recolher',
      (tester) async {
    await _open(tester, _detail(), size: const Size(1000, 600));

    final ingredient = tester.getTopLeft(find.text('500g de frango'));
    final step = tester.getTopLeft(find.text('Tempere o frango'));
    expect(ingredient.dx, lessThan(step.dx));
    expect(find.text('Preparo'), findsOneWidget);

    await tester.tap(find.text('INGREDIENTES'));
    await tester.pumpAndSettle();
    expect(find.text('500g de frango'), findsOneWidget);
  });

  testWidgets('tocar num passo risca o texto (marca como feito)',
      (tester) async {
    await _open(tester, _detail());

    // O risco é uma linha animada por cima do texto (`SweepStrikeText`),
    // não mais `TextDecoration.lineThrough` (que não anima suavemente) —
    // checa a prop `done` do widget, não o `TextStyle` renderizado.
    SweepStrikeText stepStrike() => tester.widget<SweepStrikeText>(
          find.widgetWithText(SweepStrikeText, 'Tempere o frango'),
        );

    expect(stepStrike().done, isFalse);

    await tester.tap(find.text('Tempere o frango'));
    await tester.pumpAndSettle();

    expect(stepStrike().done, isTrue);
  });

  testWidgets('sem passos, mostra aviso e mantém ingredientes', (tester) async {
    await _open(tester, _detail(steps: const []));

    expect(find.textContaining('não tem passos'), findsOneWidget);
    expect(find.text('500g de frango'), findsOneWidget);
  });

  group('timers', () {
    const baking = [
      RecipeStep(
          id: 's1', recipeId: 'r1', text: 'Tempere o frango', position: 0),
      RecipeStep(
        id: 's2',
        recipeId: 'r1',
        text: 'Asse por 20 minutos',
        position: 1,
      ),
    ];

    /// Desmonta a tela: o `ProviderScope` descarta o notifier e cancela o
    /// relógio de 1 s (senão o teste termina com timer pendente).
    Future<void> close(WidgetTester tester) =>
        tester.pumpWidget(const SizedBox.shrink());

    testWidgets('sem tempo de cozimento não tem cartão de cozimento',
        (tester) async {
      await _open(tester, _detail());
      expect(find.text('COZIMENTO'), findsNothing);
      expect(find.byTooltip('Pausar'), findsNothing);
    });

    testWidgets('com cookMinutes, o cartão inicia o timer e a faixa mostra',
        (tester) async {
      await _open(tester, _detail(cook: 25));

      expect(find.text('COZIMENTO'), findsOneWidget);
      expect(find.text('25:00 · toque pra iniciar'), findsOneWidget);

      await tester.tap(find.text('COZIMENTO'));
      await tester.pump();

      expect(find.text('Cozimento'), findsOneWidget); // rótulo na faixa
      // O relógio aparece no cartão e na faixa.
      expect(find.text('25:00'), findsNWidgets(2));
      expect(find.byTooltip('Pausar'), findsOneWidget);
      await close(tester);
    });

    testWidgets(
        'tempo no texto do passo vira botão; tocar inicia sem marcar o passo',
        (tester) async {
      await _open(tester, _detail(steps: baking));

      expect(find.text('20 min'), findsOneWidget);
      await tester.tap(find.text('20 min'));
      await tester.pump();

      expect(find.text('Passo 2'), findsOneWidget);
      expect(find.text('20:00'), findsNWidgets(2)); // botão + faixa
      final strikes = tester
          .widgetList<SweepStrikeText>(find.byType(SweepStrikeText))
          .map((w) => w.done);
      expect(strikes.every((d) => !d), isTrue);
      await close(tester);
    });

    testWidgets(
        'as chaves de vibrar e som ficam no cartão, à esquerda do relógio',
        (tester) async {
      await _open(tester, _detail(steps: baking));
      await tester.tap(find.text('20 min'));
      await tester.pump();

      // Dentro do mesmo cartão (linha) do relógio, à esquerda dele.
      final row = find.ancestor(
        of: find.text('20:00').last,
        matching: find.byType(Container),
      );
      expect(
        find.descendant(of: row.first, matching: find.byIcon(Icons.vibration)),
        findsOneWidget,
      );
      final time = tester.getTopLeft(find.text('20:00').last).dx;
      final vibrate = tester.getTopLeft(find.byIcon(Icons.vibration)).dx;
      expect(vibrate, lessThan(time));
      expect(find.byIcon(Icons.volume_off), findsOneWidget); // som: padrão off
      await close(tester);
    });

    testWidgets('pausar e retomar pela faixa; o botão do passo acompanha',
        (tester) async {
      await _open(tester, _detail(steps: baking));
      await tester.tap(find.text('20 min'));
      await tester.pump();

      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();
      expect(find.byTooltip('Retomar'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsWidgets);

      await tester.tap(find.byTooltip('Retomar'));
      await tester.pump();
      expect(find.byTooltip('Pausar'), findsOneWidget);
      await close(tester);
    });

    testWidgets('ao acabar vira "Pronto!" e "Parar" tira da tela',
        (tester) async {
      var now = DateTime.utc(2026, 10, 1, 12);
      await _open(tester, _detail(steps: baking), clock: () => now);
      await tester.tap(find.text('20 min'));
      await tester.pump();

      now = now.add(const Duration(minutes: 21));
      ProviderScope.containerOf(tester.element(find.byType(CookingModePage)))
          .read(cookingTimersProvider.notifier)
          .tick();
      await tester.pump();

      expect(find.text('Passo 2 · Pronto!'), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget); // no botão do passo
      expect(find.byTooltip('Repetir'), findsOneWidget);

      await tester.tap(find.byTooltip('Parar'));
      await tester.pump();
      expect(find.text('Passo 2 · Pronto!'), findsNothing);
      expect(find.text('20 min'), findsOneWidget); // botão volta ao normal
      await close(tester);
    });
  });
}
