import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Gerenciar tags (§RF-01.10): lista tudo, inclusive as que não estão em
/// nenhuma receita, pra poder apagá-las. Apagar tira a tag de todas as receitas
/// e do filtro pra sempre.
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    int count,
  ) async {
    final colors = context.colors;
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.delete_outline,
      accent: colors.danger,
      title: 'Apagar "${tag.name}"?',
      message: count == 0
          ? 'Não está em nenhuma receita.'
          : 'Sai de $count receita${count == 1 ? '' : 's'}.',
      confirmLabel: 'Apagar',
    );
    if (ok) {
      await ref.read(tagRepositoryProvider).delete(tag.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(tagsWithCountsProvider);

    final count = tags.valueOrNull?.length;
    return HeaderScaffold(
      title: 'Tags',
      subtitle: count == null ? null : '$count ${count == 1 ? 'tag' : 'tags'}',
      color: TileColor.coral,
      body: tags.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => _buildError(context),
        data: (items) => items.isEmpty
            ? _buildEmpty(context)
            : _buildList(context, ref, items),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;
    return Center(
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
              'Não deu para carregar as tags',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateBadge(
              icon: Icons.sell_outlined,
              background: colors.violet,
              foreground: colors.onSaturated,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma tag ainda',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<({Tag tag, int count})> items,
  ) {
    final maxCount = items.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screen),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final (:tag, :count) = items[i];
        return _TagRow(
          tag: tag,
          count: count,
          maxCount: maxCount,
          onDelete: () => _delete(context, ref, tag, count),
        );
      },
    );
  }
}

/// Cartão de uma tag: à esquerda um azulejo do app (cor e textura próprias de
/// cada tag, sempre as mesmas) com o número de receitas bem grande; à direita
/// o nome, "N receitas" e uma barra de quanto ela é usada em relação à tag
/// mais usada. Tag sem receita fica apagada. O botão de apagar fica na ponta.
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.count,
    required this.maxCount,
    required this.onDelete,
  });

  final Tag tag;
  final int count;
  final int maxCount;
  final VoidCallback onDelete;

  static const _tileSize = 84.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unused = count == 0;
    final tile = resolveTileAppearance(colors, seedId: tag.id);

    return Container(
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTile(context, tile, unused),
            Expanded(child: _buildInfo(context, unused)),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: CircleIconButton(
                  icon: Icons.delete_outline,
                  background: colors.danger,
                  onTap: onDelete,
                  tooltip: 'Apagar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, TileAppearance tile, bool unused) {
    final colors = context.colors;
    return SizedBox(
      width: _tileSize,
      child: Opacity(
        opacity: unused ? 0.45 : 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TilePattern(
              motif: tile.motif,
              background: tile.background,
              patternColor: tile.patternColor,
              patternColorAlt: tile.patternColorAlt,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$count',
                    style: AppTextStyles.display(38)
                        .copyWith(color: tile.onColor, height: 1),
                  ),
                ),
              ),
            ),
            if (unused)
              Positioned(
                top: 6,
                left: 6,
                child: Icon(Icons.sell_outlined, size: 16, color: colors.ink),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, bool unused) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tag.name,
            style: AppTextStyles.display(22).copyWith(
              color: unused ? colors.textMuted : colors.ink,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            unused ? 'Não usada' : '$count receita${count == 1 ? '' : 's'}',
            style: context.texts.labelLarge?.copyWith(color: colors.textMuted),
          ),
          if (!unused && maxCount > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Stack(
                children: [
                  Container(height: 6, color: colors.paper),
                  FractionallySizedBox(
                    widthFactor: (count / maxCount).clamp(0.06, 1.0),
                    child: Container(height: 6, color: colors.ink),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Link discreto pra tela de tags — só quando existe alguma tag.
class TagsLink extends ConsumerWidget {
  const TagsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tagsWithCountsProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => context.push('/tags'),
      icon:
          Icon(Icons.sell_outlined, size: 18, color: context.colors.textMuted),
      label: Text(
        'Tags',
        style:
            context.texts.labelLarge?.copyWith(color: context.colors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
