import 'package:flutter/material.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Card grande da "Recentes" (§9.8): nome em escala grande sobre o bloco de
/// azulejo `coral`, faixa `ink` embaixo com o tempo grande e os chips.
class FeaturedRecipeCard extends StatelessWidget {
  const FeaturedRecipeCard({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  static const double _patternHeight = 150;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final minutes = _totalMinutes;

    final chips = [
      if (recipe.servings != null) '${recipe.servings} porções',
      if (recipe.isFavorite) 'Favorita',
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Material(
        color: colors.ink,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _patternHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TilePattern(
                        motif: TileMotif.arco,
                        background: colors.coral,
                        patternColor: colors.coralPattern,
                      ),
                    ),
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.sm,
                      child: Text(
                        recipe.name,
                        style: AppTextStyles.display(42)
                            .copyWith(color: colors.onSaturated),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (minutes != null)
                      Text.rich(
                        TextSpan(
                          text: '$minutes',
                          children: const [
                            TextSpan(
                              text: ' min',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        style: AppTextStyles.display(26)
                            .copyWith(color: colors.onSaturated),
                      ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [for (final c in chips) _Chip(c)],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: context.texts.labelLarge
            ?.copyWith(color: colors.onSaturated.withValues(alpha: 0.82)),
      ),
    );
  }
}
