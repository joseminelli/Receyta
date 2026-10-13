import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/features/shopping/screens/shopping_lists_page.dart';
import 'package:receyta/theme/app_theme.dart';

ShoppingListSummary _summary(String name, int total, int checked) => (
      list: ShoppingList(
        id: name,
        name: name,
        createdAt: DateTime.utc(2026, 9, 29, 12),
        updatedAt: DateTime.utc(2026, 9, 29, 12),
      ),
      total: total,
      checked: checked,
    );

Widget _host(List<ShoppingListSummary> lists) => ProviderScope(
      overrides: [
        shoppingListsProvider.overrideWith((ref) => Stream.value(lists)),
        shoppingCostProvider.overrideWith(
          (ref, listId) => const ShoppingCost(
            byItem: {},
            totalCents: 0,
            pendingCents: 0,
            missingCount: 0,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ShoppingListsPage(),
      ),
    );

void main() {
  testWidgets('sem listas mostra o estado vazio com as duas formas de criar',
      (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma lista ainda'), findsOneWidget);
    expect(find.text('Gerar de receitas'), findsOneWidget);
    expect(find.text('Lista em branco'), findsOneWidget);
  });

  testWidgets(
      'a primeira em andamento vem em destaque, a vazia diz isso e as '
      'concluídas ficam recolhidas', (tester) async {
    await tester.pumpWidget(_host([
      _summary('Semana', 12, 7),
      _summary('Festa', 3, 3),
      _summary('Nova', 0, 0),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Semana'), findsOneWidget);
    expect(find.text('7/12', findRichText: true), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);
    expect(find.textContaining('Vazia'), findsOneWidget);
    expect(find.text('EM ANDAMENTO'), findsOneWidget);
    expect(find.text('CONCLUÍDAS'), findsOneWidget);
    expect(find.text('2 EM ANDAMENTO'), findsOneWidget);
    expect(find.text('Festa'), findsNothing);

    await tester.tap(find.text('CONCLUÍDAS'));
    await tester.pumpAndSettle();
    expect(find.text('Festa'), findsOneWidget);
  });

  testWidgets('sem nenhuma em andamento, as concluídas já aparecem abertas',
      (tester) async {
    await tester.pumpWidget(_host([_summary('Festa', 3, 3)]));
    await tester.pumpAndSettle();

    expect(find.text('Festa'), findsOneWidget);
    expect(find.text('TUDO COMPRADO'), findsOneWidget);
  });
}
