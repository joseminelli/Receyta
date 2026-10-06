import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';

import '../../helpers/fake_auth_service.dart';

const _ana = AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana Souza');

ProviderContainer _container(FakeAuthService service) {
  final c = ProviderContainer(
    overrides: [authServiceProvider.overrideWithValue(service)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('entrar com sucesso devolve null e publica o usuário', () async {
    final service = FakeAuthService()..nextResult = const Ok(_ana);
    final c = _container(service);
    c.listen(authUserProvider, (_, __) {});

    final failure = await c.read(authControllerProvider.notifier).signIn();
    await Future<void>.delayed(Duration.zero);

    expect(failure, isNull);
    expect(c.read(authUserProvider).valueOrNull?.email, 'ana@x.com');
  });

  test('cancelar a janela do Google não é erro nem loga ninguém', () async {
    final service = FakeAuthService()..nextResult = const Ok(null);
    final c = _container(service);

    final failure = await c.read(authControllerProvider.notifier).signIn();

    expect(failure, isNull);
    expect(service.currentUser, isNull);
  });

  test('falha vira Failure pra mostrar na tela', () async {
    final service = FakeAuthService()
      ..nextResult = const Err(NetworkFailure('Sem conexão.'));
    final c = _container(service);

    final failure = await c.read(authControllerProvider.notifier).signIn();

    expect(failure, isA<NetworkFailure>());
    expect(failure!.message, 'Sem conexão.');
  });

  test('sair limpa o usuário', () async {
    final service = FakeAuthService(user: _ana);
    final c = _container(service);
    c.listen(authUserProvider, (_, __) {});

    expect(c.read(authUserProvider).valueOrNull, isNull);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authUserProvider).valueOrNull?.id, 'u1');

    await c.read(authControllerProvider.notifier).signOut();
    await Future<void>.delayed(Duration.zero);

    expect(service.signOutCalls, 1);
    expect(c.read(authUserProvider).valueOrNull, isNull);
  });
}
