import 'package:drift/drift.dart' show Value;

import 'package:receyta/core/sync_kinds.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/sync/shared_meal_sync.dart';
import 'package:receyta/data/sync/sync_handler.dart';
import 'package:receyta/data/sync/sync_remote.dart';
import 'package:receyta/domain/engine/sync_codec_h4.dart';

final _epoch = DateTime.utc(1970);

Future<Set<String>> _ids(AppDatabase db, String table) async {
  final rows = await db.customSelect('SELECT id FROM $table').get();
  return {for (final r in rows) r.read<String>('id')};
}

Future<Set<String>> _unitIds(AppDatabase db) => _ids(db, 'units');

// ===========================================================================
// Histórico "cozinhei"
// ===========================================================================

/// Um registro por vez que a pessoa fez a receita. Só aplica se a receita
/// existe aqui (o registro some junto com ela).
class CookLogSync implements SyncHandler {
  CookLogSync(this.db);

  final AppDatabase db;

  @override
  String get kind => kSyncKindCookLog;

  DateTime _at(CookLogRow l) => l.updatedAt ?? l.createdAt;

  @override
  Future<bool> hasPending() async =>
      (await db.cookLogDao.dirtyForSync()).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    return [
      for (final l in await db.cookLogDao.dirtyForSync())
        (
          doc: SyncDoc(
            kind: kind,
            id: l.id,
            editedAt: _at(l),
            data: cookLogToSyncJson(SyncCookLog(
              id: l.id,
              recipeId: l.recipeId,
              cookedAt: l.cookedAt,
              note: l.note,
              mealPlanEntryId: l.mealPlanEntryId,
              createdAt: l.createdAt,
              updatedAt: _at(l),
            )),
          ),
          onSent: () => db.cookLogDao.markSynced(l.id, _at(l)),
        ),
    ];
  }

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    final recipeIds = await _ids(db, 'recipes');
    var applied = 0;
    var removed = 0;
    for (final d in docs) {
      final local = await db.cookLogDao.findById(d.id);
      if (d.deleted) {
        if (local != null &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: _at(local),
              localSyncedAt: local.syncedAt,
            )) {
          await (db.delete(db.cookLogs)..where((l) => l.id.equals(d.id))).go();
          removed++;
        }
        continue;
      }
      final log = parseCookLogSync(d.data);
      if (log == null || log.id != d.id || !recipeIds.contains(log.recipeId)) {
        continue;
      }
      if (!remoteWins(
        exists: local != null,
        remoteEditedAt: log.updatedAt,
        localUpdatedAt: local == null ? null : _at(local),
        localSyncedAt: local?.syncedAt,
      )) {
        continue;
      }
      final row = CookLogRow(
        id: log.id,
        recipeId: log.recipeId,
        cookedAt: log.cookedAt,
        note: log.note,
        mealPlanEntryId: log.mealPlanEntryId,
        createdAt: log.createdAt,
        updatedAt: log.updatedAt,
        syncedAt: log.updatedAt,
      );
      if (local == null) {
        await db.into(db.cookLogs).insert(row);
      } else {
        await (db.update(db.cookLogs)..where((l) => l.id.equals(log.id)))
            .write(row.toCompanion(false));
      }
      applied++;
    }
    return (applied: applied, removed: removed);
  }
}

// ===========================================================================
// Refeições planejadas (calendário)
// ===========================================================================

/// Uma refeição no calendário. Só aplica se a receita existe aqui.
class MealPlanSync implements SyncHandler {
  MealPlanSync(this.db);

  final AppDatabase db;

  @override
  String get kind => kSyncKindMealPlan;

  @override
  Future<bool> hasPending() async =>
      (await db.mealPlanDao.dirtyForSync()).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    return [
      for (final e in await db.mealPlanDao.dirtyForSync())
        (
          doc: SyncDoc(
            kind: kind,
            id: e.id,
            editedAt: e.updatedAt,
            data: mealPlanToSyncJson(SyncMealPlan(
              id: e.id,
              recipeId: e.recipeId,
              date: e.date,
              mealType: e.mealType,
              servingsOverride: e.servingsOverride,
              note: e.note,
              done: e.done,
              createdAt: e.createdAt,
              updatedAt: e.updatedAt,
            )),
          ),
          onSent: () => db.mealPlanDao.markSynced(e.id, e.updatedAt),
        ),
    ];
  }

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    final recipeIds = await _ids(db, 'recipes');
    var applied = 0;
    var removed = 0;
    for (final d in docs) {
      final local = await db.mealPlanDao.findById(d.id);
      if (d.deleted) {
        if (local != null &&
            local.spaceId == null &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: local.updatedAt,
              localSyncedAt: local.syncedAt,
            )) {
          await (db.delete(db.mealPlanEntries)..where((e) => e.id.equals(d.id)))
              .go();
          removed++;
        }
        continue;
      }
      if (local != null && local.spaceId != null) continue;
      final entry = parseMealPlanSync(d.data);
      if (entry == null ||
          entry.id != d.id ||
          !recipeIds.contains(entry.recipeId)) {
        continue;
      }
      if (!remoteWins(
        exists: local != null,
        remoteEditedAt: entry.updatedAt,
        localUpdatedAt: local?.updatedAt,
        localSyncedAt: local?.syncedAt,
      )) {
        continue;
      }
      final row = MealPlanEntryRow(
        id: entry.id,
        recipeId: entry.recipeId,
        date: entry.date,
        mealType: entry.mealType,
        servingsOverride: entry.servingsOverride,
        note: entry.note,
        done: entry.done,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        syncedAt: entry.updatedAt,
      );
      if (local == null) {
        await db.into(db.mealPlanEntries).insert(row);
      } else {
        await (db.update(db.mealPlanEntries)
              ..where((e) => e.id.equals(entry.id)))
            .write(row.toCompanion(false));
      }
      applied++;
    }
    return (applied: applied, removed: removed);
  }
}

// ===========================================================================
// Listas de compras
// ===========================================================================

/// A lista em si (nome, status). Os itens são outro tipo, `shopping_item`, pra
/// duas pessoas marcando coisas diferentes na mesma lista não se atropelarem.
class ShoppingListSync implements SyncHandler {
  ShoppingListSync(this.db, {this.spaceId});

  final AppDatabase db;

  /// Casa que este tratador sincroniza; nulo = as listas só da pessoa.
  final String? spaceId;

  @override
  String get kind => kSyncKindShoppingList;

  @override
  Future<bool> hasPending() async =>
      (await db.shoppingListDao.dirtyLists(spaceId: spaceId)).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    return [
      for (final l in await db.shoppingListDao.dirtyLists(spaceId: spaceId))
        (
          doc: SyncDoc(
            kind: kind,
            id: l.id,
            editedAt: l.updatedAt,
            data: shoppingListToSyncJson(SyncShoppingList(
              id: l.id,
              name: l.name,
              status: l.status,
              createdAt: l.createdAt,
              updatedAt: l.updatedAt,
            )),
          ),
          onSent: () => db.shoppingListDao.markListSynced(l.id, l.updatedAt),
        ),
    ];
  }

  /// A lista local pode ser sobrescrita por este escopo? A da conta só toma o
  /// que é da conta; a da casa toma o da conta (a lista foi compartilhada) e o
  /// que já é desta casa — nunca o de outra.
  bool _canTake(String? localSpace) => spaceId == null
      ? localSpace == null
      : (localSpace == null || localSpace == spaceId);

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    var applied = 0;
    var removed = 0;
    for (final d in docs) {
      final local = await (db.select(db.shoppingLists)
            ..where((l) => l.id.equals(d.id)))
          .getSingleOrNull();
      if (d.deleted) {
        if (local != null &&
            local.spaceId == spaceId &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: local.updatedAt,
              localSyncedAt: local.syncedAt,
            )) {
          // Os itens e as origens caem em cascata.
          await (db.delete(db.shoppingLists)..where((l) => l.id.equals(d.id)))
              .go();
          removed++;
        }
        continue;
      }
      final list = parseShoppingListSync(d.data);
      if (list == null || list.id != d.id) continue;
      if (local != null && !_canTake(local.spaceId)) continue;
      if (!remoteWins(
        exists: local != null,
        remoteEditedAt: list.updatedAt,
        localUpdatedAt: local?.updatedAt,
        localSyncedAt: local?.syncedAt,
      )) {
        continue;
      }
      final row = ShoppingListRow(
        id: list.id,
        name: list.name,
        status: list.status,
        createdAt: list.createdAt,
        updatedAt: list.updatedAt,
        syncedAt: list.updatedAt,
        spaceId: spaceId,
      );
      if (local == null) {
        await db.into(db.shoppingLists).insert(row);
      } else {
        await (db.update(db.shoppingLists)..where((l) => l.id.equals(list.id)))
            .write(row.toCompanion(false));
      }
      applied++;
    }
    return (applied: applied, removed: removed);
  }
}

/// Cada item da lista (com as receitas de onde veio). Só aplica se a lista
/// existe aqui.
class ShoppingItemSync implements SyncHandler {
  ShoppingItemSync(this.db, {this.spaceId});

  final AppDatabase db;

  /// Casa que este tratador sincroniza; nulo = os itens das listas só da pessoa.
  final String? spaceId;

  @override
  String get kind => kSyncKindShoppingItem;

  DateTime _at(ShoppingListItemRow i) => i.updatedAt ?? _epoch;

  @override
  Future<bool> hasPending() async =>
      (await db.shoppingListDao.dirtyItems(spaceId: spaceId)).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    final items = await db.shoppingListDao.dirtyItems(spaceId: spaceId);
    if (items.isEmpty) return const [];

    final ingredientIds = {
      for (final i in items)
        if (i.ingredientId != null) i.ingredientId!,
    }.toList();
    final names = {
      for (final ing in await db.ingredientDao.findByIds(ingredientIds))
        ing.id: ing.displayName,
    };
    final sources =
        await db.shoppingListDao.sourcesOf([for (final i in items) i.id]);

    final out = <PendingDoc>[];
    for (final i in items) {
      final ingredientName =
          i.ingredientId == null ? null : names[i.ingredientId];
      final hasName = (ingredientName != null && ingredientName.isNotEmpty) ||
          (i.manualName != null && i.manualName!.trim().isNotEmpty);
      // Item sem nome nenhum não tem como existir do outro lado.
      if (!hasName) continue;
      out.add((
        doc: SyncDoc(
          kind: kind,
          id: i.id,
          editedAt: _at(i),
          data: shoppingItemToSyncJson(SyncShoppingItem(
            id: i.id,
            listId: i.listId,
            ingredientName: ingredientName,
            manualName: i.manualName,
            quantity: i.quantity,
            unit: i.unitId,
            checked: i.checked,
            note: i.note,
            position: i.position,
            sources: [
              for (final s in sources)
                if (s.itemId == i.id)
                  SyncItemSource(
                    recipeId: s.recipeId,
                    quantity: s.quantity,
                    unit: s.unitId,
                  ),
            ],
            updatedAt: _at(i),
          )),
        ),
        onSent: () => db.shoppingListDao.markItemSynced(i.id, _at(i)),
      ));
    }
    return out;
  }

  /// Só entra item de lista que existe aqui E é deste escopo.
  Future<Set<String>> _scopedListIds() async {
    final rows = await (db.select(db.shoppingLists)
          ..where((l) => spaceId == null
              ? l.spaceId.isNull()
              : l.spaceId.equals(spaceId!)))
        .get();
    return {for (final l in rows) l.id};
  }

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    final listIds = await _scopedListIds();
    final recipeIds = await _ids(db, 'recipes');
    final units = await _unitIds(db);
    var applied = 0;
    var removed = 0;

    for (final d in docs) {
      final local = await (db.select(db.shoppingListItems)
            ..where((i) => i.id.equals(d.id)))
          .getSingleOrNull();
      if (d.deleted) {
        if (local != null &&
            listIds.contains(local.listId) &&
            remoteWins(
              exists: true,
              remoteEditedAt: d.editedAt,
              localUpdatedAt: _at(local),
              localSyncedAt: local.syncedAt,
            )) {
          await (db.delete(db.shoppingListItems)
                ..where((i) => i.id.equals(d.id)))
              .go();
          removed++;
        }
        continue;
      }
      final item = parseShoppingItemSync(d.data);
      if (item == null || item.id != d.id || !listIds.contains(item.listId)) {
        continue;
      }
      if (!remoteWins(
        exists: local != null,
        remoteEditedAt: item.updatedAt,
        localUpdatedAt: local == null ? null : _at(local),
        localSyncedAt: local?.syncedAt,
      )) {
        continue;
      }

      String? ingredientId;
      if (item.ingredientName != null &&
          item.ingredientName!.trim().isNotEmpty) {
        ingredientId =
            (await db.ingredientDao.getOrCreate(item.ingredientName!)).id;
      }
      final row = ShoppingListItemRow(
        id: item.id,
        listId: item.listId,
        ingredientId: ingredientId,
        manualName: item.manualName,
        quantity: item.quantity,
        unitId:
            (item.unit != null && units.contains(item.unit)) ? item.unit : null,
        checked: item.checked,
        note: item.note,
        position: item.position,
        updatedAt: item.updatedAt,
        syncedAt: item.updatedAt,
      );
      if (local == null) {
        await db.into(db.shoppingListItems).insert(row);
      } else {
        await (db.update(db.shoppingListItems)
              ..where((i) => i.id.equals(item.id)))
            .write(row.toCompanion(false));
      }

      await (db.delete(db.shoppingItemSources)
            ..where((s) => s.itemId.equals(item.id)))
          .go();
      for (final s in item.sources) {
        if (!recipeIds.contains(s.recipeId)) continue;
        await db.into(db.shoppingItemSources).insertOnConflictUpdate(
              ShoppingItemSourcesCompanion.insert(
                itemId: item.id,
                recipeId: s.recipeId,
                quantity: Value(s.quantity),
                unitId: Value(
                  (s.unit != null && units.contains(s.unit)) ? s.unit : null,
                ),
              ),
            );
      }
      applied++;
    }
    return (applied: applied, removed: removed);
  }
}

// ===========================================================================
// Despensa
// ===========================================================================

/// "Sempre tenho" por ingrediente. Nunca é apagada na nuvem — desmarcar é só
/// gravar `inPantry: false` —, então ignora itens apagados.
class PantrySync implements SyncHandler {
  PantrySync(this.db);

  final AppDatabase db;

  @override
  String get kind => kSyncKindPantry;

  @override
  Future<bool> hasPending() async =>
      (await db.ingredientDao.dirtyPantry()).isNotEmpty;

  @override
  Future<List<PendingDoc>> pending() async {
    return [
      for (final i in await db.ingredientDao.dirtyPantry())
        (
          doc: SyncDoc(
            kind: kind,
            id: i.normalizedKey,
            editedAt: i.pantryUpdatedAt!,
            data: pantryToSyncJson(SyncPantry(
              key: i.normalizedKey,
              name: i.displayName,
              inPantry: i.inPantry,
              updatedAt: i.pantryUpdatedAt!,
            )),
          ),
          onSent: () =>
              db.ingredientDao.markPantrySynced(i.id, i.pantryUpdatedAt!),
        ),
    ];
  }

  @override
  Future<ApplyResult> apply(List<SyncDoc> docs) async {
    var applied = 0;
    for (final d in docs) {
      if (d.deleted) continue;
      final p = parsePantrySync(d.data);
      if (p == null || p.key != d.id) continue;

      var local = await (db.select(db.ingredients)
            ..where((i) => i.normalizedKey.equals(p.key)))
          .getSingleOrNull();
      // Ingrediente que nunca teve a despensa mexida conta como "não tem
      // estado aqui": segue a nuvem.
      final hasState = local != null && local.pantryUpdatedAt != null;
      if (!remoteWins(
        exists: hasState,
        remoteEditedAt: p.updatedAt,
        localUpdatedAt: local?.pantryUpdatedAt,
        localSyncedAt: local?.pantrySyncedAt,
      )) {
        continue;
      }
      local ??= await db.ingredientDao.getOrCreate(p.name);
      await (db.update(db.ingredients)..where((i) => i.id.equals(local!.id)))
          .write(IngredientsCompanion(
        inPantry: Value(p.inPantry),
        pantryUpdatedAt: Value(p.updatedAt),
        pantrySyncedAt: Value(p.updatedAt),
      ));
      applied++;
    }
    return (applied: applied, removed: 0);
  }
}

/// Os tratadores na ordem em que aplicam (quem depende de outro vem depois:
/// itens só entram se a lista já existe).
List<SyncHandler> defaultSyncHandlers(AppDatabase db) => [
      PantrySync(db),
      ShoppingListSync(db),
      ShoppingItemSync(db),
      MealPlanSync(db),
      CookLogSync(db),
    ];

/// Os tratadores de uma casa: o que é compartilhado e tem `space_id`. A lista
/// antes dos itens. O calendário só entra quando há como montar o resumo das
/// receitas ([meals]).
List<SyncHandler> sharedSyncHandlers(
  AppDatabase db,
  String spaceId, {
  SharedMealSync? meals,
}) =>
    [
      ShoppingListSync(db, spaceId: spaceId),
      ShoppingItemSync(db, spaceId: spaceId),
      if (meals != null) meals,
    ];
