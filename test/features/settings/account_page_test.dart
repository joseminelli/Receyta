import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/screens/account_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';

CookLog _log(String id, String recipeId, String name) => CookLog(
      id: id,
      recipeId: recipeId,
      recipeName: name,
      cookedAt: DateTime.utc(2026, 10, 1),
    );

Widget _host({
  AppSettings initial = const AppSettings(),
  AsyncValue<LibraryStats>? stats,
  FakeAuthService? auth,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
          path: '/', builder: (_, __) => const Scaffold(body: AccountPage())),
      GoRoute(
          path: '/settings', builder: (_, __) => const Text('ROTA AJUSTES')),
      GoRoute(
          path: '/history', builder: (_, __) => const Text('ROTA HISTORICO')),
    ],
  );
  return ProviderScope(
    overrides: [
      initialAppSettingsProvider.overrideWithValue(initial),
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
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
  tester.view.physicalSize = const Size(1170, 6600);
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
    expect(find.text('RECEITAS'), findsOneWidget);
    expect(find.text('PASTAS'), findsOneWidget);
    expect(find.text('LISTAS'), findsOneWidget);
    expect(find.text('REFEIÇÕES'), findsOneWidget);
    expect(
      find.text('Mais cozinhada · Frango ao curry · 3 vezes'),
      findsOneWidget,
    );
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

    expect(find.textContaining('Mais cozinhada'), findsNothing);
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

  testWidgets('o cartão da conta leva às configurações', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Entre com o Google'), findsOneWidget);
    await tester.tap(find.text('Fazer backup nas configurações'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA AJUSTES'), findsOneWidget);
  });

  testWidgets('tocar em Entrar com Google chama o login', (tester) async {
    _usePhoneSize(tester);
    final auth = FakeAuthService();
    await tester.pumpWidget(_host(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
  });

  testWidgets('logado: mostra o e-mail, usa o nome do Google e permite sair',
      (tester) async {
    _usePhoneSize(tester);
    final auth = FakeAuthService(
      user: const AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza'),
    );
    await tester.pumpWidget(_host(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Conta conectada'), findsOneWidget);
    expect(find.text('ana@x.com'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsNothing);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(find.text('Entre com o Google'), findsOneWidget);
  });

  testWidgets('falha ao entrar mostra a mensagem', (tester) async {
    _usePhoneSize(tester);
    final auth = FakeAuthService()
      ..nextResult = const Err(NetworkFailure('Sem conexão com a internet.'));
    await tester.pumpWidget(_host(auth: auth));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar com Google'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
  });

  testWidgets('a engrenagem do topo abre as configurações', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA AJUSTES'), findsOneWidget);
  });

  testWidgets('os atalhos do livro estão só aqui e abrem suas telas',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    for (final t in [
      'Histórico',
      'Tags',
      'Despensa',
      'Ingredientes',
      'Lixeira'
    ]) {
      expect(find.text(t), findsOneWidget);
    }

    await tester.tap(find.text('Histórico'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA HISTORICO'), findsOneWidget);
  });
}
