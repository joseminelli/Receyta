import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:receyta/core/tile_style.dart';

part 'folder.freezed.dart';

/// Uma pasta (RF-02). `parentId` nulo = pasta de raiz; senão, subpasta. As
/// receitas apontam pra pasta por `folderId` — sem pasta = raiz também.
@freezed
class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    String? parentId,

    /// Aparência do azulejo (§9.4). Nulo = padrão (violet/meia-lua).
    TileColor? tileColor,
    TileMotif? tileMotif,
    @Default(0) int position,
  }) = _Folder;
}

/// Pasta com a contagem de receitas diretas e de subpastas — o tile da home e a
/// tela da pasta mostram isso.
typedef FolderWithCounts = ({Folder folder, int recipeCount, int subfolders});
