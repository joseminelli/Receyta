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

  Stream<ShoppingListRow?> watchById(String id) {
    return (select(shoppingLists)..where((l) => l.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Todas as listas, da mais nova pra mais antiga, com quantos itens têm e
  /// quantos já estão marcados (stream vivo — reemite ao marcar).
  Stream<List<({ShoppingListRow list, int total, int checked})>>
      watchAllWithCounts() {
    return customSelect(
      'SELECT l.*, '
      '  (SELECT COUNT(*) FROM shopping_list_items i '
      '   WHERE i.list_id = l.id) AS total, '
      '  (SELECT COUNT(*) FROM shopping_list_items i '
      '   WHERE i.list_id = l.id AND i.checked = 1) AS checked_count '
      'FROM shopping_lists l '
      'ORDER BY l.created_at DESC',
      readsFrom: {shoppingLists, shoppingListItems},
    ).watch().map(
          (rows) => [
            for (final row in rows)
              (
                list: shoppingLists.map(row.data),
                total: row.read<int>('total'),
                checked: row.read<int>('checked_count'),
              ),
          ],
        );
  }

  Future<ShoppingListRow> createEmpty({
    required String name,
    required DateTime at,
  }) async {
    final list = ShoppingListRow(
      id: _uuid.v4(),
      name: name,
      status: 'active',
      createdAt: at,
      updatedAt: at,
    );
    await into(shoppingLists).insert(list);
    return list;
  }

  /// Copia a lista com os itens (todos desmarcados) e as origens, numa
  /// transação — a "mesma compra da semana passada" em um gesto.
  Future<ShoppingListRow> duplicate(
    String id, {
    required String name,
    required DateTime at,
  }) {
    return transaction(() async {
      final copy = await createEmpty(name: name, at: at);
      final items = await itemsOf(id);
      final sources = await sourcesOf([for (final i in items) i.id]);
      for (final item in items) {
        final newId = _uuid.v4();
        await into(shoppingListItems).insert(
          item.copyWith(id: newId, listId: copy.id, checked: false),
        );
        for (final s in sources.where((s) => s.itemId == item.id)) {
          await into(shoppingItemSources).insert(s.copyWith(itemId: newId));
        }
      }
      return copy;
    });
  }

  /// Junta ingredientes já agregados (E1) numa lista que já existe: o que
  /// casa com um item da lista (mesmo ingrediente, unidades somáveis) soma
  /// nele e desmarca (precisa comprar mais); o resto entra no fim como item
  /// novo. Sempre grava a origem.
  Future<void> addAggregated(
    String listId,
    List<AggregatedIngredient> aggregated,
  ) {
    return transaction(() async {
      final existing = await itemsOf(listId);
      var position = existing.isEmpty
          ? 0
          : existing.map((i) => i.position).reduce((a, b) => a > b ? a : b) + 1;
      final live = [...existing];

      for (final agg in aggregated) {
        final isCatalog = !agg.ingredientKey.startsWith('raw:');
        ShoppingListItemRow? target;
        ({double? quantity, String? unitCode})? combined;
        for (final item in live) {
          final sameIngredient = isCatalog
              ? item.ingredientId == agg.ingredientKey
              : item.ingredientId == null &&
                  item.manualName?.toLowerCase() ==
                      agg.displayName.toLowerCase();
          if (!sameIngredient) continue;
          combined = combineQuantities(
            quantityA: item.quantity,
            unitA: item.unitId,
            quantityB: agg.quantity,
            unitB: agg.unitCode,
          );
          if (combined != null) {
            target = item;
            break;
          }
        }

        final String itemId;
        if (target != null && combined != null) {
          itemId = target.id;
          await (update(shoppingListItems)..where((i) => i.id.equals(itemId)))
              .write(
            ShoppingListItemsCompanion(
              quantity: Value(combined.quantity),
              unitId: Value(combined.unitCode),
              checked: const Value(false),
            ),
          );
          final index = live.indexOf(target);
          live[index] = target.copyWith(
            quantity: Value(combined.quantity),
            unitId: Value(combined.unitCode),
            checked: false,
          );
        } else {
          itemId = _uuid.v4();
          final row = ShoppingListItemRow(
            id: itemId,
            listId: listId,
            ingredientId: isCatalog ? agg.ingredientKey : null,
            manualName: isCatalog ? null : agg.displayName,
            quantity: agg.quantity,
            unitId: agg.unitCode,
            checked: false,
            position: position++,
          );
          await into(shoppingListItems).insert(row);
          live.add(row);
        }
        for (final source in agg.sources) {
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
    });
  }

  Future<int> rename(String id, String name, DateTime at) {
    return (update(shoppingLists)..where((l) => l.id.equals(id))).write(
      ShoppingListsCompanion(name: Value(name), updatedAt: Value(at)),
    );
  }

  /// Apaga a lista; itens e origens caem em cascata.
  Future<int> deleteList(String id) {
    return (delete(shoppingLists)..where((l) => l.id.equals(id))).go();
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

  /// Tira um item da lista (as origens caem em cascata).
  Future<int> deleteItem(String itemId) {
    return (delete(shoppingListItems)..where((i) => i.id.equals(itemId))).go();
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
