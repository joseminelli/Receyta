import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/features/recipes/trash_page.dart';
import 'package:receyta/theme/app_theme.dart';

Recipe _trashed(String id, String name) => Recipe(
      id: id,
      name: name,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      deletedAt: DateTime.now().toUtc().subtract(const Duration(days: 5)),
    );

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late StreamController<List<Recipe>> trash;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => DateTime.now().toUtc());
    trash = StreamController<List<Recipe>>.broadcast();
  });
  tearDown(() async {
    await trash.close();
    await db.close();
  });

  Widget host() {
    final router = GoRouter(
      initialLocation: '/trash',
      routes: [
        GoRoute(path: '/trash', builder: (_, __) => const TrashPage()),
      ],
    );
    return ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWithValue(repo),
        trashedRecipesProvider.overrideWith((ref) => trash.stream),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  /// 'ativa' | 'lixeira' | 'sumiu' — lido direto do banco, sem stream.
  Future<String> stateOf(WidgetTester tester, String id) async {
    final row = await tester.runAsync(() => db.customSelect(
        'SELECT deleted_at FROM recipes WHERE id = ?',
        variables: [Variable<String>(id)]).getSingleOrNull());
    if (row == null) return 'sumiu';
    return row.read<DateTime?>('deleted_at') == null ? 'ativa' : 'lixeira';
  }

  testWidgets('lixeira vazia mostra aviso', (tester) async {
    await tester.pumpWidget(host());
    trash.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('A lixeira está vazia.'), findsOneWidget);
  });

  testWidgets('restaura e exclui de vez chamam o repositório', (tester) async {
    final a = (await repo.saveDetail(name: 'Sopa')) as Ok<Recipe>;
    final b = (await repo.saveDetail(name: 'Bolo')) as Ok<Recipe>;
    await repo.softDelete(a.value.id);
    await repo.softDelete(b.value.id);

    await tester.pumpWidget(host());
    trash.add([_trashed(a.value.id, 'Sopa'), _trashed(b.value.id, 'Bolo')]);
    await tester.pumpAndSettle();

    expect(find.text('Sopa'), findsOneWidget);
    expect(find.textContaining('Apaga em'), findsNWidgets(2));

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Sopa'),
      matching: find.byIcon(Icons.restore_from_trash_outlined),
    ));
    await tester.pumpAndSettle();
    expect(await stateOf(tester, a.value.id), 'ativa');

    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, 'Bolo'),
      matching: find.byIcon(Icons.delete_forever_outlined),
    ));
    await tester.pumpAndSettle();
    expect(await stateOf(tester, b.value.id), 'sumiu');
  });
}
