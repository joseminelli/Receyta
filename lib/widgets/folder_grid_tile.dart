import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tile de pasta pra grade da tela "todas as pastas" — mesmo azulejo e
/// pareamento cor/módulo de `resolveTileAppearance` que `folder_page.dart` e
/// o `_Tile` de `folders_strip.dart` já usam (§9.4).
class FolderGridTile extends StatelessWidget {
  const FolderGridTile({super.key, required this.item, required this.onTap});

  final FolderWithCounts item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final folder = item.folder;
    final tile = resolveTileAppearance(
      context.colors,
      color: folder.tileColor,
      motif: folder.tileMotif,
      fallbackColor: TileColor.violet,
    );

    return Material(
      color: tile.background,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TilePattern(
              motif: tile.motif,
              background: tile.background,
              patternColor: tile.patternColor,
              patternColorAlt: tile.patternColorAlt,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.folder_outlined, size: 20, color: tile.onColor),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        folder.name,
                        style: context.texts.bodyLarge?.copyWith(
                          color: tile.onColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _subtitle(),
                        style: context.texts.labelLarge?.copyWith(
                          color: tile.onColor.withValues(alpha: 0.82),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final count = item.recipeCount;
    final subfolders = item.subfolders;
    if (count == 0 && subfolders == 0) return 'Vazia';
    final parts = <String>[
      if (count > 0) '$count ${count == 1 ? 'receita' : 'receitas'}',
      if (subfolders > 0) '$subfolders ${subfolders == 1 ? 'pasta' : 'pastas'}',
    ];
    return parts.join(' · ');
  }
}
