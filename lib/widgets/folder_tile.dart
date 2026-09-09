import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tile de pasta (§9.9). Colorido com azulejo quando tem [motif]; neutro
/// (`paperSoft`, reticências) quando não — o tile "ver todas as pastas".
class FolderTile extends StatelessWidget {
  const FolderTile({
    super.key,
    required this.label,
    required this.count,
    this.motif,
    this.onTap,
  });

  final String label;
  final int count;
  final TileMotif? motif;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motif = this.motif;

    final (bg, pattern, foreground) = switch (motif) {
      TileMotif.meiaLua => (colors.violet, colors.violetPattern, colors.onSaturated),
      TileMotif.arco => (colors.coral, colors.coralPattern, colors.onSaturated),
      TileMotif.diagonal => (colors.ink, colors.inkPattern, colors.onSaturated),
      TileMotif.ponto => (colors.lime, colors.limePattern, colors.ink),
      null => (colors.paperSoft, colors.paperSoft, colors.ink),
    };
    final muted = motif == null
        ? colors.textMuted
        : foreground.withValues(alpha: 0.82);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (motif != null)
                  TilePattern(
                    motif: motif,
                    background: bg,
                    patternColor: pattern,
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        motif == null
                            ? Icons.more_horiz
                            : Icons.folder_outlined,
                        size: 20,
                        color: foreground,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: context.texts.displaySmall
                                ?.copyWith(color: foreground),
                          ),
                          Text(
                            label,
                            style: context.texts.labelLarge
                                ?.copyWith(color: muted),
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
        ),
      ),
    );
  }
}
