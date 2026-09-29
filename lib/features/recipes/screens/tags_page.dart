import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';

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
    final colors = context.colors;
    final tags = ref.watch(tagsWithCountsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('Tags')),
      body: tags.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => Center(
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
        ),
        data: (items) {
          if (items.isEmpty) {
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
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screen),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final (:tag, :count) = items[i];
              return _TagRow(
                tag: tag,
                count: count,
                onDelete: () => _delete(context, ref, tag, count),
              );
            },
          );
        },
      ),
    );
  }
}

/// Linha da lista de tags: cartão `paperSoft` arredondado, nome em negrito e
/// a contagem de uso como pílula tingida de `violet` — em vez do
/// `ListTile`+`Divider` chapado que o Material dá por padrão.
class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.count,
    required this.onDelete,
  });

  final Tag tag;
  final int count;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag.name,
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.violet.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    count == 0
                        ? 'Não usada'
                        : '$count receita${count == 1 ? '' : 's'}',
                    style: context.texts.labelMedium
                        ?.copyWith(color: colors.violet),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleIconButton(
            icon: Icons.delete_outline,
            background: colors.danger,
            onTap: onDelete,
            tooltip: 'Apagar',
          ),
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
      icon: Icon(Icons.sell_outlined, size: 18, color: context.colors.textMuted),
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
