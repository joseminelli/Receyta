import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/recipe_step.dart';

part 'recipe_detail.freezed.dart';

/// A receita com suas listas (§5: "listas próprias"). A home usa só [Recipe];
/// a tela de detalhe e o formulário usam este agregado.
@freezed
class RecipeDetail with _$RecipeDetail {
  const factory RecipeDetail({
    required Recipe recipe,
    @Default(<RecipeIngredient>[]) List<RecipeIngredient> ingredients,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
  }) = _RecipeDetail;
}
