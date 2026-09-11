import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/folder_actions.dart';
import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/features/folders/recipe_drag.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tela de uma pasta (§RF-02): cabeçalho `violet` com meia-lua (§9.4 — pastas),
/// faixa de subpastas e a grade de receitas diretas. O ⋯ renomeia, move, cria
/// subpasta ou exclui (o conteúdo sobe um nível).
class FolderPage extends ConsumerWidget {
  const FolderPage({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folder = ref.watch(folderProvider(folderId)).valueOrNull;
    final subfolders =
        ref.watch(subfoldersProvider(folderId)).valueOrNull ?? const [];
    final recipes =
        ref.watch(folderRecipesProvider(folderId)).valueOrNull ?? const [];

    if (folder == null) {
      return Scaffold(
        backgroundColor: context.colors.paper,
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Text('Pasta não encontrada', style: context.texts.bodyMedium),
        ),
      );
    }

    final parentId = folder.parentId;
    final parentName = parentId == null
        ? null
        : ref.watch(folderProvider(parentId)).valueOrNull?.name;

    return Scaffold(
      backgroundColor: context.colors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  folder: folder,
                  recipeCount: recipes.length,
                  subfolderCount: subfolders.length,
                  onMenu: () => showFolderMenu(
                    context,
                    ref,
                    folder,
                    onDeleted: () => context.pop(),
                  ),
                ),
              ),
              if (subfolders.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Subfolders(items: subfolders),
                ),
              if (recipes.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.lg,
                    AppSpacing.screen,
                    AppSpacing.sm,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(
                      title: 'Receitas',
                      action: Text(
                        '${recipes.length}',
                        style: context.texts.displaySmall
                            ?.copyWith(color: context.colors.textMuted),
                      ),
                    ),
                  ),
                ),
              if (recipes.isEmpty && subfolders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Empty(
                    onNewSubfolder: () =>
                        createFolderFlow(context, ref, parentId: folderId),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    0,
                    AppSpacing.screen,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => DraggableRecipe(
                        recipe: recipes[i],
                        child: RecipeCard(
                          recipe: recipes[i],
                          onTap: () => context.push('/recipe/${recipes[i].id}'),
                        ),
                      ),
                      childCount: recipes.length,
                    ),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SafeArea(
              top: false,
              child: Padding(
                // Clareia a `FolderExitDropBar` (~96 de altura visível) + folga.
                padding: const EdgeInsets.only(bottom: 112, right: 16),
                child: const RecipeDeleteDropTarget(),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FolderExitDropBar(
              parentId: parentId,
              parentName: parentName,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.folder,
    required this.recipeCount,
    required this.subfolderCount,
    required this.onMenu,
  });

  final Folder folder;
  final int recipeCount;
  final int subfolderCount;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final tile = resolveTileAppearance(
      context.colors,
      color: folder.tileColor,
      motif: folder.tileMotif,
      fallbackColor: TileColor.violet,
    );
    final onColor = tile.onColor;
    final bits = <String>[
      if (recipeCount > 0)
        '$recipeCount ${recipeCount == 1 ? 'receita' : 'receitas'}',
      if (subfolderCount > 0)
        '$subfolderCount ${subfolderCount == 1 ? 'subpasta' : 'subpastas'}',
    ];

    return AnnotatedRegion(
      value: SystemBars.onDark,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg),
        ),
        child: Container(
          color: tile.background,
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: TilePattern(
                    motif: tile.motif,
                    background: tile.background,
                    patternColor: tile.patternColor,
                    patternColorAlt: tile.patternColorAlt,
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xs,
                    AppSpacing.screen,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CircleButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const Spacer(),
                          _CircleButton(icon: Icons.more_horiz, onTap: onMenu),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'PASTA',
                        style:
                            context.texts.labelSmall?.copyWith(color: onColor),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        folder.name,
                        style:
                            AppTextStyles.display(40).copyWith(color: onColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bits.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          bits.join('  ·  '),
                          style: context.texts.bodyMedium?.copyWith(
                            color: onColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Subfolders extends StatelessWidget {
  const _Subfolders({required this.items});

  final List<FolderWithCounts> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: SectionHeader(title: 'Subpastas'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final it = items[i];
                return SizedBox(
                  width: 132,
                  child: DraggableFolder(
                    folder: it.folder,
                    child: FolderDropZone(
                      folderId: it.folder.id,
                      folderName: it.folder.name,
                      child: _MiniFolder(
                        folder: it.folder,
                        count: it.recipeCount,
                        onTap: () => context.push('/folder/${it.folder.id}'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniFolder extends StatelessWidget {
  const _MiniFolder({
    required this.folder,
    required this.count,
    required this.onTap,
  });

  final Folder folder;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = resolveTileAppearance(
      colors,
      color: folder.tileColor,
      motif: folder.tileMotif,
      fallbackColor: TileColor.violet,
    ).background;
    return Material(
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
              Icon(Icons.folder_outlined, size: 20, color: accent),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    folder.name,
                    style: context.texts.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    count == 0
                        ? 'Vazia'
                        : '$count ${count == 1 ? 'receita' : 'receitas'}',
                    style: context.texts.labelLarge
                        ?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onNewSubfolder});

  final VoidCallback onNewSubfolder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pasta vazia',
            style: context.texts.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mova receitas pra cá pelo ⋯ da receita,\nou crie uma subpasta.',
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onNewSubfolder,
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Nova subpasta'),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 22, color: colors.onSaturated),
        ),
      ),
    );
  }
}
