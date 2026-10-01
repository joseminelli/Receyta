import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/features/onboarding/screens/tutorial_overlay.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<int> recipeCount() async =>
      (await container.read(recipeRepositoryProvider).watchAll().first)
          .length;

  test('sem tour pendente, não faz nada', () async {
    await container.read(tutorialControllerProvider).startIfNeeded();

    expect(container.read(tutorialStepProvider), isNull);
    expect(await recipeCount(), 0);
  });

  test('pendente: cria o exemplo e abre no passo 0; concluir apaga', () async {
    await markTutorialPending();
    final controller = container.read(tutorialControllerProvider);

    await controller.startIfNeeded();

    expect(container.read(tutorialStepProvider), 0);
    expect(await recipeCount(), 1);

    await controller.finish();

    expect(container.read(tutorialStepProvider), isNull);
    expect(await recipeCount(), 0);
  });

  test('o tour só começa uma vez', () async {
    await markTutorialPending();
    final controller = container.read(tutorialControllerProvider);
    await controller.startIfNeeded();
    await controller.finish();

    await controller.startIfNeeded();

    expect(container.read(tutorialStepProvider), isNull);
    expect(await recipeCount(), 0);
  });

  test('exemplo esquecido (app morto no meio do tour) some na abertura',
      () async {
    await markTutorialPending();
    await container.read(tutorialControllerProvider).startIfNeeded();
    expect(await recipeCount(), 1);

    container.read(tutorialStepProvider.notifier).state = null;
    await container.read(tutorialControllerProvider).startIfNeeded();

    expect(await recipeCount(), 0);
  });

  test('next percorre todos os passos e o último conclui', () async {
    await markTutorialPending();
    final controller = container.read(tutorialControllerProvider);
    await controller.startIfNeeded();

    for (var i = 1; i < kTutorialSteps.length; i++) {
      controller.next();
      expect(container.read(tutorialStepProvider), i);
    }
    controller.next();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(tutorialStepProvider), isNull);
    expect(await recipeCount(), 0);
  });

  testWidgets('overlay mostra o cartão do passo, com Pular e Próximo',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(tutorialStepProvider.notifier).state = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: TutorialOverlay()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Um tour rápido'), findsOneWidget);
    expect(find.text('1 DE ${kTutorialSteps.length}'), findsOneWidget);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar receitas'), findsOneWidget);
    expect(c.read(tutorialStepProvider), 1);
  });
}
