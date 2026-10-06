import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';
import 'package:receyta/core/sync_kinds.dart';

part 'cook_log_dao.g.dart';

/// Acesso bruto ao histórico "cozinhei" (G7).
@DriftAccessor(tables: [CookLogs, Recipes])
class CookLogDao extends DatabaseAccessor<AppDatabase> with _$CookLogDaoMixin {
  CookLogDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  /// Registra que a receita foi feita em [cookedAt]. Devolve o id novo.
  Future<String> add({
    required String recipeId,
    required DateTime cookedAt,
    String? note,
    String? mealPlanEntryId,
    DateTime? createdAt,
  }) async {
    final id = _uuid.v4();
    await into(cookLogs).insert(
      CookLogsCompanion.insert(
        id: id,
        recipeId: recipeId,
        cookedAt: cookedAt,
        note: Value(note),
        mealPlanEntryId: Value(mealPlanEntryId),
        createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
      ),
    );
    return id;
  }

  /// Histórico de uma receita, do mais recente ao mais antigo. Stream vivo.
  Stream<List<CookLogRow>> watchForRecipe(String recipeId) {
    return (select(cookLogs)
          ..where((l) => l.recipeId.equals(recipeId))
          ..orderBy([
            (l) => OrderingTerm.desc(l.cookedAt),
            (l) => OrderingTerm.desc(l.createdAt),
          ]))
        .watch();
  }

  /// Todo o histórico com o nome da receita (as da lixeira ficam de fora),
  /// do mais recente ao mais antigo. Serve às estatísticas e às sugestões.
  Stream<List<({CookLogRow log, RecipeRow recipe})>> watchAllWithRecipe() {
    final query = select(cookLogs).join([
      innerJoin(recipes, recipes.id.equalsExp(cookLogs.recipeId)),
    ])
      ..where(recipes.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(cookLogs.cookedAt)]);
    return query.watch().map(
          (rows) => [
            for (final r in rows)
              (log: r.readTable(cookLogs), recipe: r.readTable(recipes)),
          ],
        );
  }

  /// Apaga o registro; se já tinha sido sincronizado, avisa a nuvem (H4).
  Future<int> remove(String id) {
    return transaction(() async {
      final row = await findById(id);
      final count =
          await (delete(cookLogs)..where((l) => l.id.equals(id))).go();
      if (row?.syncedAt != null) {
        await attachedDatabase.addTombstone(kSyncKindCookLog, id);
      }
      return count;
    });
  }

  Future<int> removeForMealEntry(String mealPlanEntryId) {
    return transaction(() async {
      final rows = await (select(cookLogs)
            ..where((l) => l.mealPlanEntryId.equals(mealPlanEntryId)))
          .get();
      final count = await (delete(cookLogs)
            ..where((l) => l.mealPlanEntryId.equals(mealPlanEntryId)))
          .go();
      for (final r in rows) {
        if (r.syncedAt != null) {
          await attachedDatabase.addTombstone(kSyncKindCookLog, r.id);
        }
      }
      return count;
    });
  }

  Future<CookLogRow?> findById(String id) =>
      (select(cookLogs)..where((l) => l.id.equals(id))).getSingleOrNull();

  /// Registros que mudaram desde a última sincronização ou nunca subiram.
  Future<List<CookLogRow>> dirtyForSync() {
    return (select(cookLogs)
          ..where((l) =>
              l.syncedAt.isNull() | l.updatedAt.isBiggerThan(l.syncedAt)))
        .get();
  }

  Future<int> markSynced(String id, DateTime? updatedAt) {
    return (update(cookLogs)..where((l) => l.id.equals(id)))
        .write(CookLogsCompanion(syncedAt: Value(updatedAt)));
  }

  Future<bool> existsForMealEntry(String mealPlanEntryId) async {
    final row = await (select(cookLogs)
          ..where((l) => l.mealPlanEntryId.equals(mealPlanEntryId))
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }
}
