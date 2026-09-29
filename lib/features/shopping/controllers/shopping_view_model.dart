import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

/// A lista de compras atual (a mais recente) — E3 não tem seletor de lista
/// ainda, RF-05.9 (múltiplas simultâneas) fica pra depois.
final currentShoppingListProvider = StreamProvider<ShoppingList?>((ref) {
  return ref.watch(shoppingListRepositoryProvider).watchMostRecent();
});

/// Itens da lista, ao vivo — reemite quando um item é marcado/desmarcado.
final shoppingListItemsProvider =
    StreamProvider.family<List<ShoppingListItem>, String>((ref, listId) {
  return ref.watch(shoppingListRepositoryProvider).watchItems(listId);
});
