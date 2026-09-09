import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/theme/app_theme.dart';

Widget _host() => ProviderScope(
      overrides: [
        recipesStreamProvider
            .overrideWith((ref) => Stream.value(const <Recipe>[])),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
    );

void main() {
  testWidgets('inicia em Receitas com as 3 abas', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byType(RecipesPage), findsOneWidget);
    for (final label in ['Receitas', 'Semana', 'Compras']) {
      expect(find.bySemanticsLabel(label), findsWidgets);
    }
    expect(find.text('Em breve'), findsNothing);
  });

  testWidgets('trocar de aba mostra o placeholder e o estado é preservado',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Compras'));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsOneWidget);

    expect(find.byType(RecipesPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Receitas'));
    await tester.pumpAndSettle();
    expect(find.text('Em breve'), findsNothing);
  });
}
