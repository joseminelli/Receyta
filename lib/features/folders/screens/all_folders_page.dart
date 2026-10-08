import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/breakpoints.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/folder_grid_tile.dart';
import 'package:receyta/widgets/folder_shape.dart';
import 'package:receyta/widgets/pull_to_refresh.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Todas as pastas de raiz, em grade — o "Ver todas" da faixa de pastas da
/// home, que só mostra as 7 mais recentes (§ "recentes"). Ordem alfabética,
/// como sempre foi: só a prateleira da home usa a ordenação por uso.
class AllFoldersPage extends ConsumerWidget {
  const AllFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(rootFoldersProvider);

    Future<void> refresh() async {
      ref.invalidate(rootFoldersProvider);
      await ref.read(rootFoldersProvider.future);
    }

    final count = folders.valueOrNull?.length;
    return HeaderScaffold(
      title: 'Pastas',
      subtitle:
          count == null ? null : '$count ${count == 1 ? 'pasta' : 'pastas'}',
      color: TileColor.violet,
      body: PullToRefreshControl(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
            folders.when(
              loading: () => _buildLoading(),
              error: (_, __) => _buildError(context),
              data: (items) => items.isEmpty
                  ? _buildEmpty(context)
                  : _buildGrid(context, items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: BrandLoader()),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateBadge(
              icon: Icons.priority_high_rounded,
              background: colors.danger,
              foreground: colors.onSaturated,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não deu para carregar as pastas',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateBadge(
              icon: Icons.folder_outlined,
              background: colors.violet,
              foreground: colors.onSaturated,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma pasta ainda',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<FolderWithCounts> items) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: kGridTileMaxExtent,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: kFolderAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => FolderGridTile(
            item: items[i],
            onTap: () => context.push('/folder/${items[i].folder.id}'),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}
