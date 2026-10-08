import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/screens/folder_actions.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/features/folders/screens/recipe_drag.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/folder_shape.dart';

const _tileWidth = 148.0;
const _tileHeight = _tileWidth / kFolderAspectRatio;

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
        _buildHeader(context),
        _buildList(context, ref, folders),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
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
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<FolderWithCounts> folders,
  ) {
    return SizedBox(
      height: _tileHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        itemCount: folders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == folders.length) {
            return SizedBox(
              width: _tileWidth,
              height: _tileHeight,
              child: _NewTile(onTap: () => createFolderFlow(context, ref)),
            );
          }
          final it = folders[i];
          return DraggableFolder(
            folder: it.folder,
            child: FolderDropZone(
              folderId: it.folder.id,
              folderName: it.folder.name,
              child: SizedBox(
                width: _tileWidth,
                height: _tileHeight,
                child: FolderShapeCard(
                  folder: it.folder,
                  recipes: it.recipeCount,
                  subfolders: it.subfolders,
                  onTap: () => context.push('/folder/${it.folder.id}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewTile extends StatelessWidget {
  const _NewTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      shape: const FolderBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm + 2,
            kFolderTabHeight + AppSpacing.sm,
            AppSpacing.sm + 2,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.create_new_folder_outlined,
                  size: 20, color: colors.ink),
              Text(
                'Nova pasta',
                style:
                    context.texts.labelLarge?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
