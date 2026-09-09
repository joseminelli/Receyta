import 'package:flutter/material.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Grade densa (célula alta) ou lista full-width (linha larga).
enum RecipeCardLayout { grid, list }

/// Card de receita da seção Receitas (§9.2, `coral`). Sem foto: o fundo é o
/// azulejo da §9.4 e o número ilustrativo (tempo total) resolve o card vazio.
/// Quando a receita ganhar imagem (B7), ela cobre o azulejo.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    this.layout = RecipeCardLayout.grid,
    this.onTap,
  });

  final Recipe recipe;
  final RecipeCardLayout layout;
  final VoidCallback? onTap;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isGrid = layout == RecipeCardLayout.grid;
    final minutes = _totalMinutes;

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: colors.coral,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TilePattern(
                motif: tileMotifForId(recipe.id),
                background: colors.coral,
                patternColor: colors.coralPattern,
              ),
              if (minutes != null)
                HeroNumber(
                  value: '$minutes',
                  color: colors.onSaturated,
                  size: isGrid ? 66 : 92,
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    recipe.name,
                    style: (isGrid
                            ? context.texts.displaySmall
                            : context.texts.displayMedium)
                        ?.copyWith(color: colors.onSaturated),
                    maxLines: isGrid ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return isGrid
        ? AspectRatio(aspectRatio: 0.82, child: card)
        : SizedBox(height: 120, child: card);
  }
}
