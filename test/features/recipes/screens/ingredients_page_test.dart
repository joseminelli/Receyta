import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/controllers/ingredients_view_model.dart';
import 'package:receyta/features/recipes/screens/ingredients_page.dart';
import 'package:receyta/theme/app_theme.dart';

class _SpyRepo extends IngredientRepository {
  _SpyRepo(super.dao);

  final pantryCalls = <({String id, bool value})>[];
  final priceCalls = <({String id, IngredientPrice? price})>[];

  @override
  Future<Result<void>> setPrice(String id, IngredientPrice? price) async {
    priceCalls.add((id: id, price: price));
    return const Ok(null);
  }

  @override
  Future<Result<void>> setInPantry(String id, bool value) async {
    pantryCalls.add((id: id, value: value));
    return const Ok(null);
  }
}

IngredientWithCount _row(String id, String name,
        {int count = 1, bool pantry = false, IngredientPrice? price}) =>
    (
      ingredient: Ingredient(
        id: id,
        displayName: name,
        normalizedKey: name.toLowerCase(),
        inPantry: pantry,
        price: price,
      ),
      count: count,
    );

void main() {
  late AppDatabase db;
  late _SpyRepo repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _SpyRepo(db.ingredientDao);
  });

  tearDown(() => db.close());

  Widget host(List<IngredientWithCount> rows, {bool pantryOnly = false}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => IngredientsPage(pantryOnly: pantryOnly),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ingredientsWithCountsProvider.overrideWith((ref) => Stream.value(rows)),
        ingredientRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('mostra a etiqueta "Sempre tenho" e a contagem da despensa',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sempre tenho'), findsOneWidget);
    expect(find.text('Na despensa (1)'), findsOneWidget);
    expect(find.text('Farinha'), findsOneWidget);
  });

  testWidgets('o filtro "Na despensa" esconde o resto', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Na despensa (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Sal'), findsOneWidget);
    expect(find.text('Farinha'), findsNothing);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();
    expect(find.text('Farinha'), findsOneWidget);
  });

  testWidgets('abre direto no filtro quando vem da aba Conta', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')],
          pantryOnly: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Farinha'), findsNothing);
    expect(find.text('Sal'), findsOneWidget);
  });

  testWidgets('despensa vazia explica como usar', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')], pantryOnly: true));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nada na despensa ainda'), findsOneWidget);
  });

  testWidgets('o botão da despensa liga e desliga o ingrediente',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sempre tenho (despensa)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tirar da despensa'));
    await tester.pumpAndSettle();

    expect(repo.pantryCalls, [
      (id: '2', value: true),
      (id: '1', value: false),
    ]);
  });

  testWidgets('"Definir preço" abre a folha e grava o valor digitado',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '8,50');
    await tester.tap(find.text('por litro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar preço'));
    await tester.pumpAndSettle();

    expect(repo.priceCalls, [
      (id: '2', price: const IngredientPrice(850, PriceBasis.liter)),
    ]);
  });

  testWidgets('valor inválido mostra o erro e não grava', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0');
    await tester.tap(find.text('Salvar preço'));
    await tester.pumpAndSettle();

    expect(find.textContaining('maior que zero'), findsOneWidget);
    expect(repo.priceCalls, isEmpty);
  });

  testWidgets('ingrediente com preço mostra a etiqueta e permite remover',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([
      _row('2', 'Farinha', price: const IngredientPrice(600, PriceBasis.kg)),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 6,00/kg'), findsOneWidget);
    expect(find.text('Definir preço'), findsNothing);

    await tester.tap(find.text('R\$ 6,00/kg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover preço'));
    await tester.pumpAndSettle();

    expect(repo.priceCalls, [(id: '2', price: null)]);
  });
}
