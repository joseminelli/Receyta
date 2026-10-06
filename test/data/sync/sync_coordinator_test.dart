import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_sync_remote.dart';

const _ana = AppUser(id: 'u1', email: 'ana@x.com', name: 'Ana');

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late FakeSyncRemote remote;
  late FakeAuthService auth;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao);
    remote = FakeSyncRemote();
    auth = FakeAuthService();
    now = DateTime.utc(2026, 3, 1, 12);
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncRemoteProvider.overrideWithValue(remote),
      authServiceProvider.overrideWithValue(auth),
      imageRemoteProvider.overrideWithValue(const NoImageRemote()),
      syncDebounceProvider.overrideWithValue(const Duration(milliseconds: 30)),
      syncPeriodProvider.overrideWithValue(null),
      syncRetryBaseProvider.overrideWithValue(const Duration(milliseconds: 40)),
      syncClockProvider.overrideWithValue(() => now),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  SyncCoordinator coordinator() =>
      container.read(syncCoordinatorProvider.notifier);
  SyncState state() => container.read(syncCoordinatorProvider);

  Future<void> until(bool Function() condition, {String? reason}) async {
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) fail('tempo esgotado: $reason');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Liga o coordenador com a pessoa [user] já conectada e espera a 1ª rodada.
  Future<void> startLoggedIn() async {
    auth = FakeAuthService(user: _ana);
    container.dispose();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncRemoteProvider.overrideWithValue(remote),
      authServiceProvider.overrideWithValue(auth),
      imageRemoteProvider.overrideWithValue(const NoImageRemote()),
      syncDebounceProvider.overrideWithValue(const Duration(milliseconds: 30)),
      syncPeriodProvider.overrideWithValue(null),
      syncRetryBaseProvider.overrideWithValue(const Duration(milliseconds: 40)),
      syncClockProvider.overrideWithValue(() => now),
    ]);
    container.listen(syncCoordinatorProvider, (_, __) {});
    coordinator().start();
    await until(() => state().lastSyncAt != null, reason: '1ª rodada');
  }

  test('sem conta: nada liga, nada é lido, nada é enviado', () async {
    container.listen(syncCoordinatorProvider, (_, __) {});
    coordinator().start();
    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(state().enabled, isFalse);
    expect(remote.pullCalls, 0);
    expect(remote.pushCalls, 0);
  });

  test('com conta: sincroniza ao ligar e guarda a hora', () async {
    await startLoggedIn();

    expect(state().enabled, isTrue);
    expect(state().phase, SyncPhase.idle);
    expect(state().lastSyncAt, now);
    expect(remote.pullCalls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sync_last_at'), isNotNull);
  });

  test('entrar na conta depois dispara a sincronização na hora', () async {
    container.listen(syncCoordinatorProvider, (_, __) {});
    coordinator().start();
    expect(state().enabled, isFalse);

    auth.nextResult = const Ok(_ana);
    await container.read(authControllerProvider.notifier).signIn();
    await until(() => state().lastSyncAt != null, reason: 'rodada após login');

    expect(state().enabled, isTrue);
  });

  test('uma edição dispara o envio depois do atraso, agrupada', () async {
    await startLoggedIn();
    final before = remote.pushCalls;

    await repo.saveDetail(name: 'Bolo');
    await repo.saveDetail(name: 'Pudim');
    await repo.saveDetail(name: 'Torta');
    await until(() => remote.docs.length == 3, reason: 'envio das 3');

    expect(remote.pushCalls, before + 1,
        reason: 'as três edições viraram UMA rodada');
    expect(await db.recipeDao.dirtyForSync(), isEmpty);
  });

  test('o que a própria sincronização grava no banco não dispara outra rodada',
      () async {
    await startLoggedIn();
    // Chega uma receita da nuvem, como se outro aparelho a tivesse enviado.
    remote.docs['recipe/x'] = SyncDoc(
      kind: 'recipe',
      id: 'x',
      editedAt: DateTime.utc(2026, 2, 1),
      data: {
        'v': 1,
        'id': 'x',
        'name': 'Da nuvem',
        'createdAt': '2026-02-01T00:00:00.000Z',
        'updatedAt': '2026-02-01T00:00:00.000Z',
      },
      updatedAt: DateTime.utc(2026, 2, 1, 0, 0, 30),
    );

    coordinator().requestSync(immediate: true);
    await until(
      () => state().phase == SyncPhase.idle && remote.pullCalls >= 2,
      reason: 'rodada com a receita nova',
    );
    final pulls = remote.pullCalls;
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect((await db.select(db.recipes).get()).single.name, 'Da nuvem');
    expect(remote.pullCalls, pulls, reason: 'sem rodada extra por eco');
  });

  test('falha de rede mostra o erro e tenta de novo sozinha', () async {
    remote.failPull = true;
    auth = FakeAuthService(user: _ana);
    container.dispose();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncRemoteProvider.overrideWithValue(remote),
      authServiceProvider.overrideWithValue(auth),
      imageRemoteProvider.overrideWithValue(const NoImageRemote()),
      syncDebounceProvider.overrideWithValue(const Duration(milliseconds: 30)),
      syncPeriodProvider.overrideWithValue(null),
      syncRetryBaseProvider.overrideWithValue(const Duration(milliseconds: 40)),
      syncClockProvider.overrideWithValue(() => now),
    ]);
    container.listen(syncCoordinatorProvider, (_, __) {});
    coordinator().start();

    await until(() => state().phase == SyncPhase.error,
        reason: 'estado de erro');
    expect(state().failure, isNotNull);
    expect(state().lastSyncAt, isNull);

    remote.failPull = false;
    await until(() => state().lastSyncAt != null, reason: 'nova tentativa');

    expect(state().phase, SyncPhase.idle);
    expect(state().failure, isNull);
  });

  test('o botão "Sincronizar agora" roda na hora', () async {
    await startLoggedIn();
    final pulls = remote.pullCalls;

    coordinator().requestSync(immediate: true);
    await until(() => remote.pullCalls > pulls, reason: 'rodada manual');
  });

  test(
      'pedidos durante uma rodada viram UMA rodada extra, nunca duas ao mesmo tempo',
      () async {
    await startLoggedIn();
    final pulls = remote.pullCalls;

    for (var i = 0; i < 5; i++) {
      coordinator().requestSync(immediate: true);
    }
    await until(
        () => state().phase == SyncPhase.idle && remote.pullCalls > pulls,
        reason: 'rodadas');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(remote.pullCalls - pulls, lessThanOrEqualTo(2));
  });

  test('voltar pro app só sincroniza se já faz tempo', () async {
    await startLoggedIn();
    final pulls = remote.pullCalls;

    now = now.add(const Duration(seconds: 5));
    coordinator().onResumed();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(remote.pullCalls, pulls);

    now = now.add(const Duration(minutes: 2));
    coordinator().onResumed();
    await until(() => remote.pullCalls > pulls, reason: 'sync ao voltar');
  });

  test('sair da conta desliga tudo: edições não geram mais envio', () async {
    await startLoggedIn();

    await auth.signOut();
    await until(() => !state().enabled, reason: 'desligar');
    final pushes = remote.pushCalls;
    final pulls = remote.pullCalls;

    await repo.saveDetail(name: 'Depois de sair');
    await Future<void>.delayed(const Duration(milliseconds: 250));

    expect(remote.pushCalls, pushes);
    expect(remote.pullCalls, pulls);
    expect(state().lastSyncAt, isNull);
  });

  test('a hora da última sincronização volta depois de reabrir o app',
      () async {
    SharedPreferences.setMockInitialValues({
      'sync_last_at': DateTime.utc(2026, 2, 28, 8).toIso8601String(),
    });
    remote.failPull = true;
    auth = FakeAuthService(user: _ana);
    container.dispose();
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncRemoteProvider.overrideWithValue(remote),
      authServiceProvider.overrideWithValue(auth),
      imageRemoteProvider.overrideWithValue(const NoImageRemote()),
      syncDebounceProvider.overrideWithValue(const Duration(milliseconds: 30)),
      syncPeriodProvider.overrideWithValue(null),
      syncRetryBaseProvider.overrideWithValue(const Duration(seconds: 30)),
      syncClockProvider.overrideWithValue(() => now),
    ]);
    container.listen(syncCoordinatorProvider, (_, __) {});
    coordinator().start();

    await until(() => state().lastSyncAt != null, reason: 'hora salva');

    expect(state().lastSyncAt, DateTime.utc(2026, 2, 28, 8));
  });
}
