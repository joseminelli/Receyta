import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tag_name.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/daos/tag_dao.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';
import 'package:receyta/domain/models/tag.dart';

/// Fonte de verdade do agregado "receita" (§5): a linha em `recipes` e suas
/// listas de ingredientes e passos. Converte linha do Drift ↔ model de domínio
/// e traduz falha de banco em [Failure]. Timestamps do domínio são sempre UTC.
class RecipeRepository {
  RecipeRepository(
    this._dao,
    this._tagDao, {
    Uuid uuid = const Uuid(),
    DateTime Function() clock = DateTime.now,
  })  : _uuid = uuid,
        _clock = clock;

  final RecipeDao _dao;
  final TagDao _tagDao;
  final Uuid _uuid;
  final DateTime Function() _clock;

  Stream<List<Recipe>> watchAll({
    Set<String> anyOfTagIds = const {},
    bool favoritesOnly = false,
    bool rootOnly = false,
  }) =>
      _dao
          .watchActive(
            anyOfTagIds: anyOfTagIds,
            favoritesOnly: favoritesOnly,
            rootOnly: rootOnly,
          )
          .map((rows) => rows.map(_toDomain).toList());

  /// Existe alguma receita ativa favoritada? Decide se o chip "Favoritos"
  /// aparece no filtro da home.
  Stream<bool> watchHasFavorites() => _dao
      .watchActive(favoritesOnly: true)
      .map((rows) => rows.isNotEmpty);

  /// Receitas de uma pasta (§RF-02); `folderId` nulo = as soltas na raiz.
  Stream<List<Recipe>> watchInFolder(String? folderId) =>
      _dao.watchInFolder(folderId).map((rows) => rows.map(_toDomain).toList());

  /// As 7 mais recentes (criação ou abertura) — a prateleira da home.
  Stream<List<Recipe>> watchRecent({int limit = 7}) => _dao
      .watchRecent(limit: limit)
      .map((rows) => rows.map(_toDomain).toList());

  /// Busca por nome, sobre, notas e tag (§RF-01.9). Query vazia → lista vazia.
  Stream<List<Recipe>> search(String query) =>
      _dao.search(query).map((rows) => rows.map(_toDomain).toList());

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

    /// Rótulo do grupo de cada linha (§RF-01.4 — "Para a massa"), paralelo às
    /// listas acima. Mais curto ou vazio = sem grupo.
    List<String?> ingredientGroups = const [],
    List<String?> stepGroups = const [],
    List<String> tagNames = const [],
  }) async {
    final now = _clock().toUtc();
    final recipe = base == null
        ? Recipe(
            id: _uuid.v4(),
            name: name,
            createdAt: now,
            updatedAt: now,
            lastOpenedAt: now,
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

    String? groupAt(List<String?> groups, int i) =>
        i < groups.length ? groups[i] : null;

    final ingredients = [
      for (var i = 0; i < ingredientLines.length; i++)
        RecipeIngredientRow(
          id: _uuid.v4(),
          recipeId: recipe.id,
          rawText: ingredientLines[i],
          groupLabel: groupAt(ingredientGroups, i),
          position: i,
        ),
    ];
    final steps = [
      for (var i = 0; i < stepLines.length; i++)
        RecipeStepRow(
          id: _uuid.v4(),
          recipeId: recipe.id,
          instruction: stepLines[i],
          groupLabel: groupAt(stepGroups, i),
          position: i,
        ),
    ];

    final seen = <String>{};
    final canonicalTags = [
      for (final raw in tagNames)
        for (final part in raw.split(',')) canonicalTagName(part),
    ].where((n) => n.isNotEmpty && seen.add(n)).toList();

    try {
      final tagRows = await _tagDao.ensureTags(canonicalTags);
      await _dao.saveWithChildren(
        recipe: _toRow(recipe),
        ingredients: ingredients,
        steps: steps,
        tagIds: [for (final t in tagRows) t.id],
      );
      return Ok(recipe);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao salvar a receita', cause: e));
    }
  }

  /// Marca "aberta agora" — sobe pro topo da prateleira "Recentes" da home.
  Future<Result<void>> markOpened(String id) async {
    try {
      await _dao.setLastOpenedAt(id, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao registrar abertura', cause: e));
    }
  }

  Future<Result<void>> setFavorite(String id, bool value) async {
    try {
      await _dao.setFavorite(id, value, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao favoritar', cause: e));
    }
  }

  /// Troca a cor e/ou o módulo do azulejo (§9.4). Nulo em qualquer um volta ao
  /// automático daquele eixo.
  Future<Result<void>> setAppearance(
    String id, {
    TileColor? color,
    TileMotif? motif,
  }) async {
    try {
      await _dao.setAppearance(
        id,
        color: color?.name,
        motif: motif?.name,
        at: _clock().toUtc(),
      );
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao mudar a aparência', cause: e));
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

  /// Lixeira (RF-01.6): receitas com `deletedAt` preenchido.
  Stream<List<Recipe>> watchTrashed() =>
      _dao.watchTrashed().map((rows) => rows.map(_toDomain).toList());

  Future<Result<void>> restore(String id) async {
    try {
      await _dao.restore(id, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao restaurar', cause: e));
    }
  }

  Future<Result<void>> deleteForever(String id) async {
    try {
      await _dao.hardDelete(id);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao excluir de vez', cause: e));
    }
  }

  /// Esvazia da lixeira o que já passou dos 30 dias (RF-01.6). Roda no boot.
  Future<void> purgeExpired({Duration keep = const Duration(days: 30)}) async {
    try {
      await _dao.purgeExpired(_clock().toUtc().subtract(keep));
    } catch (_) {
      // Faxina best-effort: uma falha aqui não pode travar a abertura do app.
    }
  }

  Future<RecipeDetail> _detail(RecipeRow row) async {
    final ingredients = await _dao.ingredientsOf(row.id);
    final steps = await _dao.stepsOf(row.id);
    final tags = await _dao.tagsOf(row.id);
    return RecipeDetail(
      recipe: _toDomain(row),
      ingredients: ingredients.map(_ingredientToDomain).toList(),
      steps: steps.map(_stepToDomain).toList(),
      tags: tags.map(_tagToDomain).toList(),
    );
  }

  Tag _tagToDomain(TagRow r) => Tag(id: r.id, name: r.name);

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
        tileColor: tileColorFromName(r.tileColor),
        tileMotif: tileMotifFromName(r.tileMotif),
        isFavorite: r.isFavorite,
        deletedAt: r.deletedAt,
        lastOpenedAt: r.lastOpenedAt,
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
        tileColor: r.tileColor?.name,
        tileMotif: r.tileMotif?.name,
        imagePath: r.imagePath,
        sourceUrl: r.sourceUrl,
        notes: r.notes,
        isFavorite: r.isFavorite,
        deletedAt: null,
        lastOpenedAt: r.lastOpenedAt,
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
  final db = ref.watch(databaseProvider);
  return RecipeRepository(db.recipeDao, db.tagDao);
});
