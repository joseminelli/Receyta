import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/screens/folder_actions.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/features/folders/screens/recipe_drag.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
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
    final collections = ref.watch(smartCollectionsProvider);
    if (folders.isEmpty && collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          hasFolders: folders.isNotEmpty,
          collectionCount: collections.length,
        ),
        if (folders.isNotEmpty) _buildList(context, ref, folders),
      ],
    );
  }

  /// O atalho das coleções mora na linha das pastas, pra não gastar uma
  /// linha própria na home. Sem pasta nenhuma, sobra só ele, à direita.
  Widget _buildHeader(
    BuildContext context, {
    required bool hasFolders,
    required int collectionCount,
  }) {
    final hasCollections = collectionCount > 0;
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasCollections)
          _CollectionsButton(
            count: collectionCount,
            onTap: () => context.push('/collections'),
          ),
        if (hasFolders) ...[
          const SizedBox(width: AppSpacing.xs),
          PillButton(
            label: 'Ver todas',
            variant: PillButtonVariant.ghost,
            dense: true,
            onPressed: () => context.push('/folders'),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: hasFolders
          ? SectionHeader(title: 'Pastas', action: actions)
          : Align(alignment: Alignment.centerRight, child: actions),
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

/// Atalho das coleções: pílula escura com o raio numa bolinha lima e, no fim,
/// quantas coleções têm receita hoje. Do tamanho do botão que ocupava o lugar.
class _CollectionsButton extends StatelessWidget {
  const _CollectionsButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Coleções, $count',
      child: Material(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.lime,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.bolt_rounded, size: 18, color: colors.ink),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Coleções',
                    style: context.texts.labelLarge
                        ?.copyWith(color: colors.onSaturated),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: context.texts.labelLarge?.copyWith(
                      color: colors.lime,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
