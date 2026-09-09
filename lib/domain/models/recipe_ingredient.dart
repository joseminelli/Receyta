import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_ingredient.freezed.dart';

/// Uma linha da lista de ingredientes (§RF-01.3). No bloco B só `rawText`
/// importa — quantidade, unidade e vínculo com o catálogo são preenchidos pela
/// normalização no bloco C. `rawText` é sempre preservado (§RF-03.8).
@freezed
class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    required String id,
    required String recipeId,
    required String rawText,
    required int position,
    String? groupLabel,
    String? ingredientId,
    double? quantity,
    String? unitId,
    String? qualifier,
  }) = _RecipeIngredient;
}
