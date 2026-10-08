import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/features/recipes/screens/smart_collections_page.dart';
import 'package:receyta/theme/app_theme.dart';

Recipe _recipe(String id) {
  final t = DateTime.utc(2026);
  return Recipe(id: id, name: id, createdAt: t, updatedAt: t);
}

Widget _host(Map<SmartCollection, List<Recipe>> data) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SmartCollectionsPage()),
      GoRoute(
        path: '/collection/:id',
        builder: (_, s) => Text('ROTA ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [smartCollectionsProvider.overrideWith((ref) => data)],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('lista cada coleção com a regra e a contagem', (tester) async {
    await tester.pumpWidget(_host({
      SmartCollection.quick: [_recipe('a')],
      SmartCollection.neverCooked: [_recipe('a'), _recipe('b')],
    }));
    await tester.pumpAndSettle();

    expect(find.text('Rápidas'), findsOneWidget);
    expect(find.text(SmartCollection.quick.description), findsOneWidget);
    expect(find.text('Nunca cozinhei'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Favoritas'), findsNothing);

    await tester.tap(find.text('Nunca cozinhei'));
    await tester.pumpAndSettle();
    expect(find.text('ROTA neverCooked'), findsOneWidget);
  });

  testWidgets('sem coleção nenhuma, avisa', (tester) async {
    await tester.pumpWidget(_host(const {}));
    await tester.pumpAndSettle();
    expect(find.text('Nada por aqui ainda'), findsOneWidget);
  });
}
