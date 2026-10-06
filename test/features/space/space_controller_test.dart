import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_space_remote.dart';

const _ana = AppUser(id: 'ana', email: 'ana@x.com', name: 'Ana Souza');

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureReady();
  });

  tearDown(() => db.close());

  ProviderContainer make({AppUser? user = _ana, FakeSpaceRemote? remote}) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      authServiceProvider.overrideWithValue(FakeAuthService(user: user)),
      spaceRemoteProvider.overrideWithValue(remote ?? FakeSpaceRemote()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<SpaceController> ready(ProviderContainer c) async {
    await c.read(authUserProvider.future);
    await c.read(spaceControllerProvider.future);
    return c.read(spaceControllerProvider.notifier);
  }

  Future<String> sharedList(String space) async {
    final list = await db.shoppingListDao
        .create(name: 'Feira', items: const [], at: DateTime.utc(2026, 2, 1));
    await db.shoppingListDao.setSpace(list.id, space, DateTime.utc(2026, 2, 2));
    return list.id;
  }

  test('sem conta, não há casa', () async {
    final c = make(user: null);
    await c.read(authUserProvider.future);
    expect(await c.read(spaceControllerProvider.future), isNull);
  });

  test('criar uma casa guarda o id e usa o primeiro nome', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);

    final result = await controller.create();

    expect(result.isOk, isTrue);
    expect(c.read(currentSpaceIdProvider), 'casa-1');
    expect(remote.space!.members.single.displayName, 'Ana');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('${SpaceController.cachePrefix}ana'), 'casa-1');
  });

  test('código inválido vira mensagem clara e não entra', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);

    remote.failWith = Exception('invalid_invite');
    final result = await controller.join('ZZZZ9999');

    expect(result, isA<Err<SpaceInfo>>());
    expect((result as Err).failure.message, contains('não vale mais'));
    expect(c.read(currentSpaceIdProvider), isNull);
  });

  test('código curto demais nem vai ao servidor', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    remote.failWith = Exception('não devia chamar');

    final result = await controller.join(' ab ');

    expect(result, isA<Err<SpaceInfo>>());
    expect(remote.failWith, isNotNull);
  });

  test('entrar numa casa com código', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);

    final result = await controller.join(' abcd1234 ');

    expect(result.isOk, isTrue);
    expect(c.read(currentSpaceIdProvider), 'casa-1');
    expect(c.read(spaceControllerProvider).requireValue!.members, hasLength(2));
  });

  test('sair da casa deixa as listas só da pessoa, prontas pra subir',
      () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    await controller.create();
    final id = await sharedList('casa-1');
    await db.shoppingListDao.markListSynced(id, DateTime.utc(2026, 2, 2));

    final result = await controller.leave();

    expect(result.isOk, isTrue);
    expect(remote.leaveCalls, 1);
    expect(c.read(currentSpaceIdProvider), isNull);
    final list = await db.select(db.shoppingLists).getSingle();
    expect(list.spaceId, isNull);
    expect(list.syncedAt, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('${SpaceController.cachePrefix}ana'), isNull);
  });

  test('se a rede falhar ao sair, nada muda', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    await controller.create();
    final id = await sharedList('casa-1');

    remote.failWith = Exception('SocketException');
    final result = await controller.leave();

    expect(result, isA<Err<void>>());
    expect(c.read(currentSpaceIdProvider), 'casa-1');
    final list = await db.select(db.shoppingLists).getSingle();
    expect(list.id, id);
    expect(list.spaceId, 'casa-1');
  });

  test(
      'removido pelo dono: ao reler, a casa some e as listas voltam pra pessoa',
      () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    await controller.create();
    await sharedList('casa-1');

    remote.space = null;
    await controller.refresh();

    expect(c.read(currentSpaceIdProvider), isNull);
    expect((await db.select(db.shoppingLists).getSingle()).spaceId, isNull);
  });

  test('sem internet ao reler, mantém a casa que já conhece', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    await controller.create();

    remote.failWith = Exception('SocketException');
    await controller.refresh();

    expect(c.read(currentSpaceIdProvider), 'casa-1');
  });

  test('compartilhar uma lista exige casa; com casa, marca a lista', () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);
    final list = await db.shoppingListDao
        .create(name: 'Feira', items: const [], at: DateTime.utc(2026, 2, 1));

    final sem = await controller.setListShared(list.id, true);
    expect(sem, isA<Err<void>>());

    await controller.create();
    final com = await controller.setListShared(list.id, true);
    expect(com.isOk, isTrue);
    expect((await db.select(db.shoppingLists).getSingle()).spaceId, 'casa-1');

    await controller.setListShared(list.id, false);
    expect((await db.select(db.shoppingLists).getSingle()).spaceId, isNull);
  });

  test('o dono gera convites; quem não é dono recebe o aviso do servidor',
      () async {
    final remote = FakeSpaceRemote();
    final c = make(remote: remote);
    final controller = await ready(c);

    expect((await controller.invite()).valueOrNull, 'ABCD1234');
    remote.failWith = Exception('not_owner');
    final result = await controller.invite();
    expect((result as Err).failure.message, contains('criou a casa'));
  });

  group('normalizeInviteCode', () {
    test('pega o código dentro da mensagem do convite inteira', () {
      const message = 'Entra na minha casa no Receyta! Abra o app, vá em '
          'Conta > Casa > "Tenho um código" e digite: B89982DD (vale por 48 '
          'horas).';
      expect(normalizeInviteCode(message), 'B89982DD');
    });

    test('limpa espaços, símbolos e caixa de um código digitado', () {
      expect(normalizeInviteCode(' b899-82dd '), 'B89982DD');
      expect(normalizeInviteCode('da9dfac0 '), 'DA9DFAC0');
    });

    test('texto sem código de 8 caracteres volta limpo', () {
      expect(normalizeInviteCode('ab c'), 'ABC');
    });
  });

  group('nome na casa', () {
    test('usa o apelido local ao criar a casa', () async {
      final remote = FakeSpaceRemote();
      final c = make(remote: remote);
      await ready(c);
      await c
          .read(appSettingsProvider.notifier)
          .setProfile(nickname: 'Aninha', color: TileColor.coral);

      await c.read(spaceControllerProvider.notifier).create();

      expect(remote.space!.members.single.displayName, 'Aninha');
    });

    test('editar o apelido depois atualiza o nome na casa', () async {
      final remote = FakeSpaceRemote();
      final c = make(remote: remote);
      final controller = await ready(c);
      await controller.create();
      expect(remote.space!.members.single.displayName, 'Ana');

      await c
          .read(appSettingsProvider.notifier)
          .setProfile(nickname: 'Aninha', color: TileColor.coral);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remote.names, ['Aninha']);
      expect(remote.space!.members.single.displayName, 'Aninha');
      expect(c.read(memberNamesProvider)['ana'], 'Aninha');
    });

    test('ao reler a casa, corrige o nome que ficou velho no servidor',
        () async {
      final remote = FakeSpaceRemote();
      final c = make(remote: remote);
      final controller = await ready(c);
      await controller.create();
      await c
          .read(appSettingsProvider.notifier)
          .setProfile(nickname: 'Novo', color: TileColor.coral);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      remote.names.clear();
      remote.space = SpaceInfo(
        id: 'casa-1',
        name: 'Casa',
        ownerId: 'ana',
        members: const [
          SpaceMember(userId: 'ana', displayName: 'Velho', isOwner: true),
        ],
      );

      await controller.refresh();

      expect(remote.names, ['Novo']);
      expect(remote.space!.members.single.displayName, 'Novo');
    });

    test('sem mudança de nome, não chama o servidor à toa', () async {
      final remote = FakeSpaceRemote();
      final c = make(remote: remote);
      final controller = await ready(c);
      await controller.create();

      await controller.refresh();
      await controller.refresh();

      expect(remote.names, isEmpty);
    });
  });
}
