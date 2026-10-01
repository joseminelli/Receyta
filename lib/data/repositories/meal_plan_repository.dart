import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/meal_plan_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';

/// Fonte de verdade do planejamento semanal (§RF-04). Toda data que entra é
/// normalizada pra data de calendário (`dayOf`); timestamps sempre UTC.
class MealPlanRepository {
  MealPlanRepository(this._dao, {DateTime Function() clock = DateTime.now})
      : _clock = clock;

  final MealPlanDao _dao;
  final DateTime Function() _clock;

  /// Entradas de [from] até [toExclusive] (datas de calendário), ao vivo.
  Stream<List<MealPlanEntry>> watchRange(DateTime from, DateTime toExclusive) {
    return _dao.watchRange(dayOf(from), dayOf(toExclusive)).map(
          (rows) => [
            for (final r in rows) _toDomain(r.entry, r.recipeName),
          ],
        );
  }

  /// Agenda [recipeId] em [date] na refeição [mealType] (RF-04.2).
  Future<Result<String>> add(
    String recipeId,
    DateTime date,
    MealType mealType, {
    int? servingsOverride,
    String? note,
  }) async {
    try {
      final row = await _dao.add(
        recipeId: recipeId,
        date: dayOf(date),
        mealType: mealType.code,
        at: _clock().toUtc(),
        servingsOverride: servingsOverride,
        note: note,
      );
      return Ok(row.id);
    } catch (e) {
      debugPrint('MealPlanRepository.add: $e');
      return Err(DatabaseFailure('Falha ao agendar a receita', cause: e));
    }
  }

  Future<Result<void>> remove(String id) async {
    try {
      await _dao.remove(id);
      return const Ok(null);
    } catch (e) {
      debugPrint('MealPlanRepository.remove: $e');
      return Err(DatabaseFailure('Falha ao remover do plano', cause: e));
    }
  }

  /// Muda a entrada de dia e/ou refeição (RF-04.3).
  Future<Result<void>> move(
    String id,
    DateTime date,
    MealType mealType,
  ) async {
    try {
      await _dao.move(
        id,
        date: dayOf(date),
        mealType: mealType.code,
        at: _clock().toUtc(),
      );
      return const Ok(null);
    } catch (e) {
      debugPrint('MealPlanRepository.move: $e');
      return Err(DatabaseFailure('Falha ao mover a refeição', cause: e));
    }
  }

  /// Copia a entrada pra outro dia/refeição (RF-04.3); a cópia nasce não feita.
  Future<Result<String>> duplicate(
    String id,
    DateTime date,
    MealType mealType,
  ) async {
    try {
      final row = await _dao.duplicate(
        id,
        date: dayOf(date),
        mealType: mealType.code,
        at: _clock().toUtc(),
      );
      if (row == null) return const Err(NotFoundFailure('Refeição não encontrada.'));
      return Ok(row.id);
    } catch (e) {
      debugPrint('MealPlanRepository.duplicate: $e');
      return Err(DatabaseFailure('Falha ao duplicar a refeição', cause: e));
    }
  }

  Future<Result<void>> setDone(String id, bool done) async {
    try {
      await _dao.setDone(id, done, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      debugPrint('MealPlanRepository.setDone: $e');
      return Err(DatabaseFailure('Falha ao marcar a refeição', cause: e));
    }
  }

  /// Desfaz uma remoção: agenda de novo o mesmo conteúdo (id novo).
  Future<Result<String>> restore(MealPlanEntry entry) => add(
        entry.recipeId,
        entry.date,
        entry.mealType,
        servingsOverride: entry.servingsOverride,
        note: entry.note,
      );

  MealPlanEntry _toDomain(MealPlanEntryRow r, String recipeName) =>
      MealPlanEntry(
        id: r.id,
        recipeId: r.recipeId,
        recipeName: recipeName,
        date: dayOf(r.date),
        mealType: MealType.fromCode(r.mealType),
        servingsOverride: r.servingsOverride,
        note: r.note,
        done: r.done,
      );
}

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(ref.watch(databaseProvider).mealPlanDao);
});
