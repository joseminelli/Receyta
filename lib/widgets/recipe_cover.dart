import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Capa da receita: a foto, se ela tem uma, senão o azulejo (§9.4). É o filho
/// do `Hero` de [recipeTileHeroTag] nos cards e no detalhe, então o voo
/// funciona igual com ou sem foto.
///
/// O azulejo fica por baixo da foto: enquanto o arquivo carrega, ou se ele
/// sumir do disco, a capa continua colorida em vez de abrir um buraco.
/// [scrim] escurece o pé da foto pra o nome por cima continuar legível.
class RecipeCover extends ConsumerWidget {
  const RecipeCover({
    super.key,
    required this.recipe,
    required this.tile,
    this.scrim = false,
    this.cacheWidth = 800,
  });

  final Recipe recipe;
  final TileAppearance tile;
  final bool scrim;

  /// Largura de decodificação: o card não precisa dos 1600 px do arquivo.
  final int cacheWidth;

  /// Cor do texto por cima da capa: branco sobre foto, o par do azulejo sem.
  static Color onColor(BuildContext context, Recipe recipe, TileAppearance t) =>
      recipe.imagePath == null ? t.onColor : context.colors.onSaturated;

  Widget _tile() => TilePattern(
        motif: tile.motif,
        background: tile.background,
        patternColor: tile.patternColor,
        patternColorAlt: tile.patternColorAlt,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = recipe.imagePath;
    if (name == null) return _tile();
    final dir = ref.watch(recipeImagesDirProvider).valueOrNull;
    if (dir == null) return _tile();

    return Stack(
      fit: StackFit.expand,
      children: [
        _tile(),
        Image.file(
          File(p.join(dir.path, name)),
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        if (scrim)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.45, 1],
                colors: [
                  Colors.transparent,
                  context.colors.ink.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
