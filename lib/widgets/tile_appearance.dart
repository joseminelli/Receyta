import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Cores concretas de um azulejo, prontas pro [TilePattern] e pro texto por
/// cima. Sai de [resolveTileAppearance].
typedef TileAppearance = ({
  TileMotif motif,
  Color background,
  Color patternColor,
  Color patternColorAlt,
  Color onColor,
});

/// Tag do `Hero` que faz o azulejo da receita "crescer" do card da lista até
/// virar o hero da tela de detalhe — mesma string nos dois lados
/// ([RecipeCard]/[FeaturedRecipeCard] e o hero de `recipe_detail_page.dart`).
String recipeTileHeroTag(String recipeId) => 'recipe-tile-$recipeId';

final _recipeCardRadius = BorderRadius.circular(AppRadii.md);
final _recipeHeroRadius =
    const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg));

/// `flightShuttleBuilder` do Hero de [recipeTileHeroTag]: o card (todos os
/// cantos, raio pequeno) e o hero (só embaixo, raio grande) têm formas
/// diferentes, e o `Hero` sozinho só interpola posição/tamanho — sem isto o
/// bloco voava com canto reto (nenhum dos dois raios) o trajeto inteiro.
/// Anima o `BorderRadius` de uma forma pra outra durante o voo (invertido
/// no pop, `direction` cuida disso).
Widget recipeTileHeroFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final toHero = toHeroContext.widget as Hero;
  final fromRadius = direction == HeroFlightDirection.push
      ? _recipeCardRadius
      : _recipeHeroRadius;
  final toRadius = direction == HeroFlightDirection.push
      ? _recipeHeroRadius
      : _recipeCardRadius;
  return AnimatedBuilder(
    animation: animation,
    child: toHero.child,
    builder: (context, child) {
      // No push, a `animation` da rota já vai 0→1 (início→fim do voo). No
      // pop, o Flutter passa essa MESMA animação invertida — ela vai 1→0
      // nesse sentido. Sem desfazer isso aqui, o raio interpolava ao
      // contrário: chegava quadrado no card em vez de arredondado.
      final progress = direction == HeroFlightDirection.push
          ? animation.value
          : 1 - animation.value;
      return ClipRRect(
        borderRadius: BorderRadius.lerp(fromRadius, toRadius, progress)!,
        child: child,
      );
    },
  );
}

/// Pareamento padrão da §9.2/§9.4.
TileColor _colorForMotif(TileMotif m) => switch (m) {
      TileMotif.arco => TileColor.coral,
      TileMotif.meiaLua => TileColor.violet,
      TileMotif.diagonal => TileColor.ink,
      TileMotif.ponto => TileColor.lime,
    };

TileMotif _motifForColor(TileColor c) => switch (c) {
      TileColor.coral => TileMotif.arco,
      TileColor.violet => TileMotif.meiaLua,
      TileColor.ink => TileMotif.diagonal,
      TileColor.lime => TileMotif.ponto,
    };

/// Resolve a escolha do usuário ([color]/[motif], qualquer um pode ser nulo)
/// pras cores concretas. Se ambos forem nulos: deriva do [seedId] (mantém a
/// estampa histórica da receita) ou cai em [fallbackColor] (pastas → violet).
/// Se só um for dado, o outro vem do pareamento padrão.
TileAppearance resolveTileAppearance(
  AppColors colors, {
  TileColor? color,
  TileMotif? motif,
  String? seedId,
  TileColor fallbackColor = TileColor.coral,
}) {
  final TileColor c;
  final TileMotif m;
  if (color != null && motif != null) {
    c = color;
    m = motif;
  } else if (color != null) {
    c = color;
    m = _motifForColor(color);
  } else if (motif != null) {
    m = motif;
    c = _colorForMotif(motif);
  } else if (seedId != null) {
    m = tileMotifForId(seedId);
    c = _colorForMotif(m);
  } else {
    c = fallbackColor;
    m = _motifForColor(fallbackColor);
  }

  final (bg, pattern) = switch (c) {
    TileColor.coral => (colors.coral, colors.coralPattern),
    TileColor.violet => (colors.violet, colors.violetPattern),
    TileColor.ink => (colors.ink, colors.inkPattern),
    TileColor.lime => (colors.lime, colors.limePattern),
  };
  final alt = c == TileColor.ink
      ? colors.inkPatternAlt
      : Color.alphaBlend(Colors.black.withValues(alpha: 0.12), pattern);
  final onColor = c == TileColor.lime ? colors.ink : colors.onSaturated;

  return (
    motif: m,
    background: bg,
    patternColor: pattern,
    patternColorAlt: alt,
    onColor: onColor,
  );
}
