import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/features/recipes/recipes_page.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/recipe_card.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, clock: () => DateTime.utc(2026));
  });

  tearDown(() => db.close());

  Widget host() => ProviderScope(
        overrides: [
          recipesViewModelProvider.overrideWithValue(RecipesViewModel(repo)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: RecipesPage()),
        ),
      );

  testWidgets('sem receitas mostra o estado vazio', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma receita ainda'), findsOneWidget);
    expect(find.text('0 RECEITAS'), findsOneWidget);
    expect(find.byType(FeaturedRecipeCard), findsNothing);
  });

  testWidgets('lista lê do banco: mais recente vira o destaque', (tester) async {
    await repo.create(name: 'Risoto de limão');
    await repo.create(name: 'Sopa de abóbora');

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('2 RECEITAS'), findsOneWidget);
    expect(find.text('Recentes'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeaturedRecipeCard),
        matching: find.text('Sopa de abóbora'),
      ),
      findsOneWidget,
    );
    expect(find.byType(RecipeCard), findsOneWidget);
  });

  testWidgets('criar receita só com nome faz ela aparecer', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Farofa de ovo  ');
    await tester.pump();
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma receita ainda'), findsNothing);
    expect(find.text('1 RECEITA'), findsOneWidget);
    expect(find.text('Farofa de ovo'), findsOneWidget);
  });

  testWidgets('Criar fica desabilitado enquanto o nome está vazio',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    PillButton criar() =>
        tester.widget<PillButton>(find.widgetWithText(PillButton, 'Criar'));
    expect(criar().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Pão');
    await tester.pump();
    expect(criar().onPressed, isNotNull);
  });
}
