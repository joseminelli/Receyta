import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';

/// Unidade em que o preço foi informado.
enum PriceBasis {
  kg('kg', 'por kg'),
  liter('l', 'por litro'),
  unit('un', 'por unidade');

  const PriceBasis(this.code, this.label);

  /// O que vai pro banco (`ingredients.price_basis`).
  final String code;
  final String label;

  static PriceBasis? fromCode(String? code) {
    for (final b in values) {
      if (b.code == code) return b;
    }
    return null;
  }
}

/// Preço de um ingrediente: [cents] centavos por [basis].
class IngredientPrice {
  const IngredientPrice(this.cents, this.basis);

  final int cents;
  final PriceBasis basis;

  @override
  bool operator ==(Object other) =>
      other is IngredientPrice && other.cents == cents && other.basis == basis;

  @override
  int get hashCode => Object.hash(cents, basis);
}

/// Um ingrediente do catálogo (§8.2). `normalizedKey` é a chave de
/// identidade usada pelo `getOrCreate`.
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

    /// Preço que a pessoa informou, por [priceBasis]. Nulo = sem preço.
    IngredientPrice? price,
  }) = _Ingredient;
}

/// Ingrediente com quantas linhas de receita usam ele — a tela de gerenciar
/// (C6) lista assim.
typedef IngredientWithCount = ({Ingredient ingredient, int count});
