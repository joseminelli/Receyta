import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

/// Todas as listas de compras com o progresso de cada uma (RF-05.9).
final shoppingListsProvider =
    StreamProvider<List<ShoppingListSummary>>((ref) {
  return ref.watch(shoppingListRepositoryProvider).watchSummaries();
});

/// Uma lista pelo id, ao vivo — `null` quando ela foi apagada.
final shoppingListProvider =
    StreamProvider.family<ShoppingList?, String>((ref, listId) {
  return ref.watch(shoppingListRepositoryProvider).watchById(listId);
});

/// Itens da lista, ao vivo — reemite quando um item é marcado/desmarcado.
final shoppingListItemsProvider =
    StreamProvider.family<List<ShoppingListItem>, String>((ref, listId) {
  return ref.watch(shoppingListRepositoryProvider).watchItems(listId);
});
