import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Lixeira de 30 dias (RF-01.6): nada é apagado de verdade antes do prazo. Aqui
/// dá pra restaurar ou antecipar a exclusão definitiva.
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  static const _keep = Duration(days: 30);

  int _daysLeft(Recipe r, DateTime now) {
    final gone = (r.deletedAt ?? now).add(_keep).difference(now).inDays;
    return gone < 0 ? 0 : gone;
  }

  Future<void> _emptyAll(
    BuildContext context,
    WidgetRef ref,
    List<Recipe> items,
  ) async {
    final colors = context.colors;
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.delete_sweep_outlined,
      accent: colors.danger,
      title: 'Esvaziar a lixeira?',
      message: '${items.length} receita(s) somem de vez.',
      confirmLabel: 'Esvaziar',
    );
    if (!ok) return;
    final repo = ref.read(recipeRepositoryProvider);
    for (final r in items) {
      await repo.deleteForever(r.id);
    }
  }

  Future<void> _deleteForever(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.delete_forever_outlined,
      accent: context.colors.danger,
      title: 'Excluir "${recipe.name}"?',
      message: 'Isso apaga a receita de vez — não dá pra desfazer.',
      confirmLabel: 'Excluir',
    );
    if (!ok) return;
    await ref.read(recipeRepositoryProvider).deleteForever(recipe.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repo = ref.read(recipeRepositoryProvider);
    final trashed = ref.watch(trashedRecipesProvider);
    final now = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: const Text('Lixeira'),
        actions: [
          if (trashed.valueOrNull?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _EmptyTrashButton(
                onPressed: () => _emptyAll(context, ref, trashed.value!),
              ),
            ),
        ],
      ),
      body: trashed.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.ink),
        ),
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
                  'Não deu para carregar a lixeira',
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
                      icon: Icons.delete_outline,
                      background: colors.ink,
                      foreground: colors.lime,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'A lixeira está vazia',
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
              final r = items[i];
              return _TrashRow(
                recipe: r,
                daysLeft: _daysLeft(r, now),
                onRestore: () => repo.restore(r.id),
                onDeleteForever: () => _deleteForever(context, ref, r),
              );
            },
          );
        },
      ),
    );
  }
}

/// Ação "Esvaziar" da AppBar — pílula tingida de `danger` (mesmo tratamento
/// da pílula de contagem das tags) em vez do `TextButton` sem nenhum peso
/// visual pra uma ação destrutiva de topo de tela.
class _EmptyTrashButton extends StatelessWidget {
  const _EmptyTrashButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_sweep_outlined, size: 16, color: colors.danger),
              const SizedBox(width: AppSpacing.xs / 2),
              Text(
                'Esvaziar',
                style: context.texts.labelLarge?.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha da lixeira: cartão `paperSoft` arredondado com um distintivo
/// numérico grande (Bricolage, como o `HeroNumber`/`MetricStat` do resto do
/// app) pra contagem regressiva, em vez do `ListTile` chapado com subtítulo
/// de texto. Fica vermelho quando a receita some na próxima faxina.
class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.recipe,
    required this.daysLeft,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final Recipe recipe;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final urgent = daysLeft == 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: urgent ? colors.danger : colors.ink,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$daysLeft',
              style: AppTextStyles.display(18).copyWith(
                color: urgent ? colors.onSaturated : colors.lime,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipe.name,
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  urgent ? 'Some na próxima faxina' : 'dias restantes',
                  style: context.texts.labelMedium?.copyWith(
                    color: urgent ? colors.danger : colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleIconButton(
            icon: Icons.restore_from_trash_outlined,
            onTap: onRestore,
            tooltip: 'Restaurar',
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.delete_forever_outlined,
            background: colors.danger,
            onTap: onDeleteForever,
            tooltip: 'Excluir de vez',
          ),
        ],
      ),
    );
  }
}

/// Botão discreto de acesso à lixeira — só aparece quando há algo lá.
class TrashLink extends ConsumerWidget {
  const TrashLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(trashedRecipesProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/trash'),
        icon: Icon(Icons.delete_outline,
            size: 18, color: context.colors.textMuted),
        label: Text(
          'Lixeira · $count',
          style: context.texts.labelLarge
              ?.copyWith(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
