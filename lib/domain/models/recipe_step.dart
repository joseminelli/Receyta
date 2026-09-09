import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_step.freezed.dart';

/// Um passo de preparo (§RF-01.4). Lista ordenada; `groupLabel` agrupa em
/// seções ("Para a massa") no §RF-01.5.
@freezed
class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    required String id,
    required String recipeId,
    required String text,
    required int position,
    String? groupLabel,
  }) = _RecipeStep;
}
