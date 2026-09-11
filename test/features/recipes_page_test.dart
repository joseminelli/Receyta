import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/recipe_card.dart';

Recipe _recipe(String id, String name) {
  final t = DateTime.utc(2026);
  return Recipe(id: id, name: name, createdAt: t, updatedAt: t);
}

Widget _host(
  List<Recipe> recipes, {
  List<Tag> tags = const [],
  bool hasFavorites = false,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: RecipesPage()),
      ),
      GoRoute(path: '/recipe/new', builder: (_, __) => const Text('ROTA NOVA')),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('ROTA DETALHE ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipesStreamProvider.overrideWith((ref) => Stream.value(recipes)),
      recentRecipesProvider.overrideWith((ref) => Stream.value(recipes)),
      allRecipesProvider.overrideWith((ref) => Stream.value(recipes)),
      inUseTagsProvider.overrideWith((ref) => Stream.value(tags)),
      trashedRecipesProvider
          .overrideWith((ref) => Stream.value(const <Recipe>[])),
      hasFavoritesProvider.overrideWith((ref) => Stream.value(hasFavorites)),
      rootFoldersProvider
          .overrideWith((ref) => Stream.value(const <FolderWithCounts>[])),
      tagsWithCountsProvider.overrideWith(
        (ref) => Stream.value([for (final t in tags) (tag: t, count: 1)]),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('sem receitas mostra o estado vazio', (tester) async {
    await tester.pumpWidget(_host(const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma receita ainda'), findsOneWidget);
    expect(find.text('0 RECEITAS'), findsOneWidget);
    expect(find.byType(FeaturedRecipeCard), findsNothing);
  });

  testWidgets('primeira receita vira o destaque, o resto vai pra grade',
      (tester) async {
    await tester.pumpWidget(_host([
      _recipe('a', 'Sopa de abóbora'),
      _recipe('b', 'Risoto de limão'),
      _recipe('c', 'Farofa de ovo'),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('3 RECEITAS'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeaturedRecipeCard),
        matching: find.text('Sopa de abóbora'),
      ),
      findsOneWidget,
    );
    expect(find.byType(RecipeCard), findsNWidgets(2));
  });

  testWidgets('+ abre o menu e "Nova receita" leva ao formulário',
      (tester) async {
    await tester.pumpWidget(_host([_recipe('a', 'Sopa')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    expect(find.text('Nova receita'), findsOneWidget);
    expect(find.text('Nova pasta'), findsOneWidget);

    await tester.tap(find.text('Nova receita'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA NOVA'), findsOneWidget);
  });

  testWidgets('sem tags, a lista horizontal de filtro não aparece',
      (tester) async {
    await tester.pumpWidget(_host([_recipe('a', 'Sopa')]));
    await tester.pumpAndSettle();
    expect(find.text('Todas'), findsNothing);
  });

  testWidgets('com tags: "Todas" + as tags aparecem e respondem ao toque',
      (tester) async {
    await tester.pumpWidget(_host(
      [_recipe('a', 'Sopa')],
      tags: const [Tag(id: 't1', name: 'Rápido'), Tag(id: 't2', name: 'Doce')],
    ));
    await tester.pumpAndSettle();
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('Doce'), findsOneWidget);

    await tester.tap(find.text('Rápido'));
    await tester.pumpAndSettle();
    expect(find.text('Rápido'), findsOneWidget);
  });

  testWidgets('chip "Favoritos" aparece quando há favorita, como 1º do filtro',
      (tester) async {
    await tester.pumpWidget(_host([_recipe('a', 'Sopa')], hasFavorites: true));
    await tester.pumpAndSettle();

    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos'), findsOneWidget);
  });

  testWidgets('sem favorita nem tag, o filtro não aparece', (tester) async {
    await tester.pumpWidget(_host([_recipe('a', 'Sopa')]));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos'), findsNothing);
    expect(find.text('Todas'), findsNothing);
  });

  testWidgets('tocar no destaque abre o detalhe daquela receita',
      (tester) async {
    await tester.pumpWidget(_host([
      _recipe('a', 'Sopa de abóbora'),
      _recipe('b', 'Risoto de limão'),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FeaturedRecipeCard));
    await tester.pumpAndSettle();

    expect(find.text('ROTA DETALHE a'), findsOneWidget);
  });
}
