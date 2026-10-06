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
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/recipes/screens/trash_page.dart';
import 'package:receyta/theme/app_theme.dart';

import '../../../helpers/db_settle.dart';

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

    expect(find.text('A lixeira está vazia'), findsOneWidget);
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
    // Cada linha mostra a contagem regressiva num distintivo. Apagada há 5
    // dias e uns milissegundos: faltam 24 dias e uma fração, e o distintivo
    // mostra só os dias inteiros.
    expect(find.text('dias restantes'), findsNWidgets(2));
    expect(find.text('24'), findsNWidgets(2));

    // As linhas seguem a ordem da lista: Sopa primeiro, Bolo depois.
    await tester.tap(find.byTooltip('Restaurar').first);
    await tester.pumpAndSettle();
    await settleDb(tester);
    expect(await stateOf(tester, a.value.id), 'ativa');

    await tester.tap(find.byTooltip('Excluir de vez').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Excluir "Bolo"'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await settleDb(tester);
    expect(await stateOf(tester, b.value.id), 'sumiu');
  });
}
