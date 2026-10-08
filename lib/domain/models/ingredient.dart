import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';

/// Preço de um ingrediente: [cents] centavos por [quantity] da unidade
/// [unitCode] (código de `kSeedUnits`). "R$ 4,50 por 500 g" =
/// `IngredientPrice(450, 'g', 500)`; "R$ 6,00 o kg" = `IngredientPrice(600, 'kg')`.
class IngredientPrice {
  const IngredientPrice(this.cents, this.unitCode, [this.quantity = 1]);

  final int cents;
  final String unitCode;
  final double quantity;

  @override
  bool operator ==(Object other) =>
      other is IngredientPrice &&
      other.cents == cents &&
      other.unitCode == unitCode &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(cents, unitCode, quantity);
}

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String id,
    required String displayName,
    required String normalizedKey,
    String? categoryId,
    @Default(0) int usageCount,

    /// "Sempre tenho" (G11): fica fora das listas de compras geradas.
    @Default(false) bool inPantry,

    /// Preço que a pessoa informou. Nulo = sem preço.
    IngredientPrice? price,
  }) = _Ingredient;
}

/// Ingrediente com quantas linhas de receita usam ele — a tela de gerenciar
/// (C6) lista assim.
typedef IngredientWithCount = ({Ingredient ingredient, int count});
