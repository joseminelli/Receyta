import 'package:flutter/material.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Card grande da "Recentes" (§9.8): bloco de azulejo em cima com o tempo total
/// sangrando na costura, faixa `ink` embaixo com nome e chips.
class FeaturedRecipeCard extends StatelessWidget {
  const FeaturedRecipeCard({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  static const double _patternHeight = 240;
  static const double _numberSize = 132;

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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _patternHeight,
                    child: TilePattern(
                      motif: TileMotif.arco,
                      background: colors.coral,
                      patternColor: colors.coralPattern,
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
                        Text(
                          recipe.name,
                          style: context.texts.displayMedium
                              ?.copyWith(color: colors.onSaturated),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
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
              if (minutes != null)
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _Chip('$minutes min', accent: true),
                ),
              if (minutes != null)
                Positioned(
                  left: AppSpacing.md - 2,
                  top: _patternHeight - _numberSize * 0.82,
                  child: MediaQuery.withNoTextScaling(
                    child: ExcludeSemantics(
                      child: Text(
                        '$minutes',
                        style: AppTextStyles.display(_numberSize)
                            .copyWith(color: colors.onSaturated),
                        maxLines: 1,
                        softWrap: false,
                      ),
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

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: accent ? colors.ink : colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: context.texts.labelLarge?.copyWith(
          color: accent
              ? colors.lime
              : colors.onSaturated.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
