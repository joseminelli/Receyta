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

    /// `displayName` do catálogo (`Ingredient`) na hora em que a receita foi
    /// carregada — é o nome de verdade pra EXIBIR (já normalizado, Title
    /// Case). `null` quando `ingredientId` também é nulo (linha nunca
    /// resolvida). Quem preenche é `RecipeRepository._detail`; nunca é
    /// gravado no banco (`rawText`/`ingredientId` continuam sendo a fonte
    /// de verdade salva).
    String? ingredientName,
    double? quantity,
    String? unitId,
    String? qualifier,
  }) = _RecipeIngredient;
}
