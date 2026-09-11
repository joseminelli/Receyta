import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/folder_actions.dart';
import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/features/folders/recipe_drag.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Faixa "Pastas" da home (§9.9): rolagem horizontal de tiles `violet` com
/// meia-lua, mais um tile neutro pra criar pasta. Some quando não há pasta
/// nenhuma — a primeira pasta se cria pelo menu do `+` no cabeçalho.
class FoldersStrip extends ConsumerWidget {
  const FoldersStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(recentFoldersProvider).valueOrNull ??
        const <FolderWithCounts>[];
    if (folders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: SectionHeader(
            title: 'Pastas',
            action: PillButton(
              label: 'Ver todas',
              variant: PillButtonVariant.ghost,
              dense: true,
              onPressed: () => context.push('/folders'),
            ),
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            itemCount: folders.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              if (i == folders.length) {
                return _NewTile(onTap: () => createFolderFlow(context, ref));
              }
              final it = folders[i];
              return DraggableFolder(
                folder: it.folder,
                child: FolderDropZone(
                  folderId: it.folder.id,
                  folderName: it.folder.name,
                  child: _Tile(
                    folder: it.folder,
                    count: it.recipeCount,
                    subfolders: it.subfolders,
                    onTap: () => context.push('/folder/${it.folder.id}'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.folder,
    required this.count,
    required this.subfolders,
    required this.onTap,
  });

  final Folder folder;
  final int count;
  final int subfolders;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tile = resolveTileAppearance(
      context.colors,
      color: folder.tileColor,
      motif: folder.tileMotif,
      fallbackColor: TileColor.violet,
    );
    return SizedBox(
      width: 128,
      child: Material(
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
                    Icon(Icons.folder_outlined,
                        size: 20, color: tile.onColor),
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
      ),
    );
  }

  String _subtitle() {
    if (count == 0 && subfolders == 0) return 'Vazia';
    final parts = <String>[
      if (count > 0) '$count ${count == 1 ? 'receita' : 'receitas'}',
      if (subfolders > 0) '$subfolders ${subfolders == 1 ? 'pasta' : 'pastas'}',
    ];
    return parts.join(' · ');
  }
}

class _NewTile extends StatelessWidget {
  const _NewTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 128,
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.create_new_folder_outlined,
                    size: 20, color: colors.ink),
                Text(
                  'Nova pasta',
                  style: context.texts.labelLarge
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
