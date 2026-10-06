import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';
import 'package:receyta/core/sync_kinds.dart';

part 'meal_plan_dao.g.dart';

/// Acesso bruto ao planejamento semanal (§RF-04): receitas agendadas por dia
/// e refeição. Receita na lixeira some do plano (volta se for restaurada).
@DriftAccessor(tables: [MealPlanEntries, SharedMeals, Recipes, CookLogs])
class MealPlanDao extends DatabaseAccessor<AppDatabase>
    with _$MealPlanDaoMixin {
  MealPlanDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  /// Entradas de [from] (inclusive) até [toExclusive], com a receita, em
  /// ordem de dia e de criação. Stream vivo.
  Stream<List<({MealPlanEntryRow entry, RecipeRow recipe})>> watchRange(
    DateTime from,
    DateTime toExclusive,
  ) {
    final query = select(mealPlanEntries).join([
      innerJoin(recipes, recipes.id.equalsExp(mealPlanEntries.recipeId)),
    ])
      ..where(
        mealPlanEntries.date.isBiggerOrEqualValue(from) &
            mealPlanEntries.date.isSmallerThanValue(toExclusive) &
            recipes.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm.asc(mealPlanEntries.date),
        OrderingTerm.asc(mealPlanEntries.createdAt),
      ]);
    return query.watch().map(
          (rows) => [
            for (final r in rows)
              (
                entry: r.readTable(mealPlanEntries),
                recipe: r.readTable(recipes),
              ),
          ],
        );
  }

  /// Agendamentos ainda por fazer de [recipeId] de [from] em diante, do mais
  /// próximo ao mais distante — o cartão "agenda" da receita.
  Stream<List<({MealPlanEntryRow entry, RecipeRow recipe})>>
      watchUpcomingForRecipe(String recipeId, DateTime from) {
    final query = select(mealPlanEntries).join([
      innerJoin(recipes, recipes.id.equalsExp(mealPlanEntries.recipeId)),
    ])
      ..where(
        mealPlanEntries.recipeId.equals(recipeId) &
            mealPlanEntries.done.equals(false) &
            mealPlanEntries.date.isBiggerOrEqualValue(from) &
            recipes.deletedAt.isNull(),
      )
      ..orderBy([
        OrderingTerm.asc(mealPlanEntries.date),
        OrderingTerm.asc(mealPlanEntries.createdAt),
      ]);
    return query.watch().map(
          (rows) => [
            for (final r in rows)
              (
                entry: r.readTable(mealPlanEntries),
                recipe: r.readTable(recipes),
              ),
          ],
        );
  }

  Future<MealPlanEntryRow?> findById(String id) {
    return (select(mealPlanEntries)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<MealPlanEntryRow> add({
    required String recipeId,
    required DateTime date,
    required String mealType,
    required DateTime at,
    int? servingsOverride,
    String? note,
    String? spaceId,
  }) async {
    final row = MealPlanEntryRow(
      id: _uuid.v4(),
      recipeId: recipeId,
      date: date,
      mealType: mealType,
      servingsOverride: servingsOverride,
      note: note,
      done: false,
      createdAt: at,
      updatedAt: at,
      spaceId: spaceId,
    );
    await into(mealPlanEntries).insert(row);
    return row;
  }

  /// Tira a refeição do plano; se já tinha sido sincronizada, avisa a nuvem
  /// (H4).
  Future<int> remove(String id) {
    return transaction(() async {
      final row = await findById(id);
      final count =
          await (delete(mealPlanEntries)..where((e) => e.id.equals(id))).go();
      if (row?.syncedAt != null) {
        await attachedDatabase.addTombstone(
          kSyncKindMealPlan,
          id,
          spaceId: row!.spaceId,
        );
      }
      return count;
    });
  }

  /// Refeições que mudaram desde a última sincronização ou nunca subiram, do
  /// escopo pedido: a conta ([spaceId] nulo) ou uma casa.
  Future<List<MealPlanEntryRow>> dirtyForSync({String? spaceId}) {
    return (select(mealPlanEntries)
          ..where((e) =>
              (spaceId == null
                  ? e.spaceId.isNull()
                  : e.spaceId.equals(spaceId)) &
              (e.syncedAt.isNull() | e.updatedAt.isBiggerThan(e.syncedAt))))
        .get();
  }

  /// Passa as refeições de [from] em diante pra casa [spaceId]. O que já tinha
  /// subido pra conta deixa aviso de exclusão lá, e tudo volta a "nunca
  /// sincronizado" pra subir pra casa. O passado fica só da pessoa.
  Future<int> shareFrom(String spaceId, DateTime from) {
    return transaction(() async {
      final rows = await (select(mealPlanEntries)
            ..where(
                (e) => e.spaceId.isNull() & e.date.isBiggerOrEqualValue(from)))
          .get();
      for (final e in rows) {
        if (e.syncedAt != null) {
          await attachedDatabase.addTombstone(kSyncKindMealPlan, e.id);
        }
        await (attachedDatabase.delete(attachedDatabase.syncTombstones)
              ..where((t) =>
                  t.kind.equals(kSyncKindMealPlan) &
                  t.id.equals(e.id) &
                  t.spaceId.equals(spaceId)))
            .go();
      }
      await (update(mealPlanEntries)
            ..where(
                (e) => e.spaceId.isNull() & e.date.isBiggerOrEqualValue(from)))
          .write(MealPlanEntriesCompanion(
        spaceId: Value(spaceId),
        syncedAt: const Value(null),
      ));
      return rows.length;
    });
  }

  /// Deixa de compartilhar o calendário: as refeições da pessoa voltam a ser só
  /// dela (e sobem pra conta), com aviso de exclusão pra casa, e somem as
  /// refeições que eram dos outros.
  Future<void> unshare(String spaceId) {
    return transaction(() async {
      final rows = await (select(mealPlanEntries)
            ..where((e) => e.spaceId.equals(spaceId)))
          .get();
      for (final e in rows) {
        if (e.syncedAt != null) {
          await attachedDatabase.addTombstone(
            kSyncKindMealPlan,
            e.id,
            spaceId: spaceId,
          );
        }
      }
      await (update(mealPlanEntries)..where((e) => e.spaceId.equals(spaceId)))
          .write(const MealPlanEntriesCompanion(
        spaceId: Value(null),
        syncedAt: Value(null),
      ));
      await (delete(sharedMeals)..where((m) => m.spaceId.equals(spaceId))).go();
    });
  }

  // ---------------------------------------------------------------------
  // Refeições de outras pessoas da casa
  // ---------------------------------------------------------------------

  Stream<List<SharedMealRow>> watchShared(DateTime from, DateTime toExclusive) {
    return (select(sharedMeals)
          ..where((m) =>
              m.date.isBiggerOrEqualValue(from) &
              m.date.isSmallerThanValue(toExclusive))
          ..orderBy([
            (m) => OrderingTerm.asc(m.date),
            (m) => OrderingTerm.asc(m.createdAt),
          ]))
        .watch();
  }

  Future<SharedMealRow?> findShared(String id) {
    return (select(sharedMeals)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> putShared(SharedMealRow row) =>
      into(sharedMeals).insertOnConflictUpdate(row);

  Future<List<SharedMealRow>> dirtySharedMeals(String spaceId) {
    return (select(sharedMeals)
          ..where((m) =>
              m.spaceId.equals(spaceId) &
              (m.syncedAt.isNull() | m.updatedAt.isBiggerThan(m.syncedAt))))
        .get();
  }

  Future<int> markSharedSynced(String id, DateTime updatedAt) {
    return (update(sharedMeals)..where((m) => m.id.equals(id)))
        .write(SharedMealsCompanion(syncedAt: Value(updatedAt)));
  }

  /// Apaga o aviso de exclusão de uma refeição da casa (desfazer a remoção).
  Future<int> clearTombstone(String id, String spaceId) {
    return (attachedDatabase.delete(attachedDatabase.syncTombstones)
          ..where((t) =>
              t.kind.equals(kSyncKindMealPlan) &
              t.id.equals(id) &
              t.spaceId.equals(spaceId)))
        .go();
  }

  Future<int> deleteSharedRaw(String id) =>
      (delete(sharedMeals)..where((m) => m.id.equals(id))).go();

  /// Tira a refeição de outra pessoa daqui e avisa a casa.
  Future<int> removeShared(String id) {
    return transaction(() async {
      final row = await findShared(id);
      if (row == null) return 0;
      final count = await deleteSharedRaw(id);
      await attachedDatabase.addTombstone(
        kSyncKindMealPlan,
        id,
        spaceId: row.spaceId,
      );
      return count;
    });
  }

  Future<int> setSharedDone(String id, bool done, DateTime at) {
    return (update(sharedMeals)..where((m) => m.id.equals(id))).write(
      SharedMealsCompanion(done: Value(done), updatedAt: Value(at)),
    );
  }

  Future<int> moveShared(
    String id, {
    required DateTime date,
    required String mealType,
    required DateTime at,
  }) {
    return (update(sharedMeals)..where((m) => m.id.equals(id))).write(
      SharedMealsCompanion(
        date: Value(date),
        mealType: Value(mealType),
        updatedAt: Value(at),
      ),
    );
  }

  Future<int> markSynced(String id, DateTime updatedAt) {
    return (update(mealPlanEntries)..where((e) => e.id.equals(id)))
        .write(MealPlanEntriesCompanion(syncedAt: Value(updatedAt)));
  }

  Future<int> move(
    String id, {
    required DateTime date,
    required String mealType,
    required DateTime at,
  }) {
    return (update(mealPlanEntries)..where((e) => e.id.equals(id))).write(
      MealPlanEntriesCompanion(
        date: Value(date),
        mealType: Value(mealType),
        updatedAt: Value(at),
      ),
    );
  }

  /// Cópia da entrada (mesma receita, porções e nota; nunca feita) em outro
  /// dia/refeição.
  Future<MealPlanEntryRow?> duplicate(
    String id, {
    required DateTime date,
    required String mealType,
    required DateTime at,
  }) async {
    final source = await findById(id);
    if (source == null) return null;
    return add(
      recipeId: source.recipeId,
      date: date,
      mealType: mealType,
      at: at,
      servingsOverride: source.servingsOverride,
      note: source.note,
      spaceId: source.spaceId,
    );
  }

  /// A refeição de [recipeId] ainda por fazer em [day] (a mais antiga, se a
  /// receita está agendada mais de uma vez no dia). Nula se não há.
  Future<String?> firstPendingOn(String recipeId, DateTime day) async {
    final row = await (select(mealPlanEntries)
          ..where(
            (e) =>
                e.recipeId.equals(recipeId) &
                e.done.equals(false) &
                e.date.equals(day),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }

  /// Marca a refeição como feita ou desfaz. Feita, ela entra no histórico
  /// "cozinhei" (G7) — uma vez só por refeição; desfeita, o registro sai.
  Future<int> setDone(String id, bool done, DateTime at) {
    return transaction(() async {
      final written =
          await (update(mealPlanEntries)..where((e) => e.id.equals(id))).write(
        MealPlanEntriesCompanion(done: Value(done), updatedAt: Value(at)),
      );
      if (written == 0) return 0;

      if (!done) {
        final logs = await (select(cookLogs)
              ..where((l) => l.mealPlanEntryId.equals(id)))
            .get();
        await (delete(cookLogs)..where((l) => l.mealPlanEntryId.equals(id)))
            .go();
        for (final l in logs) {
          if (l.syncedAt != null) {
            await attachedDatabase.addTombstone(kSyncKindCookLog, l.id);
          }
        }
        return written;
      }

      final logged = await (select(cookLogs)
            ..where((l) => l.mealPlanEntryId.equals(id))
            ..limit(1))
          .getSingleOrNull();
      if (logged == null) {
        final entry = await (select(mealPlanEntries)
              ..where((e) => e.id.equals(id)))
            .getSingle();
        await into(cookLogs).insert(
          CookLogsCompanion.insert(
            id: _uuid.v4(),
            recipeId: entry.recipeId,
            cookedAt: at,
            mealPlanEntryId: Value(id),
          ),
        );
      }
      return written;
    });
  }
}
