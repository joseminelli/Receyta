import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/serving_scale.dart';
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
  ///
  /// [counts] diz quantas vezes cada receita entra (receita feita duas vezes
  /// na semana pede o dobro dos ingredientes); ausente = uma vez cada.
  /// [factors] (id → multiplicador) escala as quantidades da receita pro
  /// número de porções que se vai fazer, sempre arredondando pra cima.
  Future<Result<ShoppingList>> generateFromRecipes(
    List<String> recipeIds, {
    String? name,
    Map<String, int>? counts,
    Map<String, double>? factors,
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
      final needed = _outsidePantry(rows, catalogRows);
      if (needed.isEmpty) {
        return const Err(
          ValidationFailure(
            'Tudo o que as receitas pedem já está na sua despensa.',
          ),
        );
      }

      final aggregated = aggregateIngredients(
          _repeatedLines(needed, namesById, counts, factors));

      final at = _clock().toUtc();
      final trimmed = name?.trim() ?? '';
      final listName = trimmed.isEmpty ? _defaultName(at) : trimmed;

      final row = await _dao.create(name: listName, items: aggregated, at: at);
      return Ok(_listToDomain(row));
    } catch (e) {
      debugPrint('ShoppingListRepository.generateFromRecipes: $e');
      return Err(DatabaseFailure('Falha ao gerar a lista', cause: e));
    }
  }

  /// Junta uma receita numa lista que já existe (RF-05.1). Ver
  /// [addRecipesToList].
  Future<Result<void>> addRecipeToList(String listId, String recipeId) =>
      addRecipesToList(listId, {recipeId: 1});

  /// Junta receitas ([counts]: id → quantas vezes) numa lista que já existe:
  /// os ingredientes somam com os itens iguais e o resto entra no fim.
  /// Receita que já contribuiu pra essa lista é pulada (somaria em dobro sem
  /// o usuário perceber); sem sobrar nenhuma com ingrediente, recusa.
  Future<Result<void>> addRecipesToList(
    String listId,
    Map<String, int> counts, {
    Map<String, double>? factors,
  }) async {
    final plural = counts.length > 1;
    try {
      final items = await _dao.itemsOf(listId);
      final sources = await _dao.sourcesOf([for (final i in items) i.id]);
      final already = {for (final s in sources) s.recipeId};
      final fresh = {
        for (final e in counts.entries)
          if (!already.contains(e.key)) e.key: e.value,
      };
      if (fresh.isEmpty) {
        return Err(ValidationFailure(
          plural
              ? 'Essas receitas já estão na lista.'
              : 'Essa receita já está na lista.',
        ));
      }

      final rows = await _recipeDao.ingredientsForRecipes(fresh.keys.toList());
      if (rows.isEmpty) {
        return Err(ValidationFailure(
          plural
              ? 'Essas receitas não têm ingredientes.'
              : 'Essa receita não tem ingredientes.',
        ));
      }

      final ingredientIds = {
        for (final r in rows)
          if (r.ingredientId != null) r.ingredientId!,
      }.toList();
      final catalogRows = await _ingredientDao.findByIds(ingredientIds);
      final namesById = {for (final c in catalogRows) c.id: c.displayName};
      final needed = _outsidePantry(rows, catalogRows);
      if (needed.isEmpty) {
        return Err(ValidationFailure(
          plural
              ? 'Tudo o que essas receitas pedem já está na sua despensa.'
              : 'Tudo o que essa receita pede já está na sua despensa.',
        ));
      }
      final aggregated = aggregateIngredients(
          _repeatedLines(needed, namesById, fresh, factors));

      await _dao.addAggregated(listId, aggregated);
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.addRecipesToList: $e');
      return Err(DatabaseFailure('Falha ao adicionar à lista', cause: e));
    }
  }

  /// Tira as linhas de ingredientes marcados "sempre tenho" (G11): ficam fora
  /// de toda lista gerada. Linha sem ingrediente do catálogo sempre fica.
  List<RecipeIngredientRow> _outsidePantry(
    List<RecipeIngredientRow> rows,
    List<IngredientRow> catalog,
  ) {
    final pantry = {
      for (final c in catalog)
        if (c.inPantry) c.id,
    };
    return [
      for (final r in rows)
        if (!pantry.contains(r.ingredientId)) r,
    ];
  }

  /// Linhas de ingrediente, cada uma repetida [counts] vezes pra receita
  /// dela (o agregador soma as repetições numa origem só).
  List<RecipeIngredient> _repeatedLines(
    List<RecipeIngredientRow> rows,
    Map<String, String> namesById,
    Map<String, int>? counts,
    Map<String, double>? factors,
  ) {
    return [
      for (final r in rows)
        for (var n = 0; n < (counts?[r.recipeId] ?? 1); n++)
          _scaled(_lineToDomain(r, namesById), factors?[r.recipeId]),
    ];
  }

  /// Linha com a quantidade escalada e arredondada pra cima (1,5 ovo → 2).
  RecipeIngredient _scaled(RecipeIngredient line, double? factor) {
    final q = line.quantity;
    if (factor == null || factor == 1 || q == null) return line;
    return line.copyWith(
      quantity: roundUpForShopping(q * factor, unitId: line.unitId),
    );
  }

  Stream<List<ShoppingList>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_listToDomain).toList());

  /// Listas em que a receita está (tem algum item vindo dela), ao vivo.
  Stream<List<ShoppingList>> watchListsWithRecipe(String recipeId) => _dao
      .watchListsContainingRecipe(recipeId)
      .map((rows) => rows.map(_listToDomain).toList());

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

  /// Compartilha a lista com a casa ([spaceId]) ou volta a deixá-la só da
  /// pessoa (nulo).
  Future<Result<void>> setSpace(String id, String? spaceId) async {
    try {
      await _dao.setSpace(id, spaceId, _clock().toUtc());
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.setSpace: $e');
      return Err(DatabaseFailure('Falha ao compartilhar a lista', cause: e));
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

  /// Desmarca todos os itens da lista (pra reaproveitar a lista na próxima
  /// compra). Devolve os ids que estavam marcados, pra [recheck] desfazer.
  Future<Result<List<String>>> uncheckAll(String listId) async {
    try {
      return Ok(await _dao.uncheckAll(listId));
    } catch (e) {
      debugPrint('ShoppingListRepository.uncheckAll: $e');
      return Err(DatabaseFailure('Falha ao desmarcar os itens', cause: e));
    }
  }

  /// Remarca os itens de [itemIds] — o "desfazer" do [uncheckAll].
  Future<Result<void>> recheck(List<String> itemIds) async {
    try {
      await _dao.setCheckedMany(itemIds, true);
      return const Ok(null);
    } catch (e) {
      debugPrint('ShoppingListRepository.recheck: $e');
      return Err(DatabaseFailure('Falha ao desfazer', cause: e));
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
        spaceId: r.spaceId,
      );

  String _defaultName(DateTime at) =>
      'Lista de ${at.day.toString().padLeft(2, '0')}/'
      '${at.month.toString().padLeft(2, '0')}';
}

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ShoppingListRepository(
    db.shoppingListDao,
    db.recipeDao,
    db.ingredientDao,
  );
});
