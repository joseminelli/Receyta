import 'package:freezed_annotation/freezed_annotation.dart';

part 'shopping_list_item.freezed.dart';

/// De qual receita um item veio, com a quantidade ORIGINAL dela (não
/// convertida) — RF-05.8, "mostrar de quais receitas veio cada item".
@freezed
class ShoppingItemSource with _$ShoppingItemSource {
  const factory ShoppingItemSource({
    required String recipeId,
    required String recipeName,
    double? quantity,
    String? unitId,
  }) = _ShoppingItemSource;
}

/// Uma linha da lista de compras. `ingredientId` nulo + `manualName`
/// preenchido = item avulso (RF-05.6) ou ingrediente sem catálogo (a
/// `aggregateIngredients` chave sintética a partir do `rawText`).
@freezed
class ShoppingListItem with _$ShoppingListItem {
  const factory ShoppingListItem({
    required String id,
    required String listId,
    String? ingredientId,
    required String displayName,
    String? manualName,

    /// Nulo quando nenhuma origem tinha quantidade numérica reconhecida —
    /// a tela mostra a unidade/nome sem número, não inventa um.
    double? quantity,
    String? unitId,
    @Default(false) bool checked,
    String? note,
    @Default(0) int position,

    /// Corredor do mercado (slug de `kSeedCategories`, RF-05.7) — do
    /// catálogo quando o ingrediente tem categoria, senão inferido do nome.
    @Default('outros') String categorySlug,

    /// Quem adicionou e quem marcou o item (id da conta); só em listas da casa.
    String? addedBy,
    String? checkedBy,
    @Default(<ShoppingItemSource>[]) List<ShoppingItemSource> sources,
  }) = _ShoppingListItem;
}
