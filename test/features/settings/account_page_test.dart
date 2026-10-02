import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/screens/account_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

CookLog _log(String id, String recipeId, String name) => CookLog(
      id: id,
      recipeId: recipeId,
      recipeName: name,
      cookedAt: DateTime.utc(2026, 10, 1),
    );

Widget _host({
  AppSettings initial = const AppSettings(),
  AsyncValue<LibraryStats>? stats,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
          path: '/', builder: (_, __) => const Scaffold(body: AccountPage())),
      GoRoute(
          path: '/settings', builder: (_, __) => const Text('ROTA AJUSTES')),
    ],
  );
  return ProviderScope(
    overrides: [
      initialAppSettingsProvider.overrideWithValue(initial),
      libraryStatsProvider.overrideWithValue(
        stats ??
            const AsyncData((
              recipes: 12,
              folders: 3,
              lists: 2,
              plannedMeals: 9,
              doneMeals: 4,
              topRecipe: 'Frango ao curry',
              topRecipeCount: 3,
            )),
      ),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 4200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('topCooked', () {
    test('pega a receita com mais registros no histórico', () {
      final top = topCooked([
        _log('1', 'a', 'Bolo'),
        _log('2', 'b', 'Sopa'),
        _log('3', 'b', 'Sopa'),
      ]);

      expect(top.name, 'Sopa');
      expect(top.count, 2);
    });

    test('no empate, fica a que apareceu primeiro', () {
      final top = topCooked([
        _log('1', 'a', 'Bolo'),
        _log('2', 'b', 'Sopa'),
      ]);

      expect(top.name, 'Bolo');
    });

    test('sem histórico, não há receita mais cozinhada', () {
      final top = topCooked(const []);

      expect(top.name, isNull);
      expect(top.count, 0);
    });
  });

  testWidgets('sem apelido, convida a colocar o nome', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Seu nome aqui'), findsOneWidget);
    expect(find.text('Toque pra editar'), findsOneWidget);
  });

  testWidgets('mostra o apelido e a inicial no avatar', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host(initial: const AppSettings(nickname: 'julie')),
    );
    await tester.pumpAndSettle();

    expect(find.text('julie'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
  });

  testWidgets('mostra o livro em números e a receita mais cozinhada',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Receitas'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Refeições planejadas'), findsOneWidget);
    expect(find.text('Mais cozinhada'), findsOneWidget);
    expect(find.text('Frango ao curry'), findsOneWidget);
    expect(find.text('3 vezes'), findsOneWidget);
  });

  testWidgets('sem refeição feita, esconde "Mais cozinhada"', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host(
        stats: const AsyncData((
          recipes: 1,
          folders: 0,
          lists: 0,
          plannedMeals: 0,
          doneMeals: 0,
          topRecipe: null,
          topRecipeCount: 0,
        )),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mais cozinhada'), findsNothing);
  });

  testWidgets('editar o perfil salva apelido e cor', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seu nome aqui'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Zé');
    await tester.tap(find.bySemanticsLabel('Cor violet'));
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Zé'), findsOneWidget);
    final loaded = await loadAppSettings();
    expect(loaded.nickname, 'Zé');
    expect(loaded.profileColor, TileColor.violet);
  });

  testWidgets('o cartão de sincronização leva às configurações',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Sincronização em breve'), findsOneWidget);
    await tester.tap(find.text('Ver backup'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA AJUSTES'), findsOneWidget);
  });
}
