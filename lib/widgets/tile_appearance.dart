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
