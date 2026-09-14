import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/domain/engine/ingredient_normalizer.dart';

/// Fonte de verdade do catálogo de ingredientes (§8.2). `getOrCreate` é o
/// ponto de entrada que o parser (C1) usa pra resolver o nome de uma linha
/// num `Ingredient` real, criando quando não existe.
class IngredientRepository {
  IngredientRepository(this._dao);

  final IngredientDao _dao;

  Future<Result<Ingredient>> getOrCreate(String displayName) async {
    final clean = displayName.trim();
    if (clean.isEmpty) {
      return const Err(ValidationFailure('Nome do ingrediente vazio.'));
    }
    try {
      final row = await _dao.getOrCreate(clean);
      return Ok(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao resolver o ingrediente', cause: e));
    }
  }

  Stream<List<Ingredient>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toDomain).toList());

  /// Catálogo com contagem de uso — a tela de gerenciar (C6).
  Stream<List<IngredientWithCount>> watchAllWithCounts() {
    return _dao.watchAllWithCounts().map(
          (rows) => [
            for (final row in rows)
              (ingredient: _toDomain(row.ingredient), count: row.count),
          ],
        );
  }

  /// Junta [sourceId] em [targetId] (C6) — nunca automático, sempre a partir
  /// de uma confirmação explícita na tela de gerenciar.
  Future<Result<void>> merge(String sourceId, String targetId) async {
    if (sourceId == targetId) {
      return const Err(
        ValidationFailure('Escolha um ingrediente diferente pra mesclar.'),
      );
    }
    try {
      await _dao.merge(sourceId, targetId);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao mesclar ingredientes', cause: e));
    }
  }

  Future<Result<void>> confirmAlias(
      String ingredientId, String aliasText) async {
    final key = normalize(aliasText);
    if (key.isEmpty) return const Ok(null);
    try {
      await _dao.addAlias(ingredientId, key);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao gravar o alias', cause: e));
    }
  }

  Ingredient _toDomain(IngredientRow r) => Ingredient(
        id: r.id,
        displayName: r.displayName,
        normalizedKey: r.normalizedKey,
        categoryId: r.categoryId,
        usageCount: r.usageCount,
      );
}

final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return IngredientRepository(db.ingredientDao);
});
