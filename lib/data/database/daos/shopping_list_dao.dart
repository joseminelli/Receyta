import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:receyta/domain/engine/shopping_aggregator.dart';
import '../app_database.dart';
import '../tables.dart';

part 'shopping_list_dao.g.dart';

/// Acesso bruto às listas de compras (§RF-05): a linha em `shopping_lists`,
/// seus itens em `shopping_list_items` e a origem de cada item (de qual
/// receita veio, RF-05.8) em `shopping_item_sources`.
@DriftAccessor(tables: [ShoppingLists, ShoppingListItems, ShoppingItemSources])
class ShoppingListDao extends DatabaseAccessor<AppDatabase>
    with _$ShoppingListDaoMixin {
  ShoppingListDao(super.db, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final Uuid _uuid;

  /// Cria a lista + os itens já agregados (E1, `aggregateIngredients`) + a
  /// origem de cada um, numa transação só — tudo ou nada.
  Future<ShoppingListRow> create({
    required String name,
    required List<AggregatedIngredient> items,
    required DateTime at,
  }) {
    return transaction(() async {
      final list = ShoppingListRow(
        id: _uuid.v4(),
        name: name,
        status: 'active',
        createdAt: at,
        updatedAt: at,
      );
      await into(shoppingLists).insert(list);

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final itemId = _uuid.v4();
        // Item nunca resolvido contra o catálogo (chave sintética a partir
        // do `rawText`, ver `aggregateIngredients`) vira item manual — não
        // tem `ingredientId` de verdade pra gravar como FK.
        final isCatalog = !item.ingredientKey.startsWith('raw:');
        await into(shoppingListItems).insert(
          ShoppingListItemRow(
            id: itemId,
            listId: list.id,
            ingredientId: isCatalog ? item.ingredientKey : null,
            manualName: isCatalog ? null : item.displayName,
            quantity: item.quantity,
            unitId: item.unitCode,
            checked: false,
            position: i,
          ),
        );
        for (final source in item.sources) {
          await into(shoppingItemSources).insert(
            ShoppingItemSourceRow(
              itemId: itemId,
              recipeId: source.recipeId,
              quantity: source.quantity,
              unitId: source.unitId,
            ),
          );
        }
      }
      return list;
    });
  }

  Stream<List<ShoppingListRow>> watchAll() {
    return (select(shoppingLists)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .watch();
  }

  /// A lista mais recente — E3 não tem seletor de "qual lista" ainda
  /// (múltiplas listas simultâneas é RF-05.9, Could); mostra sempre a
  /// última gerada.
  Stream<ShoppingListRow?> watchMostRecent() {
    return (select(shoppingLists)
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<List<ShoppingListItemRow>> itemsOf(String listId) {
    return (select(shoppingListItems)
          ..where((i) => i.listId.equals(listId))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
  }

  Stream<List<ShoppingListItemRow>> watchItems(String listId) {
    return (select(shoppingListItems)
          ..where((i) => i.listId.equals(listId))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .watch();
  }

  /// Item avulso (RF-05.6) no fim da lista.
  Future<void> addItem({
    required String listId,
    String? ingredientId,
    String? manualName,
    double? quantity,
    String? unitId,
  }) {
    return transaction(() async {
      final maxPosition = shoppingListItems.position.max();
      final last = await (selectOnly(shoppingListItems)
            ..addColumns([maxPosition])
            ..where(shoppingListItems.listId.equals(listId)))
          .map((r) => r.read(maxPosition))
          .getSingle();
      await into(shoppingListItems).insert(
        ShoppingListItemRow(
          id: _uuid.v4(),
          listId: listId,
          ingredientId: ingredientId,
          manualName: manualName,
          quantity: quantity,
          unitId: unitId,
          checked: false,
          position: (last ?? -1) + 1,
        ),
      );
    });
  }

  /// Apaga os itens já marcados da lista (origens caem em cascata).
  Future<int> deleteChecked(String listId) {
    return (delete(shoppingListItems)
          ..where((i) => i.listId.equals(listId) & i.checked.equals(true)))
        .go();
  }

  Future<int> setChecked(String itemId, bool checked) {
    return (update(shoppingListItems)..where((i) => i.id.equals(itemId)))
        .write(ShoppingListItemsCompanion(checked: Value(checked)));
  }

  Future<List<ShoppingItemSourceRow>> sourcesOf(List<String> itemIds) {
    if (itemIds.isEmpty) return Future.value(const []);
    return (select(shoppingItemSources)
          ..where((s) => s.itemId.isIn(itemIds)))
        .get();
  }
}
