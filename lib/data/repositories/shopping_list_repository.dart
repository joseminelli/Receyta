import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/database/app_database.dart';
import 'package:receyta/data/database/daos/ingredient_dao.dart';
import 'package:receyta/data/database/daos/recipe_dao.dart';
import 'package:receyta/data/database/daos/shopping_list_dao.dart';
import 'package:receyta/data/database/database_provider.dart';
import 'package:receyta/domain/engine/ingredient_category.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';
import 'package:receyta/domain/engine/shopping_aggregator.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

/// Fonte de verdade das listas de compras (§RF-05). Orquestra o agregador
/// (E1, `aggregateIngredients`, Dart puro) sobre os ingredientes das
/// receitas selecionadas e grava o resultado via [ShoppingListDao].
/// Timestamps sempre UTC.
class ShoppingListRepository {
  ShoppingListRepository(
    this._dao,
    this._recipeDao,
    this._ingredientDao, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final ShoppingListDao _dao;
  final RecipeDao _recipeDao;
  final IngredientDao _ingredientDao;
  final DateTime Function() _clock;

  /// Gera uma lista nova a partir das receitas selecionadas (RF-05.1):
  /// busca os ingredientes de todas, agrega (E1) e grava lista + itens +
  /// origem numa transação. Recusa quando não há nada pra agregar.
  Future<Result<ShoppingList>> generateFromRecipes(
    List<String> recipeIds, {
    String? name,
  }) async {
    if (recipeIds.isEmpty) {
      return const Err(ValidationFailure('Escolha ao menos uma receita.'));
    }
    try {
      final rows = await _recipeDao.ingredientsForRecipes(recipeIds);
      if (rows.isEmpty) {
        return const Err(
          ValidationFailure('Nenhuma receita selecionada tem ingrediente.'),
        );
      }

      final ingredientIds = {
        for (final r in rows)
          if (r.ingredientId != null) r.ingredientId!,
      }.toList();
      final catalogRows = await _ingredientDao.findByIds(ingredientIds);
      final namesById = {for (final c in catalogRows) c.id: c.displayName};

      final lines = [for (final r in rows) _lineToDomain(r, namesById)];
      final aggregated = aggregateIngredients(lines);

      final at = _clock().toUtc();
      final trimmed = name?.trim() ?? '';
      final listName = trimmed.isEmpty ? _defaultName(at) : trimmed;

      final row =
          await _dao.create(name: listName, items: aggregated, at: at);
      return Ok(_listToDomain(row));
    } catch (e) {
      debugPrint('ShoppingListRepository.generateFromRecipes: $e');
      return Err(DatabaseFailure('Falha ao gerar a lista', cause: e));
    }
  }

  /// Junta uma receita numa lista que já existe (RF-05.1): os ingredientes
  /// somam com os itens iguais e o resto entra no fim. Recusa receita sem
  /// ingrediente e receita que já contribuiu pra essa lista (somaria em
  /// dobro sem o usuário perceber).
  Future<Result<void>> addRecipeToList(String listId, String recipeId) async {
    try {
      final rows = await _recipeDao.ingredientsForRecipes([recipeId]);
      if (rows.isEmpty) {
        return const Err(
          ValidationFailure('Essa receita não tem ingredientes.'),
        );
      }
      final items = await _dao.itemsOf(listId);
      final sources = await _dao.sourcesOf([for (final i in items) i.id]);
      if (sources.any((s) => s.recipeId == recipeId)) {
        return const Err(ValidationFailure('Essa receita já está na lista.'));
      }

      final ingredientIds = {
        for (final r in rows)
          if (r.ingredientId != null) r.ingredientId!,
      }.toList();
      final catalogRows = await _ingredientDao.findByIds(ingredientIds);
      final namesById = {for (final c in catalogRows) c.id: c.displayName};
      final aggregated = aggregateIngredients(
        [for (final r in rows) _lineToDomain(r, namesById)],
      );

      await _dao.addAggregated(listId, aggregated);
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.addRecipeToList: $e');
      return Err(DatabaseFailure('Falha ao adicionar à lista', cause: e));
    }
  }

  Stream<List<ShoppingList>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_listToDomain).toList());

  Stream<ShoppingList?> watchById(String id) {
    return _dao.watchById(id).map((r) => r == null ? null : _listToDomain(r));
  }

  /// Todas as listas com progresso, ao vivo — a tela "suas listas" (RF-05.9).
  Stream<List<ShoppingListSummary>> watchSummaries() {
    return _dao.watchAllWithCounts().map(
          (rows) => [
            for (final r in rows)
              (
                list: _listToDomain(r.list),
                total: r.total,
                checked: r.checked,
              ),
          ],
        );
  }

  /// Lista sem itens — pra ir montando à mão com itens avulsos. Sem nome,
  /// cai no padrão com a data.
  Future<Result<ShoppingList>> createEmpty({String? name}) async {
    try {
      final at = _clock().toUtc();
      final trimmed = name?.trim() ?? '';
      final row = await _dao.createEmpty(
        name: trimmed.isEmpty ? _defaultName(at) : trimmed,
        at: at,
      );
      return Ok(_listToDomain(row));
    } catch (e) {
      debugPrint('ShoppingListRepository.createEmpty: $e');
      return Err(DatabaseFailure('Falha ao criar a lista', cause: e));
    }
  }

  /// Duplica a lista ("Nome (cópia)") com os itens desmarcados.
  Future<Result<ShoppingList>> duplicate(String id) async {
    try {
      final original = await _dao.watchById(id).first;
      if (original == null) {
        return const Err(NotFoundFailure('Lista não encontrada.'));
      }
      final row = await _dao.duplicate(
        id,
        name: '${original.name} (cópia)',
        at: _clock().toUtc(),
      );
      return Ok(_listToDomain(row));
    } catch (e) {
      debugPrint('ShoppingListRepository.duplicate: $e');
      return Err(DatabaseFailure('Falha ao duplicar a lista', cause: e));
    }
  }

  Future<Result<void>> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Dê um nome à lista.'));
    }
    try {
      await _dao.rename(id, trimmed, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.rename: $e');
      return Err(DatabaseFailure('Falha ao renomear a lista', cause: e));
    }
  }

  Future<Result<void>> deleteList(String id) async {
    try {
      await _dao.deleteList(id);
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.deleteList: $e');
      return Err(DatabaseFailure('Falha ao excluir a lista', cause: e));
    }
  }

  Future<Result<void>> setChecked(String itemId, bool checked) async {
    try {
      await _dao.setChecked(itemId, checked);
      return const Ok(null);
    } catch (e) {
      return Err(DatabaseFailure('Falha ao marcar item', cause: e));
    }
  }

  /// Tira um item da lista.
  Future<Result<void>> deleteItem(String itemId) async {
    try {
      await _dao.deleteItem(itemId);
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.deleteItem: $e');
      return Err(DatabaseFailure('Falha ao tirar o item', cause: e));
    }
  }

  /// Adiciona um item avulso digitado na lista (RF-05.6). Passa pelo mesmo
  /// parser (C1) e catálogo (C2) das receitas — "2 caixas de leite" vira
  /// quantidade + unidade + ingrediente "Leite", e ganha o corredor certo.
  Future<Result<void>> addManualItem(String listId, String text) async {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const Err(ValidationFailure('Digite o item.'));
    }
    try {
      final parsed = parseIngredientLine(raw);
      final name = parsed.name.trim().isEmpty ? raw : parsed.name.trim();
      final ingredient = await _ingredientDao.getOrCreate(name);
      await _dao.addItem(
        listId: listId,
        ingredientId: ingredient.id,
        quantity: parsed.quantity,
        unitId: parsed.unitCode,
      );
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.addManualItem: $e');
      return Err(DatabaseFailure('Falha ao adicionar o item', cause: e));
    }
  }

  /// Itens de uma lista, já com o nome de exibição e a origem resolvidos
  /// (catálogo + receitas) — quem chama não faz join nenhum sozinho.
  Future<List<ShoppingListItem>> itemsOf(String listId) async {
    final items = await _dao.itemsOf(listId);
    return _resolveItems(items);
  }

  /// Mesma resolução de [itemsOf], mas ao vivo — reemite quando um item é
  /// marcado/desmarcado ou a lista ganha itens novos.
  Stream<List<ShoppingListItem>> watchItems(String listId) {
    return _dao.watchItems(listId).asyncMap(_resolveItems);
  }

  Future<List<ShoppingListItem>> _resolveItems(
    List<ShoppingListItemRow> items,
  ) async {
    if (items.isEmpty) return const [];

    final ingredientIds = {
      for (final i in items)
        if (i.ingredientId != null) i.ingredientId!,
    }.toList();
    final catalogRows = await _ingredientDao.findByIds(ingredientIds);
    final namesById = {for (final c in catalogRows) c.id: c.displayName};
    final categoryById = {
      for (final c in catalogRows) c.id: categorySlugFromId(c.categoryId),
    };

    final sources = await _dao.sourcesOf([for (final i in items) i.id]);
    final recipeIds = {for (final s in sources) s.recipeId}.toList();
    final recipeRows = await _recipeDao.findByIds(recipeIds);
    final recipeNamesById = {for (final r in recipeRows) r.id: r.name};

    final sourcesByItem = <String, List<ShoppingItemSource>>{};
    for (final s in sources) {
      sourcesByItem.putIfAbsent(s.itemId, () => []).add(
            ShoppingItemSource(
              recipeId: s.recipeId,
              recipeName: recipeNamesById[s.recipeId] ?? '?',
              quantity: s.quantity,
              unitId: s.unitId,
            ),
          );
    }

    return [
      for (final i in items) _toItem(i, namesById, categoryById, sourcesByItem),
    ];
  }

  ShoppingListItem _toItem(
    ShoppingListItemRow i,
    Map<String, String> namesById,
    Map<String, String?> categoryById,
    Map<String, List<ShoppingItemSource>> sourcesByItem,
  ) {
    final displayName =
        (i.ingredientId != null ? namesById[i.ingredientId] : null) ??
            i.manualName ??
            '?';
    return ShoppingListItem(
      id: i.id,
      listId: i.listId,
      ingredientId: i.ingredientId,
      displayName: displayName,
      manualName: i.manualName,
      categorySlug:
          (i.ingredientId != null ? categoryById[i.ingredientId] : null) ??
              categorySlugFor(displayName),
      quantity: i.quantity,
      unitId: i.unitId,
      checked: i.checked,
      note: i.note,
      position: i.position,
      sources: sourcesByItem[i.id] ?? const [],
    );
  }

  RecipeIngredient _lineToDomain(
    RecipeIngredientRow r,
    Map<String, String> namesById,
  ) =>
      RecipeIngredient(
        id: r.id,
        recipeId: r.recipeId,
        rawText: r.rawText,
        position: r.position,
        groupLabel: r.groupLabel,
        ingredientId: r.ingredientId,
        ingredientName:
            r.ingredientId == null ? null : namesById[r.ingredientId],
        quantity: r.quantity,
        unitId: r.unitId,
        qualifier: r.qualifier,
      );

  ShoppingList _listToDomain(ShoppingListRow r) => ShoppingList(
        id: r.id,
        name: r.name,
        status: r.status,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  String _defaultName(DateTime at) =>
      'Lista de ${at.day.toString().padLeft(2, '0')}/'
      '${at.month.toString().padLeft(2, '0')}';
}

final shoppingListRepositoryProvider =
    Provider<ShoppingListRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ShoppingListRepository(
    db.shoppingListDao,
    db.recipeDao,
    db.ingredientDao,
  );
});
