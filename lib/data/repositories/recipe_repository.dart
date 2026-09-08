import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/domain/models/recipe.dart';

/// Fonte de verdade do agregado "receita" (§5). Converte linha do Drift ↔
/// model de domínio e traduz falha de banco em [Failure]. Timestamps do
/// domínio são sempre UTC.
class RecipeRepository {
  RecipeRepository(
    this._dao, {
    Uuid uuid = const Uuid(),
    DateTime Function() clock = DateTime.now,
  })  : _uuid = uuid,
        _clock = clock;

  final RecipeDao _dao;
  final Uuid _uuid;
  final DateTime Function() _clock;

  Stream<List<Recipe>> watchAll() =>
      _dao.watchActive().map((rows) => rows.map(_toDomain).toList());

  Future<Result<Recipe>> getById(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) {
        return Err(NotFoundFailure('Receita $id não encontrada'));
      }
      return Ok(_toDomain(row));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao ler a receita', cause: e));
    }
  }

  Future<Result<Recipe>> create({
    required String name,
    String? folderId,
    String? about,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    String? sourceUrl,
    String? notes,
    bool isFavorite = false,
  }) async {
    final now = _clock().toUtc();
    final recipe = Recipe(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
      folderId: folderId,
      about: about,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: servings,
      sourceUrl: sourceUrl,
      notes: notes,
      isFavorite: isFavorite,
    );
    try {
      await _dao.upsert(_toRow(recipe));
      return Ok(recipe);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao criar a receita', cause: e));
    }
  }

  Future<Result<Recipe>> update(Recipe recipe) async {
    final updated = recipe.copyWith(updatedAt: _clock().toUtc());
    try {
      await _dao.upsert(_toRow(updated));
      return Ok(updated);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao salvar a receita', cause: e));
    }
  }

  Future<Result<void>> softDelete(String id) async {
    try {
      await _dao.softDelete(id, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao excluir a receita', cause: e));
    }
  }

  Recipe _toDomain(RecipeRow r) => Recipe(
        id: r.id,
        name: r.name,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        folderId: r.folderId,
        about: r.about,
        prepMinutes: r.prepMinutes,
        cookMinutes: r.cookMinutes,
        servings: r.servings,
        imagePath: r.imagePath,
        sourceUrl: r.sourceUrl,
        notes: r.notes,
        isFavorite: r.isFavorite,
      );

  RecipeRow _toRow(Recipe r) => RecipeRow(
        id: r.id,
        name: r.name,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        folderId: r.folderId,
        about: r.about,
        prepMinutes: r.prepMinutes,
        cookMinutes: r.cookMinutes,
        servings: r.servings,
        imagePath: r.imagePath,
        sourceUrl: r.sourceUrl,
        notes: r.notes,
        isFavorite: r.isFavorite,
        deletedAt: null,
      );
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(databaseProvider).recipeDao);
});
