import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables.dart';

part 'meal_plan_dao.g.dart';

/// Acesso bruto ao planejamento semanal (§RF-04): receitas agendadas por dia
/// e refeição. Receita na lixeira some do plano (volta se for restaurada).
@DriftAccessor(tables: [MealPlanEntries, Recipes])
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
    );
    await into(mealPlanEntries).insert(row);
    return row;
  }

  Future<int> remove(String id) {
    return (delete(mealPlanEntries)..where((e) => e.id.equals(id))).go();
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
    );
  }

  Future<int> setDone(String id, bool done, DateTime at) {
    return (update(mealPlanEntries)..where((e) => e.id.equals(id))).write(
      MealPlanEntriesCompanion(done: Value(done), updatedAt: Value(at)),
    );
  }
}
