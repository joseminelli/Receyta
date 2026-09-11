import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:receyta/core/tile_style.dart';

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

    /// Aparência do azulejo escolhida pelo usuário (§9.4). Nulo em qualquer um
    /// = deriva do id / pareamento padrão.
    TileColor? tileColor,
    TileMotif? tileMotif,
    @Default(false) bool isFavorite,

    /// Preenchido só nas linhas da lixeira (RF-01.6). `null` = receita ativa.
    DateTime? deletedAt,

    /// Última abertura ou criação — ordena a prateleira "Recentes" da home.
    DateTime? lastOpenedAt,
  }) = _Recipe;
}
