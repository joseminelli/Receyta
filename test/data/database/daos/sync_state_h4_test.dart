import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receyta/core/sync_kinds.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;
  late DateTime clock;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.ensureReady();
    clock = DateTime.utc(2026, 1, 1, 12);
    repo = RecipeRepository(db.recipeDao, db.tagDao, db.ingredientDao,
        clock: () => clock);
  });
  tearDown(() => db.close());

  Future<String> newRecipe([String name = 'Bolo']) async =>
      ((await repo.saveDetail(name: name)).valueOrNull)!.id;

  Future<List<SyncTombstoneRow>> tombstones() =>
      db.select(db.syncTombstones).get();

  /// O carimbo dos gatilhos é "agora" em UTC, no formato que o Drift lê.
  void expectJustNow(DateTime? at) {
    expect(at, isNotNull);
    expect(at!.isUtc, isTrue);
    expect(DateTime.now().toUtc().difference(at).inSeconds.abs(), lessThan(60));
  }

  group('histórico "cozinhei"', () {
    test('registro novo ganha updated_at (gatilho) e está pendente', () async {
      final id = await newRecipe();

      final logId = await db.cookLogDao.add(
        recipeId: id,
        cookedAt: DateTime.utc(2026, 1, 1),
      );

      final row = (await db.cookLogDao.findById(logId))!;
      expectJustNow(row.updatedAt);
      expect((await db.cookLogDao.dirtyForSync()).map((l) => l.id), [logId]);
    });

    test(
        'depois de sincronizado não está pendente; editar a nota volta a estar',
        () async {
      final id = await newRecipe();
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final row = (await db.cookLogDao.findById(logId))!;
      await db.cookLogDao.markSynced(logId, row.updatedAt);
      expect(await db.cookLogDao.dirtyForSync(), isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await (db.update(db.cookLogs)..where((l) => l.id.equals(logId)))
          .write(const CookLogsCompanion(note: Value('ficou ótimo')));

      expect((await db.cookLogDao.dirtyForSync()), hasLength(1));
    });

    test('marcar como sincronizado não conta como edição (sem laço)', () async {
      final id = await newRecipe();
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final before = (await db.cookLogDao.findById(logId))!.updatedAt;

      await db.cookLogDao.markSynced(logId, before);

      expect((await db.cookLogDao.findById(logId))!.updatedAt, before);
      expect(await db.cookLogDao.dirtyForSync(), isEmpty);
    });

    test('apagar registro sincronizado avisa a nuvem; o que nunca subiu, não',
        () async {
      final id = await newRecipe();
      final synced = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final local = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 2));
      await db.cookLogDao.markSynced(
          synced, (await db.cookLogDao.findById(synced))!.updatedAt);

      await db.cookLogDao.remove(synced);
      await db.cookLogDao.remove(local);

      final t = await tombstones();
      expect(t.map((x) => (x.kind, x.id)), [(kSyncKindCookLog, synced)]);
    });

    test('desfazer "feita" numa refeição apaga o registro e avisa a nuvem',
        () async {
      final id = await newRecipe();
      final entry = await db.mealPlanDao.add(
        recipeId: id,
        date: DateTime.utc(2026, 1, 5),
        mealType: 'dinner',
        at: clock,
      );
      await db.mealPlanDao.setDone(entry.id, true, clock);
      final log = (await db.select(db.cookLogs).get()).single;
      await db.cookLogDao.markSynced(log.id, log.updatedAt);

      await db.mealPlanDao.setDone(entry.id, false, clock);

      expect(await db.select(db.cookLogs).get(), isEmpty);
      expect((await tombstones()).single.id, log.id);
    });

    test('registro some junto com a receita apagada, sem aviso próprio',
        () async {
      final id = await newRecipe();
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      await db.cookLogDao
          .markSynced(logId, (await db.cookLogDao.findById(logId))!.updatedAt);

      await db.recipeDao.hardDelete(id);

      expect(await db.select(db.cookLogs).get(), isEmpty);
      expect((await tombstones()).map((t) => t.kind),
          isNot(contains(kSyncKindCookLog)));
    });
  });

  group('refeições do plano', () {
    test('nova refeição está pendente; sincronizada, não; mover volta a estar',
        () async {
      final id = await newRecipe();
      final entry = await db.mealPlanDao.add(
        recipeId: id,
        date: DateTime.utc(2026, 1, 5),
        mealType: 'lunch',
        at: clock,
      );
      expect(
          (await db.mealPlanDao.dirtyForSync()).map((e) => e.id), [entry.id]);

      await db.mealPlanDao.markSynced(entry.id, entry.updatedAt);
      expect(await db.mealPlanDao.dirtyForSync(), isEmpty);

      await db.mealPlanDao.move(
        entry.id,
        date: DateTime.utc(2026, 1, 6),
        mealType: 'dinner',
        at: clock.add(const Duration(minutes: 1)),
      );
      expect(await db.mealPlanDao.dirtyForSync(), hasLength(1));
    });

    test('tirar do plano: avisa se já subiu, senão não', () async {
      final id = await newRecipe();
      final a = await db.mealPlanDao.add(
        recipeId: id,
        date: DateTime.utc(2026, 1, 5),
        mealType: 'lunch',
        at: clock,
      );
      final b = await db.mealPlanDao.add(
        recipeId: id,
        date: DateTime.utc(2026, 1, 6),
        mealType: 'lunch',
        at: clock,
      );
      await db.mealPlanDao.markSynced(a.id, a.updatedAt);

      await db.mealPlanDao.remove(a.id);
      await db.mealPlanDao.remove(b.id);

      expect((await tombstones()).map((t) => (t.kind, t.id)),
          [(kSyncKindMealPlan, a.id)]);
    });
  });

  group('listas de compras', () {
    Future<ShoppingListItemRow> firstItem() async =>
        (await db.select(db.shoppingListItems).get()).first;

    test('item novo ganha updated_at pelo gatilho e está pendente', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);

      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');

      expectJustNow((await firstItem()).updatedAt);
      expect(await db.shoppingListDao.dirtyItems(), hasLength(1));
    });

    test('marcar o item como comprado conta como mudança', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final item = await firstItem();
      await db.shoppingListDao.markItemSynced(item.id, item.updatedAt);
      expect(await db.shoppingListDao.dirtyItems(), isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.shoppingListDao.setChecked(item.id, true);

      expect(await db.shoppingListDao.dirtyItems(), hasLength(1));
    });

    test('marcar/desmarcar em lote e desmarcar todos também', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Pão');
      for (final i in await db.select(db.shoppingListItems).get()) {
        await db.shoppingListDao.markItemSynced(i.id, i.updatedAt);
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final ids = [
        for (final i in await db.select(db.shoppingListItems).get()) i.id
      ];

      await db.shoppingListDao.setCheckedMany(ids, true);
      expect(await db.shoppingListDao.dirtyItems(), hasLength(2));

      for (final i in await db.select(db.shoppingListItems).get()) {
        await db.shoppingListDao.markItemSynced(i.id, i.updatedAt);
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.shoppingListDao.uncheckAll(list.id);
      expect(await db.shoppingListDao.dirtyItems(), hasLength(2));
    });

    test('marcar como sincronizado não gera nova mudança', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final item = await firstItem();

      await db.shoppingListDao.markItemSynced(item.id, item.updatedAt);

      expect((await firstItem()).updatedAt, item.updatedAt);
      expect(await db.shoppingListDao.dirtyItems(), isEmpty);
    });

    test('renomear a lista e mudar o status contam como mudança da lista',
        () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.markListSynced(list.id, list.updatedAt);
      expect(await db.shoppingListDao.dirtyLists(), isEmpty);

      await db.shoppingListDao.rename(
          list.id, 'Feira da semana', clock.add(const Duration(minutes: 1)));
      expect(await db.shoppingListDao.dirtyLists(), hasLength(1));

      final after = (await db.shoppingListDao.dirtyLists()).single;
      await db.shoppingListDao.markListSynced(list.id, after.updatedAt);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await (db.update(db.shoppingLists)..where((l) => l.id.equals(list.id)))
          .write(const ShoppingListsCompanion(status: Value('done')));

      expect(await db.shoppingListDao.dirtyLists(), hasLength(1));
    });

    test('apagar item sincronizado avisa; item que nunca subiu, não', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Pão');
      final items = await db.select(db.shoppingListItems).get();
      await db.shoppingListDao.markItemSynced(items[0].id, items[0].updatedAt);

      await db.shoppingListDao.deleteItem(items[0].id);
      await db.shoppingListDao.deleteItem(items[1].id);

      expect((await tombstones()).map((t) => (t.kind, t.id)),
          [(kSyncKindShoppingItem, items[0].id)]);
    });

    test('apagar a lista avisa dela e de cada item já sincronizado', () async {
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.markListSynced(list.id, list.updatedAt);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Pão');
      final items = await db.select(db.shoppingListItems).get();
      await db.shoppingListDao.markItemSynced(items[0].id, items[0].updatedAt);

      await db.shoppingListDao.deleteList(list.id);

      final t = await tombstones();
      expect(
        t.map((x) => (x.kind, x.id)).toSet(),
        {
          (kSyncKindShoppingList, list.id),
          (kSyncKindShoppingItem, items[0].id)
        },
      );
      expect(await db.select(db.shoppingListItems).get(), isEmpty);
    });
  });

  group('despensa', () {
    Future<IngredientRow> ingredient() async =>
        (await db.ingredientDao.getOrCreate('Sal'));

    test('ingrediente que nunca foi mexido na despensa não está pendente',
        () async {
      await ingredient();

      expect(await db.ingredientDao.dirtyPantry(), isEmpty);
    });

    test('marcar "sempre tenho" carimba e fica pendente', () async {
      final ing = await ingredient();

      await db.ingredientDao.setInPantry(ing.id, true);

      final row = (await db.ingredientDao.findByIds([ing.id])).single;
      expectJustNow(row.pantryUpdatedAt);
      expect((await db.ingredientDao.dirtyPantry()).map((i) => i.id), [ing.id]);
    });

    test('desmarcar também é mudança (precisa chegar à nuvem)', () async {
      final ing = await ingredient();
      await db.ingredientDao.setInPantry(ing.id, true);
      final marked = (await db.ingredientDao.findByIds([ing.id])).single;
      await db.ingredientDao.markPantrySynced(ing.id, marked.pantryUpdatedAt!);
      expect(await db.ingredientDao.dirtyPantry(), isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      await db.ingredientDao.setInPantry(ing.id, false);

      expect(await db.ingredientDao.dirtyPantry(), hasLength(1));
    });

    test('gravar o mesmo valor de novo não é mudança', () async {
      final ing = await ingredient();
      await db.ingredientDao.setInPantry(ing.id, true);
      final marked = (await db.ingredientDao.findByIds([ing.id])).single;
      await db.ingredientDao.markPantrySynced(ing.id, marked.pantryUpdatedAt!);

      await db.ingredientDao.setInPantry(ing.id, true);

      expect(await db.ingredientDao.dirtyPantry(), isEmpty);
    });

    test('marcar como sincronizado não conta como mudança', () async {
      final ing = await ingredient();
      await db.ingredientDao.setInPantry(ing.id, true);
      final marked = (await db.ingredientDao.findByIds([ing.id])).single;

      await db.ingredientDao.markPantrySynced(ing.id, marked.pantryUpdatedAt!);

      final after = (await db.ingredientDao.findByIds([ing.id])).single;
      expect(after.pantryUpdatedAt, marked.pantryUpdatedAt);
    });
  });

  group('limpar o estado do sync (conta excluída)', () {
    test('tudo volta a "nunca sincronizado" e os avisos somem; os dados ficam',
        () async {
      final id = await newRecipe();
      final entry = await db.mealPlanDao.add(
        recipeId: id,
        date: DateTime.utc(2026, 1, 5),
        mealType: 'lunch',
        at: clock,
      );
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final ing = await db.ingredientDao.getOrCreate('Sal');
      await db.ingredientDao.setInPantry(ing.id, true);

      final recipe = (await db.recipeDao.findIncludingTrashed(id))!;
      await db.recipeDao.markSynced(id, recipe.updatedAt);
      await db.mealPlanDao.markSynced(entry.id, entry.updatedAt);
      await db.shoppingListDao.markListSynced(list.id, list.updatedAt);
      final item = (await db.select(db.shoppingListItems).get()).single;
      await db.shoppingListDao.markItemSynced(item.id, item.updatedAt);
      final log = (await db.cookLogDao.findById(logId))!;
      await db.cookLogDao.markSynced(logId, log.updatedAt);
      final pantry = (await db.ingredientDao.findByIds([ing.id])).single;
      await db.ingredientDao.markPantrySynced(ing.id, pantry.pantryUpdatedAt!);
      await db.addTombstone('recipe', 'velho');
      expect(await db.recipeDao.dirtyForSync(), isEmpty);

      await db.resetSyncState();

      expect(await db.recipeDao.dirtyForSync(), hasLength(1));
      expect(await db.mealPlanDao.dirtyForSync(), hasLength(1));
      expect(await db.shoppingListDao.dirtyLists(), hasLength(1));
      expect(await db.shoppingListDao.dirtyItems(), hasLength(1));
      expect(await db.cookLogDao.dirtyForSync(), hasLength(1));
      expect(await db.ingredientDao.dirtyPantry(), hasLength(1));
      expect(await tombstones(), isEmpty);
    });
  });

  group('banco que já existia (backfill de ensureReady)', () {
    test('histórico e itens antigos ganham updated_at; despensa antiga sobe',
        () async {
      final id = await newRecipe();
      final list =
          await db.shoppingListDao.createEmpty(name: 'Feira', at: clock);
      await db.shoppingListDao.addItem(listId: list.id, manualName: 'Leite');
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final ing = await db.ingredientDao.getOrCreate('Sal');
      // Simula o dado de antes da v9: sem os carimbos.
      await db.customStatement('UPDATE cook_logs SET updated_at = NULL');
      await db
          .customStatement('UPDATE shopping_list_items SET updated_at = NULL');
      await db.customStatement(
          'UPDATE ingredients SET in_pantry = 1, pantry_updated_at = NULL '
          "WHERE id = '${ing.id}'");

      await db.ensureReady();

      expect((await db.cookLogDao.findById(logId))!.updatedAt, isNotNull);
      expect((await db.select(db.shoppingListItems).get()).single.updatedAt,
          isNotNull);
      expect((await db.ingredientDao.dirtyPantry()).map((i) => i.id), [ing.id]);
    });

    test('rodar ensureReady de novo não mexe no que já está carimbado',
        () async {
      final id = await newRecipe();
      final logId = await db.cookLogDao
          .add(recipeId: id, cookedAt: DateTime.utc(2026, 1, 1));
      final before = (await db.cookLogDao.findById(logId))!.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await db.ensureReady();

      expect((await db.cookLogDao.findById(logId))!.updatedAt, before);
    });
  });
}
