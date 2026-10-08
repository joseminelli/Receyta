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

  testWidgets(
      '"Definir preço" abre a folha e grava valor, quantidade e unidade',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '4,50');
    await tester.enterText(fields.at(1), '500');
    await tester.tap(find.text('Salvar preço'));
    await tester.pumpAndSettle();

    expect(repo.priceCalls, [
      (id: '2', price: const IngredientPrice(450, 'kg', 500)),
    ]);
  });

  testWidgets('a unidade vem por extenso, agrupada, e dá pra trocar',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    expect(find.text('Quilograma (kg)'), findsOneWidget);

    await tester.tap(find.text('Quilograma (kg)'));
    await tester.pumpAndSettle();
    expect(find.text('PESO'), findsOneWidget);
    expect(find.text('VOLUME'), findsOneWidget);
    expect(find.text('CONTAGEM'), findsOneWidget);
    expect(find.text('Gramas (g)'), findsOneWidget);
    expect(find.text('Litro (L)'), findsOneWidget);
    expect(find.text('Mililitro (ml)'), findsOneWidget);
    expect(find.text('Unidade (un)'), findsOneWidget);

    await tester.tap(find.text('Litro (L)'));
    await tester.pumpAndSettle();
    expect(find.text('Litro (L)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '5');
    await tester.tap(find.text('Salvar preço'));
    await tester.pumpAndSettle();

    expect(repo.priceCalls, [
      (id: '2', price: const IngredientPrice(500, 'l')),
    ]);
  });

  testWidgets('seletor de unidade: busca, filtro e voltar sem mudar',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quilograma (kg)'));
    await tester.pumpAndSettle();

    // Busca ignora acento e caixa.
    await tester.enterText(find.byType(TextField).last, 'MACO');
    await tester.pumpAndSettle();
    expect(find.text('Maço'), findsOneWidget);
    expect(find.text('Litro (L)'), findsNothing);

    await tester.enterText(find.byType(TextField).last, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma unidade encontrada'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar busca'));
    await tester.pumpAndSettle();

    // Filtro por tipo.
    await tester.tap(find.widgetWithText(InkWell, 'Volume').first);
    await tester.pumpAndSettle();
    expect(find.text('Litro (L)'), findsOneWidget);
    expect(find.text('Gramas (g)'), findsNothing);
    expect(find.text('Dente'), findsNothing);

    // Voltar fecha o seletor sem trocar a unidade.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Quilograma (kg)'), findsOneWidget);
    expect(find.text('Buscar unidade'), findsNothing);
  });

  testWidgets('a folha de preço avisa que ele fica só no aparelho',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();

    expect(find.textContaining('só neste aparelho'), findsOneWidget);
    expect(find.textContaining('nuvem'), findsOneWidget);
  });

  testWidgets('valor inválido mostra o erro e não grava', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definir preço'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.text('Salvar preço'));
    await tester.pumpAndSettle();

    expect(find.textContaining('maior que zero'), findsOneWidget);
    expect(repo.priceCalls, isEmpty);
  });

  testWidgets('ingrediente com preço mostra a etiqueta e permite remover',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([
      _row('2', 'Farinha', price: const IngredientPrice(600, 'kg')),
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
