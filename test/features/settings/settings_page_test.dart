import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/screens/settings_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';

class _FakeReset implements DataResetService {
  final calls = <String>[];
  Result<void> everything = const Ok(null);
  Result<void> account = const Ok(null);

  @override
  RecipeImageService? get images => null;

  @override
  Future<Result<void>> wipeAll() async {
    calls.add('local');
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    calls.add('conta');
    return account;
  }

  @override
  Future<Result<void>> wipeEverything() async {
    calls.add('tudo');
    return everything;
  }
}

Widget _host({
  AppSettings initial = const AppSettings(),
  FakeAuthService? auth,
  _FakeReset? reset,
}) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/welcome', builder: (_, __) => const Text('ROTA WELCOME')),
      GoRoute(path: '/tags', builder: (_, __) => const Text('ROTA TAGS')),
    ],
  );
  return ProviderScope(
    overrides: [
      initialAppSettingsProvider.overrideWithValue(initial),
      authServiceProvider.overrideWithValue(auth ?? FakeAuthService()),
      if (reset != null) dataResetServiceProvider.overrideWithValue(reset),
    ],
    child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
}

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 7200);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _open(WidgetTester tester, String panel) async {
  await tester.tap(find.text(panel));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('as preferências voltam do disco como foram salvas', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appSettingsProvider.notifier);

    await notifier.setTextSize(TextSizeStep.larger);
    await notifier.setHighContrast(true);
    final at = DateTime(2026, 10, 1, 9, 30);
    await notifier.markBackedUp(at);

    final loaded = await loadAppSettings();
    expect(loaded.textSize, TextSizeStep.larger);
    expect(loaded.highContrast, isTrue);
    expect(loaded.lastBackupAt, at);
  });

  test('sem nada salvo, vale o padrão', () async {
    final loaded = await loadAppSettings();
    expect(loaded, const AppSettings());
  });

  testWidgets('mostra as seções e o aviso de que ainda não há backup',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Aparência'), findsOneWidget);
    expect(find.text('Timers e lembretes'), findsOneWidget);
    expect(find.text('Seus dados'), findsOneWidget);
    expect(find.text('Zona de risco'), findsOneWidget);
    expect(find.text('Você ainda não fez backup'), findsOneWidget);
    expect(find.text('Alto contraste'), findsNothing);
  });

  testWidgets('abrir um painel fecha o que estava aberto', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _open(tester, 'Aparência');
    expect(find.text('Alto contraste'), findsOneWidget);

    await _open(tester, 'Seus dados');
    expect(find.text('Alto contraste'), findsNothing);
    expect(find.text('Ver a introdução de novo'), findsOneWidget);

    await _open(tester, 'Seus dados');
    expect(find.text('Ver a introdução de novo'), findsNothing);
  });

  testWidgets('mostra a data do último backup quando há', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      _host(initial: AppSettings(lastBackupAt: DateTime(2026, 9, 12, 8, 5))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Último: 12/09/2026 às 08:05'), findsOneWidget);
    await _open(tester, 'Seus dados');
    expect(find.text('Último: 12/09/2026 às 08:05'), findsNWidgets(2));
  });

  testWidgets('escolher um tamanho de texto atualiza a configuração',
      (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _open(tester, 'Aparência');
    expect(find.text('Normal'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Texto Maior'));
    await tester.pumpAndSettle();

    expect(find.text('Maior'), findsOneWidget);
  });

  testWidgets('o interruptor de alto contraste liga e desliga', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _open(tester, 'Aparência');
    final finder = find.byType(Switch).first;
    expect(tester.widget<Switch>(finder).value, isFalse);

    await tester.tap(find.text('Alto contraste'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(finder).value, isTrue);
  });

  testWidgets('"Ver a introdução de novo" leva às boas-vindas', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _open(tester, 'Seus dados');
    await tester.tap(find.text('Ver a introdução de novo'));
    await tester.pumpAndSettle();

    expect(find.text('ROTA WELCOME'), findsOneWidget);
  });

  testWidgets('sem conta, não há cartão da conta nem "Sair"', (tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('Conectado com o Google'), findsNothing);
    expect(find.text('Sair'), findsNothing);
    expect(find.textContaining('só neste aparelho'), findsOneWidget);
  });

  testWidgets('logado: o cartão da conta mostra o e-mail e sair desconecta',
      (tester) async {
    _usePhoneSize(tester);
    final auth = FakeAuthService(
      user: const AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza'),
    );
    await tester.pumpWidget(_host(auth: auth));
    await tester.pumpAndSettle();

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('ana@x.com'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(find.text('Sair'), findsNothing);
  });

  group('zona de risco', () {
    const ana = AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza');

    testWidgets('sem conta: só "Limpar dados", sem a opção da nuvem',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      expect(find.text('Limpar dados'), findsOneWidget);
      expect(find.text('Apagar tudo, inclusive da conta'), findsNothing);
    });

    testWidgets('com conta: as duas opções, com textos que dizem a diferença',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host(auth: FakeAuthService(user: ana)));
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      expect(find.text('Limpar este aparelho'), findsOneWidget);
      expect(find.textContaining('volta ao sincronizar'), findsOneWidget);
      expect(find.text('Apagar tudo, inclusive da conta'), findsOneWidget);
      expect(find.textContaining('Não dá para desfazer'), findsOneWidget);
    });

    testWidgets('limpar este aparelho avisa que a conta guarda uma cópia',
        (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset();
      await tester.pumpWidget(
        _host(auth: FakeAuthService(user: ana), reset: reset),
      );
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Limpar este aparelho'));
      await tester.pumpAndSettle();
      expect(find.textContaining('A sua conta continua com uma cópia'),
          findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(reset.calls, ['local']);
    });

    testWidgets('apagar tudo exige digitar APAGAR; antes disso o botão não age',
        (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset();
      await tester.pumpWidget(
        _host(auth: FakeAuthService(user: ana), reset: reset),
      );
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Apagar tudo, inclusive da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirme digitando'), findsOneWidget);
      await tester.tap(find.text('Apagar tudo'));
      await tester.pumpAndSettle();
      expect(reset.calls, isEmpty);
      expect(find.text('Confirme digitando'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'apag');
      await tester.pump();
      await tester.tap(find.text('Apagar tudo'));
      await tester.pumpAndSettle();
      expect(reset.calls, isEmpty);

      await tester.enterText(find.byType(TextField), 'apagar');
      await tester.pump();
      await tester.tap(find.text('Apagar tudo'));
      await tester.pumpAndSettle();

      expect(reset.calls, ['tudo']);
      expect(find.text('Confirme digitando'), findsNothing);
    });

    testWidgets('cancelar em qualquer passo não apaga nada', (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset();
      await tester.pumpWidget(
        _host(auth: FakeAuthService(user: ana), reset: reset),
      );
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Apagar tudo, inclusive da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(reset.calls, isEmpty);

      await tester.tap(find.text('Apagar tudo, inclusive da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(reset.calls, isEmpty);
    });

    testWidgets('falha na nuvem termina o fluxo sem derrubar a tela',
        (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset()
        ..everything = const Err(NetworkFailure(
          'Não foi possível apagar os dados da conta. '
          'Nada foi apagado neste aparelho; tente de novo.',
        ));
      await tester.pumpWidget(
        _host(auth: FakeAuthService(user: ana), reset: reset),
      );
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Apagar tudo, inclusive da conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'APAGAR');
      await tester.pump();
      await tester.tap(find.text('Apagar tudo'));
      await tester.pumpAndSettle();

      // O erro vem como mensagem; o aviso em si usa o overlay da raiz (que
      // este host de teste não monta), então aqui só garante que o fluxo
      // terminou sem derrubar a tela.
      expect(reset.calls, ['tudo']);
      expect(find.text('Confirme digitando'), findsNothing);
      expect(find.text('Apagar tudo, inclusive da conta'), findsOneWidget);
    });

    testWidgets('"Excluir minha conta" só aparece com conta conectada',
        (tester) async {
      _usePhoneSize(tester);
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');
      expect(find.text('Excluir minha conta'), findsNothing);

      await tester.pumpWidget(_host(auth: FakeAuthService(user: ana)));
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');
      expect(find.text('Excluir minha conta'), findsOneWidget);
    });

    testWidgets('excluir a conta: avisa o que fica, exige EXCLUIR e desconecta',
        (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset();
      final auth = FakeAuthService(user: ana);
      await tester.pumpWidget(_host(auth: auth, reset: reset));
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      expect(find.textContaining('continua aqui'), findsOneWidget);
      expect(find.textContaining('será uma conta nova'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('digite EXCLUIR'), findsOneWidget);
      await tester.tap(find.text('Excluir conta'));
      await tester.pumpAndSettle();
      expect(reset.calls, isEmpty);

      await tester.enterText(find.byType(TextField), 'apagar');
      await tester.pump();
      await tester.tap(find.text('Excluir conta'));
      await tester.pumpAndSettle();
      expect(reset.calls, isEmpty);

      await tester.enterText(find.byType(TextField), 'excluir');
      await tester.pump();
      await tester.tap(find.text('Excluir conta'));
      await tester.pumpAndSettle();

      expect(reset.calls, ['conta']);
      expect(auth.signOutCalls, 1);
      expect(find.text('Excluir minha conta'), findsNothing);
    });

    testWidgets('cancelar a exclusão não faz nada', (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset();
      final auth = FakeAuthService(user: ana);
      await tester.pumpWidget(_host(auth: auth, reset: reset));
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(reset.calls, isEmpty);
      expect(auth.signOutCalls, 0);
    });

    testWidgets('se o servidor falha, a pessoa continua conectada',
        (tester) async {
      _usePhoneSize(tester);
      final reset = _FakeReset()
        ..account = const Err(NetworkFailure('Sem rede.'));
      final auth = FakeAuthService(user: ana);
      await tester.pumpWidget(_host(auth: auth, reset: reset));
      await tester.pumpAndSettle();
      await _open(tester, 'Zona de risco');

      await tester.tap(find.text('Excluir minha conta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      await tester.tap(find.text('Excluir conta'));
      await tester.pumpAndSettle();

      expect(reset.calls, ['conta']);
      expect(auth.signOutCalls, 0);
      expect(find.text('Excluir minha conta'), findsOneWidget);
    });
  });
}
