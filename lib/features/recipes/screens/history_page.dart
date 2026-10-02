import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/engine/cook_log_format.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Tudo o que você cozinhou (G7), do mais recente ao mais antigo, agrupado por
/// mês. Cada linha abre a receita. Apagar um registro continua sendo na folha
/// "Cozinhei" da própria receita.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(allCookLogsProvider);
    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(title: const Text('Histórico')),
      body: logs.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => _buildMessage(
          context,
          icon: Icons.priority_high_rounded,
          background: context.colors.danger,
          foreground: context.colors.onSaturated,
          title: 'Não deu para carregar o histórico',
        ),
        data: (items) => items.isEmpty
            ? _buildMessage(
                context,
                icon: Icons.restaurant_outlined,
                background: context.colors.ink,
                foreground: context.colors.lime,
                title: 'Nada cozinhado ainda',
                body: 'Toque em "Cozinhei!" no modo cozinha, ou registre pelo '
                    'cartão "Cozinhei" de qualquer receita.',
              )
            : _buildList(context, items),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required Color background,
    required Color foreground,
    required String title,
    String? body,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(icon: icon, background: background, foreground: foreground),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<CookLog> items) {
    final colors = context.colors;
    final now = DateTime.now();
    final recipes = {for (final l in items) l.recipeId}.length;
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(
          '${items.length} ${items.length == 1 ? 'vez' : 'vezes'} · '
          '$recipes ${recipes == 1 ? 'receita' : 'receitas'}',
          style: context.texts.labelSmall?.copyWith(color: colors.textMuted),
        ),
      ),
    ];

    String? month;
    for (final log in items) {
      final label = formatMonthYear(log.cookedAt);
      if (label != month) {
        month = label;
        children.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(label, style: AppTextStyles.display(30)),
          ),
        );
      }
      children.add(_HistoryRow(log: log, now: now));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: children,
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.log, required this.now});

  final CookLog log;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final day = log.cookedAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => context.push('/recipe/${log.recipeId}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Text('${day.day}', style: AppTextStyles.display(34)),
                      Text(
                        formatCookedDate(day, now).split(',').first.toUpperCase(),
                        style: context.texts.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.recipeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (log.hasNote)
                        Text(log.note!, style: context.texts.bodyMedium),
                      Text(
                        cookedAgo(log.cookedAt, now),
                        style: context.texts.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
