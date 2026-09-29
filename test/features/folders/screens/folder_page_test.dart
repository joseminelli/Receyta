import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/folders/folder_page.dart';
import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/recipe_card.dart';

Recipe _recipe(String id, String name) {
  final t = DateTime.utc(2026);
  return Recipe(id: id, name: name, createdAt: t, updatedAt: t, folderId: 'f1');
}

Widget _host({
  Folder? folder = const Folder(id: 'f1', name: 'Doces'),
  List<FolderWithCounts> subfolders = const [],
  List<Recipe> recipes = const [],
}) {
  final router = GoRouter(
    initialLocation: '/folder/f1',
    routes: [
      GoRoute(
        path: '/folder/:id',
        builder: (_, s) => FolderPage(folderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => Text('DETALHE ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      folderProvider.overrideWith((ref, id) => Stream.value(folder)),
      subfoldersProvider.overrideWith((ref, id) => Stream.value(subfolders)),
      folderRecipesProvider.overrideWith((ref, id) => Stream.value(recipes)),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void main() {
  testWidgets('mostra o nome da pasta e as receitas', (tester) async {
    await tester.pumpWidget(_host(
      recipes: [_recipe('a', 'Brigadeiro'), _recipe('b', 'Beijinho')],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Doces'), findsOneWidget);
    expect(find.byType(RecipeCard), findsNWidgets(2));
  });

  testWidgets('pasta vazia mostra o aviso', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Pasta vazia'), findsOneWidget);
  });

  testWidgets('subpasta aparece e navega', (tester) async {
    await tester.pumpWidget(_host(
      subfolders: const [
        (
          folder: Folder(id: 'sub', name: 'Bolos', parentId: 'f1'),
          recipeCount: 3,
          subfolders: 0,
        ),
      ],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Bolos'), findsOneWidget);
    expect(find.text('Subpastas'), findsOneWidget);
  });

  testWidgets('pasta inexistente mostra fallback', (tester) async {
    await tester.pumpWidget(_host(folder: null));
    await tester.pumpAndSettle();

    expect(find.text('Pasta não encontrada'), findsOneWidget);
  });

  testWidgets('tocar numa receita abre o detalhe', (tester) async {
    await tester.pumpWidget(_host(recipes: [_recipe('a', 'Brigadeiro')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(RecipeCard));
    await tester.pumpAndSettle();

    expect(find.text('DETALHE a'), findsOneWidget);
  });
}
