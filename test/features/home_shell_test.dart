import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/home_shell.dart';
import 'package:receyta/theme/app_theme.dart';

Widget _host() => ProviderScope(
      overrides: [
        recipesStreamProvider
            .overrideWith((ref) => Stream.value(const <Recipe>[])),
        inUseTagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
        trashedRecipesProvider
            .overrideWith((ref) => Stream.value(const <Recipe>[])),
        hasFavoritesProvider.overrideWith((ref) => Stream.value(false)),
        tagsWithCountsProvider.overrideWith(
          (ref) => Stream.value(const <({Tag tag, int count})>[]),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
    );

void main() {
  testWidgets('inicia em Receitas com as 4 abas', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byType(RecipesPage), findsOneWidget);
    // RegExp, não igualdade: no slot ativo o label do Semantics funde com o
    // Text visível ("Receitas Receitas").
    for (final label in ['Receitas', 'Semana', 'Compras', 'Conta']) {
      expect(find.bySemanticsLabel(RegExp(label)), findsWidgets);
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

  testWidgets('aba Conta mostra o placeholder de perfil e o botão de config',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(RegExp('Conta')));
    await tester.pumpAndSettle();

    expect(find.text('Sem login por enquanto'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
