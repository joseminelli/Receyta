import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/features/folders/folders_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/folder_grid_tile.dart';
import 'package:receyta/widgets/pull_to_refresh.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Todas as pastas de raiz, em grade — o "Ver todas" da faixa de pastas da
/// home, que só mostra as 7 mais recentes (§ "recentes"). Ordem alfabética,
/// como sempre foi: só a prateleira da home usa a ordenação por uso.
class AllFoldersPage extends ConsumerWidget {
  const AllFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final folders = ref.watch(rootFoldersProvider);

    Future<void> refresh() async {
      ref.invalidate(rootFoldersProvider);
      await ref.read(rootFoldersProvider.future);
    }

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('Pastas')),
      body: PullToRefreshControl(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
            folders.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: BrandLoader()),
              ),
              error: (_, __) => SliverFillRemaining(
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
              ),
              data: (items) {
                if (items.isEmpty) {
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
                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => FolderGridTile(
                        item: items[i],
                        onTap: () =>
                            context.push('/folder/${items[i].folder.id}'),
                      ),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
