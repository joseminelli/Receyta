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

  /// Abre o menu "⋯" da linha [row] e escolhe a opção [label].
  Future<void> pickFromMenu(
    WidgetTester tester,
    String label, {
    int row = 0,
  }) async {
    await tester.tap(find.byTooltip('Opções do ingrediente').at(row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('quem está na despensa leva o ícone; o filtro mostra a conta',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')]),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.kitchen), findsOneWidget);
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

  testWidgets('a despensa liga e desliga pelo menu', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(
      host([_row('1', 'Sal', pantry: true), _row('2', 'Farinha')]),
    );
    await tester.pumpAndSettle();

    await pickFromMenu(tester, 'Sempre tenho (despensa)', row: 1);
    await pickFromMenu(tester, 'Tirar da despensa', row: 0);

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

    await pickFromMenu(tester, 'Definir preço');
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

    await pickFromMenu(tester, 'Definir preço');
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
    await pickFromMenu(tester, 'Definir preço');
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

  testWidgets('o cartão é enxuto: inicial, nome e "N receitas · preço"',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([
      _row('1', 'Farinha', count: 3, price: const IngredientPrice(600, 'kg')),
      _row('2', 'Sal', count: 0),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('F'), findsOneWidget);
    expect(find.text('3 receitas'), findsOneWidget);
    expect(find.text('R\$ 6,00/kg'), findsOneWidget);
    expect(find.text('Não usado'), findsOneWidget);
    expect(find.text('Sem preço'), findsOneWidget);
    // Nada de botões soltos: tudo mora no menu.
    expect(find.text('Definir preço'), findsNothing);
    expect(find.byTooltip('Sempre tenho (despensa)'), findsNothing);
  });

  testWidgets('a lixeira marca só quem pode ser apagado', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([
      _row('1', 'Farinha', count: 3),
      _row('2', 'Sal', count: 0),
      _row('3', 'Açúcar', count: 0, pantry: true),
    ]));
    await tester.pumpAndSettle();

    // Dois sem uso (Sal e Açúcar) -> duas lixeiras; só um na despensa.
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    expect(find.byIcon(Icons.kitchen), findsOneWidget);
    expect(find.bySemanticsLabel('Pode ser apagado'), findsNWidgets(2));
  });

  testWidgets('todas as opções ficam no menu; apagar só sem uso',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([
      _row('1', 'Farinha', count: 3),
      _row('2', 'Sal', count: 0),
    ]));
    await tester.pumpAndSettle();

    // Em uso: preço, despensa e mesclar — sem apagar.
    await tester.tap(find.byTooltip('Opções do ingrediente').first);
    await tester.pumpAndSettle();
    expect(find.text('Definir preço'), findsOneWidget);
    expect(find.text('Sempre tenho (despensa)'), findsOneWidget);
    expect(find.text('Mesclar com...'), findsOneWidget);
    expect(find.text('Apagar'), findsNothing);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Sem uso: também "Apagar".
    await tester.tap(find.byTooltip('Opções do ingrediente').last);
    await tester.pumpAndSettle();
    expect(find.text('Apagar'), findsOneWidget);
  });

  testWidgets('a folha de preço avisa que ele fica só no aparelho',
      (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await pickFromMenu(tester, 'Definir preço');

    expect(find.textContaining('só neste aparelho'), findsOneWidget);
    expect(find.textContaining('nuvem'), findsOneWidget);
  });

  testWidgets('valor inválido mostra o erro e não grava', (tester) async {
    usePhone(tester);
    await tester.pumpWidget(host([_row('2', 'Farinha')]));
    await tester.pumpAndSettle();

    await pickFromMenu(tester, 'Definir preço');
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
    expect(find.text('Sem preço'), findsNothing);

    await pickFromMenu(tester, 'Editar preço');
    await tester.tap(find.text('Remover preço'));
    await tester.pumpAndSettle();

    expect(repo.priceCalls, [(id: '2', price: null)]);
  });
}
