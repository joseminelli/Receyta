import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/data/space/space_remote.dart';
import 'package:receyta/data/sync/shared_remote.dart';
import 'package:receyta/data/sync/sync_coordinator.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_space_remote.dart';
import '../../helpers/fake_sync_remote.dart';

class _FakeShared implements SharedRemote {
  @override
  String? userId = 'ana';

  int pullCalls = 0;
  final pushed = <SyncDoc>[];
  final events = StreamController<SharedChange>.broadcast();

  @override
  Future<void> push(String spaceId, List<SyncDoc> docs) async =>
      pushed.addAll(docs);

  @override
  Future<List<SyncDoc>> pullSince(String spaceId, DateTime? since) async {
    pullCalls++;
    return const [];
  }

  @override
  Stream<SharedChange> changes(String spaceId) => events.stream;
}

const _ana = AppUser(id: 'ana', email: 'ana@x.com', name: 'Ana');

void main() {
  late AppDatabase db;
  late _FakeShared shared;
  late FakeSpaceRemote spaces;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shared = _FakeShared();
    spaces = FakeSpaceRemote(
      space: const SpaceInfo(
        id: 'casa-1',
        name: 'Casa',
        ownerId: 'ana',
        members: [
          SpaceMember(userId: 'ana', displayName: 'Ana', isOwner: true),
        ],
      ),
    );
    container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      syncRemoteProvider.overrideWithValue(FakeSyncRemote()),
      sharedRemoteProvider.overrideWithValue(shared),
      spaceRemoteProvider.overrideWithValue(spaces),
      authServiceProvider.overrideWithValue(FakeAuthService(user: _ana)),
      imageRemoteProvider.overrideWithValue(const NoImageRemote()),
      syncDebounceProvider.overrideWithValue(const Duration(milliseconds: 30)),
      syncPeriodProvider.overrideWithValue(null),
      syncRetryBaseProvider.overrideWithValue(const Duration(milliseconds: 40)),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> until(bool Function() condition, {String? reason}) async {
    final end = DateTime.now().add(const Duration(seconds: 5));
    while (!condition()) {
      if (DateTime.now().isAfter(end)) fail('tempo esgotado: $reason');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> start() async {
    await db.ensureReady();
    container.listen(syncCoordinatorProvider, (_, __) {});
    container.listen(spaceControllerProvider, (_, __) {});
    await container.read(authUserProvider.future);
    await container.read(spaceControllerProvider.future);
    container.read(syncCoordinatorProvider.notifier).start();
    await until(() => shared.pullCalls > 0, reason: 'rodada da casa');
  }

  test('com casa, a rodada também sincroniza a casa', () async {
    await start();

    expect(container.read(syncCoordinatorProvider).phase, SyncPhase.idle);
    expect(shared.pullCalls, greaterThan(0));
  });

  test('uma lista compartilhada nova sobe pra casa, não pra conta', () async {
    await start();

    final list = await db.shoppingListDao
        .create(name: 'Feira', items: const [], at: DateTime.utc(2026, 2, 1));
    await db.shoppingListDao
        .setSpace(list.id, 'casa-1', DateTime.utc(2026, 2, 2));
    await until(() => shared.pushed.isNotEmpty, reason: 'envio à casa');

    expect(shared.pushed.single.kind, 'shopping_list');
    expect(shared.pushed.single.id, list.id);
  });

  test('aviso em tempo real de mudança dispara uma rodada logo', () async {
    await start();
    await until(() => shared.events.hasListener, reason: 'canal assinado');
    final before = shared.pullCalls;

    shared.events.add(SharedChange.docs);
    await until(() => shared.pullCalls > before, reason: 'rodada pelo aviso');
  });

  test('aviso de que alguém saiu manda reler a casa', () async {
    await start();

    await until(() => shared.events.hasListener, reason: 'canal assinado');
    spaces.space = null;
    shared.events.add(SharedChange.members);
    await until(
      () => container.read(currentSpaceIdProvider) == null,
      reason: 'casa relida',
    );
  });

  test('sem casa, só a conta sincroniza', () async {
    spaces.space = null;
    await db.ensureReady();
    container.listen(syncCoordinatorProvider, (_, __) {});
    container.listen(spaceControllerProvider, (_, __) {});
    await container.read(authUserProvider.future);
    await container.read(spaceControllerProvider.future);
    container.read(syncCoordinatorProvider.notifier).start();
    await until(
      () => container.read(syncCoordinatorProvider).lastSyncAt != null,
      reason: 'rodada da conta',
    );

    expect(shared.pullCalls, 0);
  });

  test('marcar um item da lista compartilhada sobe sozinho, sem sincronizar',
      () async {
    await start();
    final list = await db.shoppingListDao
        .create(name: 'Feira', items: const [], at: DateTime.utc(2026, 2, 1));
    await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
    await db.shoppingListDao
        .setSpace(list.id, 'casa-1', DateTime.utc(2026, 2, 2));
    await until(
      () => shared.pushed.any((d) => d.kind == 'shopping_item'),
      reason: 'envio inicial',
    );
    shared.pushed.clear();

    final item = (await db.shoppingListDao.itemsOf(list.id)).single;
    await (db.update(db.shoppingListItems)..where((i) => i.id.equals(item.id)))
        .write(const ShoppingListItemsCompanion(checked: Value(true)));

    await until(
      () => shared.pushed.any((d) => d.kind == 'shopping_item'),
      reason: 'envio do item marcado',
    );
  });

  test('marcar como feita a refeição de outra pessoa sobe sozinho', () async {
    SharedPreferences.setMockInitialValues({'space_calendar_ana': true});
    await start();
    final meal = SharedMealRow(
      id: 'm1',
      spaceId: 'casa-1',
      date: DateTime.utc(2026, 3, 10),
      mealType: 'lunch',
      done: false,
      recipeJson: '{"id":"r1","name":"Bolo"}',
      authorId: 'beto',
      authorName: 'Beto',
      createdAt: DateTime.utc(2026, 3, 1),
      updatedAt: DateTime.utc(2026, 3, 1),
      syncedAt: DateTime.utc(2026, 3, 1),
    );
    await db.mealPlanDao.putShared(meal);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    shared.pushed.clear();

    await db.mealPlanDao.setSharedDone('m1', true, DateTime.utc(2026, 3, 2));

    await until(
      () => shared.pushed.any((d) => d.kind == 'meal_plan'),
      reason: 'envio da refeição marcada',
    );
  });
}
