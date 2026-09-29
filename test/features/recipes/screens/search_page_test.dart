import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/features/recipes/search_page.dart';
import 'package:receyta/theme/app_theme.dart';

Recipe _recipe(String name) {
  final t = DateTime.utc(2026);
  return Recipe(
    id: name,
    name: name,
    createdAt: t,
    updatedAt: t,
    prepMinutes: 10,
  );
}

Widget _host(
  List<Recipe> results, {
  List<Tag> tags = const [],
  List<Recipe> all = const [],
}) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(path: '/search', builder: (_, __) => const SearchPage()),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('DETALHE ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      inUseTagsProvider.overrideWith((ref) => Stream.value(tags)),
      allRecipesProvider.overrideWith((ref) => Stream.value(all)),
      searchResultsProvider.overrideWith((ref) {
        final q = ref.watch(searchQueryProvider).trim();
        return Stream.value(q.isEmpty ? const <Recipe>[] : results);
      }),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('query vazia sem tags mostra a dica', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();
    expect(find.textContaining('Busque uma receita'), findsOneWidget);
  });

  testWidgets('query vazia com tags mostra atalhos que preenchem a busca',
      (tester) async {
    await tester.pumpWidget(_host(
      [_recipe('Curry')],
      tags: const [Tag(id: 't1', name: 'Rápido')],
    ));
    await tester.pumpAndSettle();

    expect(find.text('BUSCAR POR TAG'), findsOneWidget);
    await tester.tap(find.text('Rápido'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Rápido'), findsOneWidget);
    expect(find.text('Curry'), findsOneWidget); // resultado apareceu
  });

  testWidgets('digitar mostra resultados e tocar abre o detalhe',
      (tester) async {
    await tester.pumpWidget(_host([_recipe('Frango ao curry')]));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'curry');
    await tester.pump(const Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();

    expect(find.text('Frango ao curry'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);

    await tester.tap(find.text('Frango ao curry'));
    await tester.pumpAndSettle();
    expect(find.text('DETALHE Frango ao curry'), findsOneWidget);
  });

  testWidgets('busca sem resultado mostra aviso', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nada encontrado'), findsOneWidget);
  });
}
