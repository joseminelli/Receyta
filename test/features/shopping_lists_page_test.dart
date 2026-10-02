import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      'cada lista mostra nome e progresso; concluída e vazia dizem isso',
      (tester) async {
    await tester.pumpWidget(_host([
      _summary('Semana', 12, 7),
      _summary('Festa', 3, 3),
      _summary('Nova', 0, 0),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('Semana'), findsOneWidget);
    expect(find.textContaining('7 de 12 itens'), findsOneWidget);
    expect(find.textContaining('Vazia'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('EM ANDAMENTO'), findsOneWidget);
    expect(find.text('CONCLUÍDAS'), findsOneWidget);
    expect(find.textContaining('3 LISTAS · 2 EM ANDAMENTO'), findsOneWidget);
  });
}
