import 'package:receyta/core/unit_label.dart';
import 'package:receyta/domain/engine/ingredient_category.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';

/// "1,3 kg de Farinha" / "3 dentes de Alho" / "Sal" — a linha de um item,
/// igual na tela e no texto exportado.
String shoppingItemLabel(ShoppingListItem item) {
  final qty = item.quantity;
  if (qty == null) return item.displayName;
  final unit = unitLabel(item.unitId, qty);
  final qtyText = qty == qty.roundToDouble()
      ? qty.toInt().toString()
      : qty.toStringAsFixed(2).replaceAll('.', ',');
  return unit == null
      ? '$qtyText ${item.displayName}'
      : '$qtyText $unit de ${item.displayName}';
}

/// "Bolo, Pão de Queijo" — de quais receitas o item veio (RF-05.8). Vazio
/// pra item avulso.
String shoppingItemOrigin(ShoppingListItem item) =>
    shoppingItemOrigins(item).join(', ');

/// Nomes distintos das receitas de origem, na ordem em que aparecem.
List<String> shoppingItemOrigins(ShoppingListItem item) =>
    item.sources.map((s) => s.recipeName).toSet().toList();

/// Quantidade sozinha ("1,3", "2"); `null` sem quantidade reconhecida.
String? shoppingItemQuantity(ShoppingListItem item) {
  final qty = item.quantity;
  if (qty == null) return null;
  return qty == qty.roundToDouble()
      ? qty.toInt().toString()
      : qty.toStringAsFixed(2).replaceAll('.', ',');
}

/// Unidade por extenso ("kg", "dentes") ou `null`.
String? shoppingItemUnit(ShoppingListItem item) {
  final qty = item.quantity;
  return qty == null ? null : unitLabel(item.unitId, qty);
}

/// Itens agrupados por corredor, seções na ordem do mercado e itens de
/// cada seção na ordem original (`position`). Com [sinkChecked], os itens
/// marcados vão pro fim da seção e as seções inteiramente marcadas pro fim
/// da lista (a ordem do mercado só desempata).
List<({String slug, String label, List<ShoppingListItem> items})>
    groupShoppingItems(
  List<ShoppingListItem> items, {
  bool sinkChecked = false,
}) {
  final bySlug = <String, List<ShoppingListItem>>{};
  for (final i in items) {
    bySlug.putIfAbsent(i.categorySlug, () => []).add(i);
  }
  bool complete(String s) => bySlug[s]!.every((i) => i.checked);
  final slugs = bySlug.keys.toList()
    ..sort((a, b) {
      if (sinkChecked && complete(a) != complete(b)) {
        return complete(a) ? 1 : -1;
      }
      return categoryOrder(a).compareTo(categoryOrder(b));
    });
  return [
    for (final s in slugs)
      (
        slug: s,
        label: categoryLabel(s),
        items: [...bySlug[s]!]..sort((a, b) {
            if (sinkChecked && a.checked != b.checked) {
              return a.checked ? 1 : -1;
            }
            return a.position.compareTo(b.position);
          }),
      ),
  ];
}

/// Texto simples pra compartilhar (RF-05.10): título, seção por corredor,
/// "[ ]"/"[x]" por item e a origem entre parênteses.
String buildShoppingListText(String listName, List<ShoppingListItem> items) {
  final buffer = StringBuffer(listName);
  for (final group in groupShoppingItems(items)) {
    buffer
      ..writeln()
      ..writeln()
      ..write(group.label.toUpperCase());
    for (final item in group.items) {
      final origin = shoppingItemOrigin(item);
      buffer
        ..writeln()
        ..write(item.checked ? '[x] ' : '[ ] ')
        ..write(shoppingItemLabel(item));
      if (origin.isNotEmpty) buffer.write(' ($origin)');
    }
  }
  return buffer.toString();
}
