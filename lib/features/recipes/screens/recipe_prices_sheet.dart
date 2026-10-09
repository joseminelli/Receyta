import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/screens/cost_notes.dart';
import 'package:receyta/features/recipes/screens/ingredient_price_sheet.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Os ingredientes da receita com o custo de cada um. Tocar numa linha abre o
/// preço dele — informar o que falta é o caminho pro total ficar completo.
Future<void> showRecipePricesSheet(BuildContext context, String recipeId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RecipePricesSheet(recipeId: recipeId),
  );
}

class _RecipePricesSheet extends ConsumerWidget {
  const _RecipePricesSheet({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = ref.watch(recipeCostProvider(recipeId));
    final catalog = ref.watch(ingredientCatalogProvider);
    final colors = context.colors;

    final lines = [
      for (final l in cost?.lines ?? const <LineCost>[])
        if (l.counted) l,
    ];

    return AppSheetFrame(
      title: 'Preços da receita',
      subtitle: cost != null && cost.complete
          ? 'Total ≈ ${formatMoney(cost.totalCents)}'
          : 'Informe o preço de cada ingrediente para ver o total',
      scrollable: true,
      child: Column(
        children: [
          for (final line in lines)
            _Row(
              line: line,
              onTap: line.line.ingredientId == null ||
                      catalog[line.line.ingredientId] == null
                  ? null
                  : () => showIngredientPriceSheet(
                        context,
                        catalog[line.line.ingredientId]!,
                        suggestedUnit: suggestedPriceUnit(line.line.unitId),
                      ),
            ),
          if (cost != null && cost.lines.any((l) => !l.counted)) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Itens sem quantidade ou "a gosto" (como sal e cheiro-verde) '
              'ficam fora da conta.',
              style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          const HowItWorksLink(),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Esta receita ainda não tem ingredientes.',
                style:
                    context.texts.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.line, required this.onTap});

  final LineCost line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (text, muted) = switch ((line.cents, line.gap)) {
      (final int cents, _) => (formatMoney(cents), false),
      (_, CostGap.cannotConvert) => ('Unidade não converte', true),
      _ => ('Definir preço', true),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Expanded(
              child: Text(
                line.name,
                style: context.texts.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              text,
              style: context.texts.labelLarge?.copyWith(
                color: muted ? colors.textMuted : colors.ink,
                fontWeight: muted ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
