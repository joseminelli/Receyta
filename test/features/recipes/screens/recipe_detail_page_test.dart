import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/similar_recipes.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipe_status_view_model.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/recipes/screens/recipe_detail_page.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';

RecipeDetail _detail() {
  final t = DateTime.utc(2026);
  return RecipeDetail(
    recipe: Recipe(
      id: 'r1',
      name: 'Frango ao curry',
      createdAt: t,
      updatedAt: t,
      about: 'rápido para a semana',
      prepMinutes: 15,
      cookMinutes: 25,
      servings: 4,
      notes: 'melhor no dia seguinte',
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
        rawText: '2 dentes de alho',
        position: 1,
        quantity: 2,
        unitId: 'dente',
      ),
    ],
    steps: const [
      RecipeStep(
          id: 's1', recipeId: 'r1', text: 'Tempere o frango', position: 0),
      RecipeStep(id: 's2', recipeId: 'r1', text: 'Refogue o alho', position: 1),
    ],
    tags: const [Tag(id: 't1', name: 'Rápido'), Tag(id: 't2', name: 'Frango')],
  );
}

Widget _host({
  RecipeDetail? detail,
  List<ShoppingList> shoppingLists = const [],
  List<MealPlanEntry> upcoming = const [],
  List<Recipe> similar = const [],
}) {
  final router = GoRouter(
    initialLocation: '/recipe/r1',
    routes: [
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => RecipeDetailPage(recipeId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/recipe/:id/edit',
        builder: (_, __) => const Text('ROTA EDIT'),
      ),
      GoRoute(
        path: '/recipe/:id/cook',
        builder: (_, __) => const Text('ROTA COZINHA'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeDetailProvider.overrideWith((ref, id) => Stream.value(detail)),
      cookLogsProvider.overrideWith(
        (ref, id) => Stream.value(const <CookLog>[]),
      ),
      // Os cartões de status leem o banco; sem isto cairiam no de verdade.
      recipeShoppingListsProvider.overrideWith(
        (ref, id) => Stream.value(shoppingLists),
      ),
      recipeUpcomingPlanProvider.overrideWith(
        (ref, key) => Stream.value(upcoming),
      ),
      similarRecipesProvider.overrideWith(
        (ref, id) async => [
          for (final r in similar)
            PlannerSuggestion(
              recipe: r,
              score: 0.5,
              sharedIngredientNames: const ['Frango', 'Alho'],
            ),
        ],
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

/// Tela de celular (390×844): com os cartões de status a lista de
/// ingredientes começa mais abaixo, fora da superfície padrão (800×600).
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// A página agenda um `markOpened` pra depois do voo do Hero (520 ms). Desmonta
/// a tela e deixa o tempo passar: com ela fora, o callback não faz nada e o
/// teste não termina com timer pendente nem toca no banco de verdade.
Future<void> _flushOpenedTimer(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('mostra nome, métricas, ingredientes e passos', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    expect(find.text('Frango ao curry'), findsOneWidget);
    expect(find.text('rápido para a semana'), findsOneWidget);
    expect(find.text('Ingredientes'), findsOneWidget);
    expect(find.text('2 itens'), findsOneWidget);
    expect(find.text('500   g de frango', findRichText: true), findsOneWidget);
    expect(find.text('2   dentes de alho', findRichText: true), findsOneWidget);
    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('Frango'), findsOneWidget);

    // Ingredientes e passos agora são slivers lazy (RF perf): numa tela de
    // teste pequena, "Preparo" só existe na árvore depois de rolar até lá.
    await tester.scrollUntilVisible(find.text('Tempere o frango'), 300);
    expect(find.text('Preparo'), findsOneWidget);
    expect(find.text('Tempere o frango'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('melhor no dia seguinte'), 300);
    expect(find.text('melhor no dia seguinte'), findsOneWidget);

    expect(find.text('Modo cozinha'), findsOneWidget);
    await _flushOpenedTimer(tester);
  });

  testWidgets('tela larga: capa fica ao lado do conteúdo', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    final name = tester.getTopLeft(find.text('Frango ao curry'));
    final ingredients = tester.getTopLeft(find.text('Ingredientes'));
    expect(name.dx, lessThan(ingredients.dx));
    await _flushOpenedTimer(tester);
  });

  testWidgets('"Parecidas" mostra as receitas e o que têm em comum',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(
      detail: _detail(),
      similar: [
        Recipe(
          id: 'r2',
          name: 'Frango xadrez',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Parecidas'), 300);
    expect(find.text('Frango xadrez'), findsOneWidget);
    expect(find.text('com frango e alho'), findsOneWidget);
    await _flushOpenedTimer(tester);
  });

  testWidgets('sem passos, não mostra "Modo cozinha"', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(
      detail: RecipeDetail(
        recipe: Recipe(
          id: 'r1',
          name: 'Vitamina',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Modo cozinha'), findsNothing);
    await _flushOpenedTimer(tester);
  });

  testWidgets('"Modo cozinha" abre o modo cozinha', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Modo cozinha'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA COZINHA'), findsOneWidget);
    await _flushOpenedTimer(tester);
  });

  testWidgets('receita inexistente mostra aviso', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(detail: null));
    await tester.pumpAndSettle();

    expect(find.text('Receita não encontrada'), findsOneWidget);
    await _flushOpenedTimer(tester);
  });

  testWidgets('menu "Mais": "Editar" abre o formulário de edição',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host(detail: _detail()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA EDIT'), findsOneWidget);
    await _flushOpenedTimer(tester);
  });

  group('cartões de status (lista de compras e agenda)', () {
    ShoppingList list(String id, String name) => ShoppingList(
          id: id,
          name: name,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );

    MealPlanEntry planned(DateTime day, MealType meal, String id) =>
        MealPlanEntry(
          id: id,
          recipe: _detail().recipe,
          date: day,
          mealType: meal,
        );

    testWidgets('receita solta: os dois cartões convidam a adicionar',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host(detail: _detail()));
      await tester.pumpAndSettle();

      expect(find.text('LISTA DE COMPRAS'), findsOneWidget);
      expect(find.text('Fora da lista'), findsOneWidget);
      expect(find.text('AGENDA'), findsOneWidget);
      expect(find.text('Sem data'), findsOneWidget);
      expect(find.text('Toque pra adicionar'), findsOneWidget);
      expect(find.text('Toque pra agendar'), findsOneWidget);
      await _flushOpenedTimer(tester);
    });

    testWidgets('em uma lista e agendada: mostra qual lista e quando',
        (tester) async {
      _usePhoneSize(tester);
      final t = DateTime.now();
      final today = DateTime.utc(t.year, t.month, t.day);
      await tester.pumpWidget(_host(
        detail: _detail(),
        shoppingLists: [list('l1', 'Semana 28 set – 4 out')],
        upcoming: [
          planned(today, MealType.dinner, 'a'),
          planned(today.add(const Duration(days: 3)), MealType.lunch, 'b'),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Na lista'), findsOneWidget);
      expect(find.text('Semana 28 set – 4 out'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Jantar · +1 data'), findsOneWidget);
      expect(find.text('Fora da lista'), findsNothing);
      expect(find.text('Sem data'), findsNothing);
      await _flushOpenedTimer(tester);
    });

    testWidgets('em várias listas: conta e junta os nomes', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host(
        detail: _detail(),
        shoppingLists: [list('l1', 'Festa'), list('l2', 'Semana')],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Em 2 listas'), findsOneWidget);
      expect(find.text('Festa, Semana'), findsOneWidget);
      await _flushOpenedTimer(tester);
    });
  });
}
