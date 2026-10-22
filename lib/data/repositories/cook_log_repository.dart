import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/cook_log_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/repositories/recipe_repository.dart'
    show recipeFromRow;
import 'package:receyta/domain/models/cook_log.dart';

/// Histórico "cozinhei" (G7): registrar, listar e desfazer. Sem lógica de
/// sugestão aqui — isso é dos lembretes (G8/G9), que só leem este histórico.
class CookLogRepository {
  CookLogRepository(this._dao, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final CookLogDao _dao;
  final DateTime Function() _clock;

  /// Marca a receita como feita em [cookedAt] (agora, por padrão). Nota vazia
  /// não é gravada. Devolve o id, pra dar "desfazer" no aviso.
  Future<Result<String>> add(
    String recipeId, {
    DateTime? cookedAt,
    String? note,
    int? rating,
  }) async {
    try {
      final trimmed = note?.trim();
      final id = await _dao.add(
        recipeId: recipeId,
        cookedAt: (cookedAt ?? _clock()).toUtc(),
        note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        rating: _validRating(rating),
      );
      return Ok(id);
    } catch (e) {
      debugPrint('CookLogRepository.add: $e');
      return Err(
          DatabaseFailure('Falha ao registrar que você cozinhou', cause: e));
    }
  }

  /// Grava "como ficou" num registro já feito: estrelas (1 a 5) e uma frase.
  Future<Result<void>> setFeedback(
    String id, {
    int? rating,
    String? note,
  }) async {
    try {
      final trimmed = note?.trim();
      await _dao.setFeedback(
        id,
        rating: _validRating(rating),
        note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      );
      return const Ok(null);
    } catch (e) {
      debugPrint('CookLogRepository.setFeedback: $e');
      return Err(DatabaseFailure('Falha ao salvar como ficou', cause: e));
    }
  }

  /// Id do registro que a refeição agendada gerou ao ser marcada como feita.
  Future<String?> idForMealEntry(String mealPlanEntryId) async =>
      (await _dao.findForMealEntry(mealPlanEntryId))?.id;

  int? _validRating(int? r) => (r == null || r < 1 || r > 5) ? null : r;

  Future<Result<void>> remove(String id) async {
    try {
      await _dao.remove(id);
      return const Ok(null);
    } catch (e) {
      debugPrint('CookLogRepository.remove: $e');
      return Err(DatabaseFailure('Falha ao apagar o registro', cause: e));
    }
  }

  Stream<List<CookLog>> watchForRecipe(String recipeId) =>
      _dao.watchForRecipe(recipeId).map(
            (rows) => [for (final r in rows) _toDomain(r)],
          );

  /// Quantas vezes a receita já foi registrada como feita.
  Future<int> countForRecipe(String recipeId) async =>
      (await _dao.watchForRecipe(recipeId).first).length;

  /// Todo o histórico, com o nome da receita, do mais recente ao mais antigo.
  Stream<List<CookLog>> watchAll() => _dao.watchAllWithRecipe().map(
        (rows) => [
          for (final r in rows)
            _toDomain(r.log, recipeName: r.recipe.name, recipe: r.recipe),
        ],
      );

  CookLog _toDomain(
    CookLogRow r, {
    String recipeName = '',
    RecipeRow? recipe,
  }) =>
      CookLog(
        id: r.id,
        recipeId: r.recipeId,
        recipeName: recipeName,
        cookedAt: r.cookedAt.toLocal(),
        note: r.note,
        rating: r.rating,
        recipe: recipe == null ? null : recipeFromRow(recipe),
      );
}

final cookLogRepositoryProvider = Provider<CookLogRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CookLogRepository(db.cookLogDao);
});
