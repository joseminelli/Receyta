import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';

/// Fonte de verdade do agregado "receita" (§5): a linha em `recipes` e suas
/// listas de ingredientes e passos. Converte linha do Drift ↔ model de domínio
/// e traduz falha de banco em [Failure]. Timestamps do domínio são sempre UTC.
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

  Stream<RecipeDetail?> watchDetail(String id) {
    return _dao.watchById(id).asyncMap((row) async {
      if (row == null) return null;
      return _detail(row);
    });
  }

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

  Future<Result<RecipeDetail>> getDetail(String id) async {
    try {
      final row = await _dao.findById(id);
      if (row == null) {
        return Err(NotFoundFailure('Receita $id não encontrada'));
      }
      return Ok(await _detail(row));
    } catch (e) {
      return Err(DatabaseFailure('Falha ao ler a receita', cause: e));
    }
  }

  /// Cria (quando [base] é nulo) ou atualiza a receita e reescreve suas listas.
  /// Ingredientes e passos chegam como texto livre já na ordem — o parsing
  /// (bloco C) preenche quantidade, unidade e vínculo depois.
  Future<Result<Recipe>> saveDetail({
    Recipe? base,
    required String name,
    String? about,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    String? notes,
    List<String> ingredientLines = const [],
    List<String> stepLines = const [],
  }) async {
    final now = _clock().toUtc();
    final recipe = base == null
        ? Recipe(
            id: _uuid.v4(),
            name: name,
            createdAt: now,
            updatedAt: now,
            about: about,
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            servings: servings,
            notes: notes,
          )
        : base.copyWith(
            name: name,
            about: about,
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            servings: servings,
            notes: notes,
            updatedAt: now,
          );

    final ingredients = [
      for (var i = 0; i < ingredientLines.length; i++)
        RecipeIngredientRow(
          id: _uuid.v4(),
          recipeId: recipe.id,
          rawText: ingredientLines[i],
          position: i,
        ),
    ];
    final steps = [
      for (var i = 0; i < stepLines.length; i++)
        RecipeStepRow(
          id: _uuid.v4(),
          recipeId: recipe.id,
          instruction: stepLines[i],
          position: i,
        ),
    ];

    try {
      await _dao.saveWithChildren(
        recipe: _toRow(recipe),
        ingredients: ingredients,
        steps: steps,
      );
      return Ok(recipe);
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

  Future<RecipeDetail> _detail(RecipeRow row) async {
    final ingredients = await _dao.ingredientsOf(row.id);
    final steps = await _dao.stepsOf(row.id);
    return RecipeDetail(
      recipe: _toDomain(row),
      ingredients: ingredients.map(_ingredientToDomain).toList(),
      steps: steps.map(_stepToDomain).toList(),
    );
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

  RecipeIngredient _ingredientToDomain(RecipeIngredientRow r) => RecipeIngredient(
        id: r.id,
        recipeId: r.recipeId,
        rawText: r.rawText,
        position: r.position,
        groupLabel: r.groupLabel,
        ingredientId: r.ingredientId,
        quantity: r.quantity,
        unitId: r.unitId,
        qualifier: r.qualifier,
      );

  RecipeStep _stepToDomain(RecipeStepRow r) => RecipeStep(
        id: r.id,
        recipeId: r.recipeId,
        text: r.instruction,
        position: r.position,
        groupLabel: r.groupLabel,
      );
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(databaseProvider).recipeDao);
});
