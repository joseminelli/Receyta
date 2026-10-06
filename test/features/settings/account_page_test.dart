import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/library_stats.dart';
import 'package:receyta/features/settings/controllers/profile_preview.dart';
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

class _FakeCoordinator extends SyncCoordinator {
  _FakeCoordinator(this.initial);

  final SyncState initial;
  int syncNowCalls = 0;

  @override
  SyncState build() => initial;

  @override
  void requestSync({bool immediate = false}) {
    if (immediate) syncNowCalls++;
  }
}

Widget _host({
  AppSettings initial = const AppSettings(),
  AsyncValue<LibraryStats>? stats,
  FakeAuthService? auth,
  _FakeCoordinator? sync,
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
      if (sync != null) syncCoordinatorProvider.overrideWith(() => sync),
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

  testWidgets(
      'sem conta, o botão de entrar fica no alto, com o aviso de opcional',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Entrar com Google'), findsOneWidget);
    expect(find.textContaining('Opcional'), findsOneWidget);
    final button = tester.getTopLeft(find.text('Entrar com Google')).dy;
    final shortcuts = tester.getTopLeft(find.text('SEU LIVRO')).dy;
    expect(button, lessThan(shortcuts));
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

  testWidgets('logado: usa o nome do Google e esconde o botão de entrar',
      (tester) async {
    _usePhoneSize(tester);
    final auth = FakeAuthService(
      user: const AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza'),
    );
    await tester.pumpWidget(_host(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Entrar com Google'), findsNothing);
    expect(find.text('Sair'), findsNothing);
    expect(find.text('Sair da conta'), findsNothing);
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

  group('prévia da cor do perfil', () {
    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(AccountPage)));

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.text('Seu nome aqui'));
      await tester.pumpAndSettle();
    }

    testWidgets('tocar numa cor muda o perfil na hora, antes de salvar',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      final c = containerOf(tester);
      expect(c.read(effectiveProfileColorProvider), TileColor.coral);

      await openSheet(tester);
      await tester.tap(find.bySemanticsLabel('Cor mar'));
      await tester.pump();

      expect(c.read(effectiveProfileColorProvider), TileColor.mar);
      expect(c.read(appSettingsProvider).profileColor, TileColor.coral);
    });

    testWidgets('cancelar desfaz a prévia e não salva nada', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      final c = containerOf(tester);

      await openSheet(tester);
      await tester.tap(find.bySemanticsLabel('Cor mar'));
      await tester.pump();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(c.read(profileColorPreviewProvider), isNull);
      expect(c.read(effectiveProfileColorProvider), TileColor.coral);
      expect((await loadAppSettings()).profileColor, TileColor.coral);
    });

    testWidgets('fechar arrastando pra baixo também desfaz a prévia',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      final c = containerOf(tester);

      await openSheet(tester);
      await tester.tap(find.bySemanticsLabel('Cor mar'));
      await tester.pump();
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      expect(find.text('Salvar'), findsNothing);
      expect(c.read(effectiveProfileColorProvider), TileColor.coral);
    });

    testWidgets('salvar mantém a cor escolhida', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      final c = containerOf(tester);

      await openSheet(tester);
      await tester.tap(find.bySemanticsLabel('Cor mar'));
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(c.read(effectiveProfileColorProvider), TileColor.mar);
      expect((await loadAppSettings()).profileColor, TileColor.mar);
    });
  });

  group('entrada do perfil ao logar', () {
    double revealScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find
              .descendant(
                of: find.byType(AccountPage),
                matching: find.byType(ScaleTransition),
              )
              .first,
        )
        .scale
        .value;

    testWidgets('ao entrar na conta, nome e foto surgem com bounce',
        (tester) async {
      _usePhoneSize(tester);
      final auth = FakeAuthService()
        ..nextResult = const Ok(
          AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza'),
        );
      await tester.pumpWidget(_host(auth: auth));
      await tester.pumpAndSettle();
      expect(revealScale(tester), 1);

      await tester.tap(find.text('Entrar com Google'));
      await tester.pump();
      await tester.pump();

      expect(revealScale(tester), lessThan(1));
      expect(find.text('Ana'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 150));
      final mid = revealScale(tester);
      expect(mid, isNot(1));

      await tester.pumpAndSettle();
      expect(revealScale(tester), closeTo(1, 0.001));
    });

    testWidgets('abrir a aba com a conta já conectada não anima',
        (tester) async {
      _usePhoneSize(tester);
      final auth = FakeAuthService(
        user: const AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza'),
      );
      await tester.pumpWidget(_host(auth: auth));
      await tester.pump();
      await tester.pump();

      expect(revealScale(tester), 1);
      expect(find.text('Ana'), findsOneWidget);
    });
  });

  group('estado da sincronização', () {
    final now = DateTime.utc(2026, 3, 10, 12);

    _FakeCoordinator coordinator(SyncState state) => _FakeCoordinator(state);

    Widget host(_FakeCoordinator c) => ProviderScope(
          overrides: [
            initialAppSettingsProvider.overrideWithValue(const AppSettings()),
            authServiceProvider.overrideWithValue(FakeAuthService()),
            syncCoordinatorProvider.overrideWith(() => c),
            syncClockProvider.overrideWithValue(() => now),
            libraryStatsProvider.overrideWithValue(
              const AsyncData((
                recipes: 1,
                folders: 0,
                lists: 0,
                plannedMeals: 0,
                doneMeals: 0,
                topRecipe: null,
                topRecipeCount: 0,
              )),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: AccountPage()),
          ),
        );

    testWidgets('sem conta, não aparece nada de sincronização', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(coordinator(const SyncState())));
      await tester.pumpAndSettle();

      expect(find.text('Sincronizar'), findsNothing);
      expect(find.textContaining('Sincronizado'), findsNothing);
    });

    testWidgets('sincronizado: mostra há quanto tempo', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(coordinator(SyncState(
        enabled: true,
        lastSyncAt: now.subtract(const Duration(minutes: 5)),
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Sincronizado · há 5 min'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('ainda sem nenhuma rodada: avisa que está aguardando',
        (tester) async {
      _usePhoneSize(tester);
      await tester
          .pumpWidget(host(coordinator(const SyncState(enabled: true))));
      await tester.pumpAndSettle();

      expect(find.text('Aguardando a primeira sincronização'), findsOneWidget);
    });

    testWidgets('sincronizando: mostra o progresso e trava o botão',
        (tester) async {
      _usePhoneSize(tester);
      final c =
          coordinator(const SyncState(enabled: true, phase: SyncPhase.syncing));
      await tester.pumpWidget(host(c));
      await tester.pump();

      expect(find.text('Sincronizando…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Sincronizar'));
      await tester.pump();
      expect(c.syncNowCalls, 0);
    });

    testWidgets(
        'sem internet: mostra a mensagem do motor, nuvem cortada, '
        'botão Sincronizar', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(coordinator(const SyncState(
        enabled: true,
        phase: SyncPhase.error,
        problem: SyncProblem.offline,
        failure: 'Sem internet. Tentamos de novo sozinhos.',
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Sem internet. Tentamos de novo sozinhos.'),
          findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.text('Sincronizar'), findsOneWidget);
      expect(find.text('Entrar de novo'), findsNothing);
    });

    testWidgets('espaço da nuvem acabou: mensagem própria e ícone de aviso',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(coordinator(const SyncState(
        enabled: true,
        phase: SyncPhase.error,
        problem: SyncProblem.serverFull,
        failure:
            'O espaço da nuvem acabou. Seus dados continuam salvos neste aparelho.',
      ))));
      await tester.pumpAndSettle();

      expect(find.textContaining('espaço da nuvem acabou'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsNothing);
      expect(find.text('Sincronizar'), findsOneWidget);
    });

    testWidgets('sessão vencida: o botão vira "Entrar de novo" e faz o login',
        (tester) async {
      _usePhoneSize(tester);
      final auth = FakeAuthService();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          initialAppSettingsProvider.overrideWithValue(const AppSettings()),
          authServiceProvider.overrideWithValue(auth),
          syncCoordinatorProvider.overrideWith(
            () => coordinator(const SyncState(
              enabled: true,
              phase: SyncPhase.error,
              problem: SyncProblem.auth,
              failure:
                  'Sua sessão expirou. Entre de novo para voltar a sincronizar.',
            )),
          ),
          syncClockProvider.overrideWithValue(() => now),
          libraryStatsProvider.overrideWithValue(
            const AsyncData((
              recipes: 1,
              folders: 0,
              lists: 0,
              plannedMeals: 0,
              doneMeals: 0,
              topRecipe: null,
              topRecipeCount: 0,
            )),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AccountPage()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('sessão expirou'), findsOneWidget);
      expect(find.text('Sincronizar'), findsNothing);
      await tester.tap(find.text('Entrar de novo'));
      await tester.pump();

      expect(auth.signInCalls, 1);
    });

    testWidgets('falha sem mensagem ainda mostra algo útil', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(coordinator(const SyncState(
        enabled: true,
        phase: SyncPhase.error,
      ))));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível sincronizar agora.'), findsOneWidget);
    });

    testWidgets('tocar em Sincronizar pede uma rodada na hora', (tester) async {
      _usePhoneSize(tester);
      final c = coordinator(SyncState(enabled: true, lastSyncAt: now));
      await tester.pumpWidget(host(c));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sincronizar'));
      await tester.pump();

      expect(c.syncNowCalls, 1);
    });
  });

  group('teto de fotos da conta', () {
    const mb = 1024 * 1024;

    Widget host({PhotoQuota? quota, bool enabled = true}) => ProviderScope(
          overrides: [
            initialAppSettingsProvider.overrideWithValue(const AppSettings()),
            authServiceProvider.overrideWithValue(FakeAuthService()),
            syncCoordinatorProvider.overrideWith(
              () => _FakeCoordinator(SyncState(enabled: enabled)),
            ),
            photoQuotaProvider.overrideWith((ref) async => quota),
            libraryStatsProvider.overrideWithValue(
              const AsyncData((
                recipes: 1,
                folders: 0,
                lists: 0,
                plannedMeals: 0,
                doneMeals: 0,
                topRecipe: null,
                topRecipeCount: 0,
              )),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: AccountPage()),
          ),
        );

    PhotoQuota quota(int used, {bool blocked = false, int pending = 0}) =>
        PhotoQuota(
          usedBytes: used,
          quotaBytes: 30 * mb,
          blocked: blocked,
          pending: pending,
        );

    testWidgets('mostra quanto a conta usou e o teto, com a barra',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(quota: quota(12 * mb)));
      await tester.pumpAndSettle();

      expect(find.text('Fotos na nuvem'), findsOneWidget);
      expect(find.text('12 MB de 30 MB'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.4, 0.001));
      expect(find.textContaining('Quase no limite'), findsNothing);
      expect(find.textContaining('Limite atingido'), findsNothing);
    });

    testWidgets('perto do teto (80%) avisa antes de bloquear', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(quota: quota(25 * mb)));
      await tester.pumpAndSettle();

      expect(find.text('25 MB de 30 MB'), findsOneWidget);
      expect(find.textContaining('Quase no limite'), findsOneWidget);
    });

    testWidgets(
        'no teto: explica que as fotos novas ficam só no aparelho e '
        'quantas esperam', (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(
        host(quota: quota(30 * mb, blocked: true, pending: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Limite atingido'), findsOneWidget);
      expect(find.textContaining('só neste aparelho'), findsOneWidget);
      expect(find.textContaining('3 esperando'), findsOneWidget);
      expect(find.textContaining('Quase no limite'), findsNothing);
    });

    testWidgets('no teto e sem fotos esperando, não fala em fila',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(quota: quota(30 * mb, blocked: true)));
      await tester.pumpAndSettle();

      expect(find.textContaining('esperando'), findsNothing);
    });

    testWidgets('sem conta, ou sem o servidor informar o uso, não aparece',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(host(quota: quota(5 * mb), enabled: false));
      await tester.pumpAndSettle();
      expect(find.text('Fotos na nuvem'), findsNothing);

      await tester.pumpWidget(host(quota: null));
      await tester.pumpAndSettle();
      expect(find.text('Fotos na nuvem'), findsNothing);
    });
  });
}
