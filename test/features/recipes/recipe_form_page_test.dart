import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipe_form_page.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/pill_button.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => DateTime.utc(2026));
  });
  tearDown(() => db.close());

  Widget host(String target) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push(target),
                child: const Text('início'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/new', builder: (_, __) => const RecipeFormPage()),
        GoRoute(
          path: '/recipe/:id/edit',
          builder: (_, s) => RecipeFormPage(recipeId: s.pathParameters['id']),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        recipeRepositoryProvider.overrideWithValue(repo),
        allTagsProvider.overrideWith((ref) => Stream.value(const <Tag>[])),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
  }

  /// Abre o formulário a partir da home ('/'), para que `context.pop()` no
  /// salvar tenha uma tela abaixo — como no router real, onde ele é empurrado.
  Future<void> openForm(WidgetTester tester, String target) async {
    await tester.pumpWidget(host(target));
    await tester.pumpAndSettle();
    await tester.tap(find.text('início'));
    await tester.pumpAndSettle();
  }

  Finder fieldByLabel(String label) => find.descendant(
        of: find
            .ancestor(
              of: find.text(label.toUpperCase()),
              matching: find.byType(Column),
            )
            .first,
        matching: find.byType(TextField),
      );

  Finder hintField(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  PillButton salvar(WidgetTester tester) =>
      tester.widget<PillButton>(find.widgetWithText(PillButton, 'Salvar'));

  testWidgets('cria: nome, campo e ingrediente; salva e volta; tudo persiste',
      (tester) async {
    await openForm(tester, '/new');

    await tester.enterText(fieldByLabel('Nome'), 'Bolo de fubá');
    await tester.enterText(fieldByLabel('Sobre'), 'de domingo');

    final addIngrediente = find.text('Adicionar ingrediente');
    await tester.scrollUntilVisible(
      addIngrediente,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(addIngrediente);
    await tester.pumpAndSettle();
    await tester.tap(addIngrediente);
    await tester.pumpAndSettle();
    await tester.enterText(
        hintField('ex.: 2 xícaras de farinha'), '2 xíc fubá');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('início'), findsOneWidget);

    final detail = await tester.runAsync(() async {
      final list = await repo.watchAll().first;
      return ((await repo.getDetail(list.single.id)) as Ok<RecipeDetail>).value;
    });
    expect(detail!.recipe.name, 'Bolo de fubá');
    expect(detail.recipe.about, 'de domingo');
    expect(detail.ingredients.single.rawText, '2 xíc fubá');
  });

  testWidgets('Salvar fica desabilitado sem nome', (tester) async {
    await openForm(tester, '/new');

    expect(salvar(tester).onPressed, isNull);
    await tester.enterText(fieldByLabel('Nome'), 'Pão');
    await tester.pumpAndSettle();
    expect(salvar(tester).onPressed, isNotNull);
  });

  testWidgets('edita: as tags do banco aparecem como chips', (tester) async {
    final bolo = await repo.saveDetail(
      name: 'Bolo',
      tagNames: ['doce', 'receitas de família'],
    ) as Ok<Recipe>;

    await openForm(tester, '/recipe/${bolo.value.id}/edit');

    expect(find.text('Doce'), findsOneWidget);
    expect(find.text('Receitas de Família'), findsOneWidget);
  });

  testWidgets('edita: abre preenchido e grava por cima', (tester) async {
    final created = await repo.saveDetail(
      name: 'Sopa',
      prepMinutes: 5,
      about: 'antiga',
      ingredientLines: ['água', 'sal'],
    ) as Ok<Recipe>;

    await openForm(tester, '/recipe/${created.value.id}/edit');

    expect(find.text('Editar receita'), findsOneWidget);
    expect(find.text('Sopa'), findsOneWidget);
    expect(find.text('antiga'), findsOneWidget);
    expect(find.text('água'), findsOneWidget);

    await tester.enterText(fieldByLabel('Nome'), 'Caldo verde');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    final saved = await tester.runAsync(() => repo.watchAll().first);
    expect(saved!.single.name, 'Caldo verde');
    expect(saved.single.id, created.value.id);
    expect(saved.single.prepMinutes, 5);
  });
}
