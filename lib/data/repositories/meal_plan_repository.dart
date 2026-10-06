import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/meal_plan_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/shared_meal_codec.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/space/controllers/calendar_share.dart';

/// Fonte de verdade do planejamento semanal (§RF-04). Toda data que entra é
/// normalizada pra data de calendário (`dayOf`); timestamps sempre UTC.
class MealPlanRepository {
  MealPlanRepository(
    this._dao, {
    DateTime Function() clock = DateTime.now,
    String? Function()? spaceIdForNew,
  })  : _clock = clock,
        _spaceIdForNew = spaceIdForNew ?? (() => null);

  final MealPlanDao _dao;
  final DateTime Function() _clock;

  /// Casa em que as refeições novas nascem (nulo = só da pessoa).
  final String? Function() _spaceIdForNew;

  /// Refeições de outras pessoas que a pessoa tirou do plano agora há pouco,
  /// pra "desfazer" poder trazê-las de volta com o mesmo id.
  final _removedShared = <String, SharedMealRow>{};

  /// Entradas de [from] até [toExclusive] (datas de calendário), ao vivo: as
  /// da pessoa e, se ela participa do calendário da casa, as dos outros.
  Stream<List<MealPlanEntry>> watchRange(DateTime from, DateTime toExclusive) {
    final start = dayOf(from);
    final end = dayOf(toExclusive);
    final mine = _dao.watchRange(start, end).map(
          (rows) => [
            for (final r in rows) _toDomain(r.entry, recipeFromRow(r.recipe)),
          ],
        );
    final others = _dao.watchShared(start, end).map(
          (rows) => [
            for (final m in rows)
              if (_sharedToDomain(m) case final e?) e,
          ],
        );
    return _combine(mine, others);
  }

  /// Junta duas listas ao vivo numa só, por dia (as da pessoa antes, em cada
  /// dia). Só emite quando as duas já responderam.
  Stream<List<MealPlanEntry>> _combine(
    Stream<List<MealPlanEntry>> a,
    Stream<List<MealPlanEntry>> b,
  ) {
    late final StreamController<List<MealPlanEntry>> controller;
    StreamSubscription<List<MealPlanEntry>>? subA;
    StreamSubscription<List<MealPlanEntry>>? subB;
    List<MealPlanEntry>? la;
    List<MealPlanEntry>? lb;

    void emit() {
      if (la == null || lb == null || controller.isClosed) return;
      final all = [...la!, ...lb!];
      final order = {for (var i = 0; i < all.length; i++) all[i].id: i};
      all.sort((x, y) {
        final byDay = x.date.compareTo(y.date);
        return byDay != 0 ? byDay : order[x.id]!.compareTo(order[y.id]!);
      });
      controller.add(all);
    }

    controller = StreamController<List<MealPlanEntry>>(
      onListen: () {
        subA = a.listen((v) {
          la = v;
          emit();
        }, onError: controller.addError);
        subB = b.listen((v) {
          lb = v;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  /// Próximos agendamentos (não feitos) de [recipeId] a partir de [from].
  Stream<List<MealPlanEntry>> watchUpcomingForRecipe(
    String recipeId,
    DateTime from,
  ) {
    return _dao.watchUpcomingForRecipe(recipeId, dayOf(from)).map(
          (rows) => [
            for (final r in rows) _toDomain(r.entry, recipeFromRow(r.recipe)),
          ],
        );
  }

  /// O resumo da receita de uma refeição de OUTRA pessoa da casa (ingredientes
  /// e preparo), ou nulo se a refeição não é de outra pessoa ou o resumo não
  /// serve.
  Future<SharedMealRecipe?> sharedRecipeOf(String entryId) async {
    final row = await _dao.findShared(entryId);
    if (row == null) return null;
    try {
      return SharedMealRecipe.parse(jsonDecode(row.recipeJson));
    } catch (_) {
      return null;
    }
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
        spaceId: _spaceIdForNew(),
      );
      return Ok(row.id);
    } catch (e) {
      debugPrint('MealPlanRepository.add: $e');
      return Err(DatabaseFailure('Falha ao agendar a receita', cause: e));
    }
  }

  Future<Result<void>> remove(String id) async {
    try {
      final other = await _dao.findShared(id);
      if (other != null) {
        _removedShared[id] = other;
        await _dao.removeShared(id);
        return const Ok(null);
      }
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
      if (await _dao.findShared(id) != null) {
        await _dao.moveShared(
          id,
          date: dayOf(date),
          mealType: mealType.code,
          at: _clock().toUtc(),
        );
        return const Ok(null);
      }
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
      if (await _dao.findShared(id) != null) {
        return const Err(ValidationFailure(
          'Essa refeição é de outra pessoa da casa. Guarde a receita na sua '
          'biblioteca para planejar do seu jeito.',
        ));
      }
      final row = await _dao.duplicate(
        id,
        date: dayOf(date),
        mealType: mealType.code,
        at: _clock().toUtc(),
      );
      if (row == null) {
        return const Err(NotFoundFailure('Refeição não encontrada.'));
      }
      return Ok(row.id);
    } catch (e) {
      debugPrint('MealPlanRepository.duplicate: $e');
      return Err(DatabaseFailure('Falha ao duplicar a refeição', cause: e));
    }
  }

  /// A pessoa cozinhou [recipeId] agora: se a receita está agendada pra hoje e
  /// ainda não foi feita, marca essa refeição como feita (o que também grava no
  /// histórico "cozinhei") e devolve o id dela. Sem agendamento pendente hoje,
  /// devolve `null` e não faz nada — quem chama registra à parte.
  Future<Result<String?>> markCookedToday(String recipeId) async {
    try {
      final id = await _dao.firstPendingOn(recipeId, dayOf(_clock()));
      if (id == null) return const Ok(null);
      await _dao.setDone(id, true, _clock().toUtc());
      return Ok(id);
    } catch (e) {
      debugPrint('MealPlanRepository.markCookedToday: $e');
      return Err(
          DatabaseFailure('Falha ao marcar a refeição de hoje', cause: e));
    }
  }

  Future<Result<void>> setDone(String id, bool done) async {
    try {
      if (await _dao.findShared(id) != null) {
        await _dao.setSharedDone(id, done, _clock().toUtc());
        return const Ok(null);
      }
      await _dao.setDone(id, done, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      debugPrint('MealPlanRepository.setDone: $e');
      return Err(DatabaseFailure('Falha ao marcar a refeição', cause: e));
    }
  }

  /// Desfaz uma remoção: agenda de novo o mesmo conteúdo (id novo). A refeição
  /// de outra pessoa volta com o mesmo id, pra a casa entender que é a mesma.
  Future<Result<String>> restore(MealPlanEntry entry) async {
    final removed = _removedShared.remove(entry.id);
    if (removed != null) {
      try {
        await _dao.putShared(
          removed.copyWith(
            updatedAt: _clock().toUtc(),
            syncedAt: const Value(null),
          ),
        );
        await _dao.clearTombstone(removed.id, removed.spaceId);
        return Ok(removed.id);
      } catch (e) {
        debugPrint('MealPlanRepository.restore: $e');
        return Err(DatabaseFailure('Falha ao desfazer', cause: e));
      }
    }
    return add(
      entry.recipeId,
      entry.date,
      entry.mealType,
      servingsOverride: entry.servingsOverride,
      note: entry.note,
    );
  }

  MealPlanEntry _toDomain(MealPlanEntryRow r, Recipe recipe) => MealPlanEntry(
        id: r.id,
        recipe: recipe,
        date: dayOf(r.date),
        mealType: MealType.fromCode(r.mealType),
        servingsOverride: r.servingsOverride,
        note: r.note,
        done: r.done,
        spaceId: r.spaceId,
      );

  /// A refeição de outra pessoa, com uma receita montada do resumo que veio
  /// junto (não existe no banco daqui). Resumo ilegível = a refeição some.
  MealPlanEntry? _sharedToDomain(SharedMealRow m) {
    Object? json;
    try {
      json = jsonDecode(m.recipeJson);
    } catch (_) {
      return null;
    }
    final snap = SharedMealRecipe.parse(json);
    if (snap == null) return null;
    return MealPlanEntry(
      id: m.id,
      recipe: Recipe(
        id: snap.id,
        name: snap.name,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
        about: snap.about,
        prepMinutes: snap.prepMinutes,
        cookMinutes: snap.cookMinutes,
        servings: snap.servings,
        tileColor: snap.tileColor,
        tileMotif: snap.tileMotif,
      ),
      date: dayOf(m.date),
      mealType: MealType.fromCode(m.mealType),
      servingsOverride: m.servingsOverride,
      note: m.note,
      done: m.done,
      spaceId: m.spaceId,
      sharedBy: m.authorName.isEmpty ? 'Alguém da casa' : m.authorName,
    );
  }
}

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepository(
    ref.watch(databaseProvider).mealPlanDao,
    spaceIdForNew: () => ref.read(calendarSpaceIdProvider),
  );
});
