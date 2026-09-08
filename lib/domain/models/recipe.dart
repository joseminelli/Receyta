import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';

/// Uma receita, do ponto de vista do domínio (§5). Só o núcleo em B1 —
/// ingredientes (B5), passos (B5) e tags (B10) entram como listas próprias
/// depois. `id`/`createdAt`/`updatedAt` ficam aqui porque a UI navega por id e
/// ordena por data.
@freezed
class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? folderId,
    String? about,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    String? imagePath,
    String? sourceUrl,
    String? notes,
    @Default(false) bool isFavorite,
  }) = _Recipe;
}
