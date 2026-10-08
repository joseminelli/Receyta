import 'package:flutter/material.dart';

import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/widgets/folder_shape.dart';

/// Pasta na grade da tela "todas as pastas": o mesmo cartão em forma de pasta
/// da faixa da home (`FolderShapeCard`), com cor e módulo de
/// `resolveTileAppearance` (§9.4).
class FolderGridTile extends StatelessWidget {
  const FolderGridTile({super.key, required this.item, required this.onTap});

  final FolderWithCounts item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FolderShapeCard(
      folder: item.folder,
      recipes: item.recipeCount,
      subfolders: item.subfolders,
      onTap: onTap,
    );
  }
}
