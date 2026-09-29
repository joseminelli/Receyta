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
    item.sources.map((s) => s.recipeName).toSet().join(', ');

/// Itens agrupados por corredor, seções na ordem do mercado e itens de
/// cada seção na ordem original (`position`).
List<({String slug, String label, List<ShoppingListItem> items})>
    groupShoppingItems(List<ShoppingListItem> items) {
  final bySlug = <String, List<ShoppingListItem>>{};
  for (final i in items) {
    bySlug.putIfAbsent(i.categorySlug, () => []).add(i);
  }
  final slugs = bySlug.keys.toList()
    ..sort((a, b) => categoryOrder(a).compareTo(categoryOrder(b)));
  return [
    for (final s in slugs)
      (
        slug: s,
        label: categoryLabel(s),
        items: [...bySlug[s]!]
          ..sort((a, b) => a.position.compareTo(b.position)),
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
