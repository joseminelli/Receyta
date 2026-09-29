import 'package:flutter/material.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Card de receita da grade (§9.4). Bloco de azulejo em cima, faixa `paperSoft`
/// com nome e tempo embaixo. Sem foto ainda — a imagem (B7) cobre o azulejo.
/// A cor e o módulo vêm da escolha do usuário (`recipe.tileColor/tileMotif`),
/// ou derivam do id quando ele não escolheu.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, this.onTap});

  final Recipe recipe;
  final VoidCallback? onTap;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );
    final minutes = _totalMinutes;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: colors.paperSoft,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.45,
                // `ColoredBox` fora do `Hero`: o `TilePattern` pinta o
                // próprio fundo chapado, então enquanto ele "voa" (some daqui
                // e some do destino, só existe na camada de overlay do voo)
                // sobrava o `paperSoft` do card por baixo — um flash sem cor
                // nenhuma. Esta cópia parada da cor cobre esse buraco.
                child: ColoredBox(
                  color: tile.background,
                  child: Hero(
                    tag: recipeTileHeroTag(recipe.id),
                    flightShuttleBuilder: recipeTileHeroFlightShuttleBuilder,
                    child: TilePattern(
                      motif: tile.motif,
                      background: tile.background,
                      patternColor: tile.patternColor,
                      patternColorAlt: tile.patternColorAlt,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      recipe.name,
                      style: context.texts.displaySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      minutes == null ? '—' : '$minutes min',
                      style: context.texts.labelLarge
                          ?.copyWith(color: colors.textMuted),
                    ),
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
