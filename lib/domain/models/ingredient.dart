import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';

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
  }) = _Ingredient;
}

/// Ingrediente com quantas linhas de receita usam ele — a tela de gerenciar
/// (C6) lista assim.
typedef IngredientWithCount = ({Ingredient ingredient, int count});
