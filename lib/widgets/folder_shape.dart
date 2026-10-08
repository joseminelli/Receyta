import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Altura da orelha da pasta. O conteúdo do cartão começa abaixo dela.
const kFolderTabHeight = 12.0;

/// Proporção (largura / altura) dos cartões de pasta: um retângulo só um
/// pouco mais largo que alto.
const kFolderAspectRatio = 1.5;

const _kFolderRadius = AppRadii.sm;
const _kFolderSlope = 14.0;

/// Contorno de pasta: um retângulo de cantos arredondados com uma orelha no
/// canto superior esquerdo. Serve de `shape` para `Material`/`ShapeDecoration`,
/// então o recorte, a tinta do toque e o anel de "soltar aqui" seguem a forma.
class FolderBorder extends OutlinedBorder {
  const FolderBorder({super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final w = rect.width;
    final h = rect.height;
    final tabW = math.min(w * 0.42, 92.0);
    const th = kFolderTabHeight;
    const r = _kFolderRadius;
    const s = _kFolderSlope;
    const radius = Radius.circular(r);

    final path = Path()
      ..moveTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: radius)
      ..lineTo(tabW, 0)
      ..cubicTo(tabW + s * 0.55, 0, tabW + s * 0.45, th, tabW + s, th)
      ..lineTo(w - r, th)
      ..arcToPoint(Offset(w, th + r), radius: radius)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: radius)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: radius)
      ..close();
    return path.shift(rect.topLeft);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  /// O traço fica todo por dentro do contorno: o `Material` recorta o que
  /// passa da forma, e um traço centrado na borda perderia metade da espessura.
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    canvas.drawPath(
      getOuterPath(rect.deflate(side.width / 2), textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  FolderBorder copyWith({BorderSide? side}) =>
      FolderBorder(side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => FolderBorder(side: side.scale(t));
}

/// Cartão de pasta no formato de pasta. O número de receitas vem grande no
/// alto (as subpastas só quando não há receita), o nome embaixo. Por padrão
/// leva o azulejo do app (cor e módulo de `resolveTileAppearance`); com
/// [outlined] fica neutro (`paperSoft`), com a cor só no contorno. Quem
/// decide o tamanho é o pai; [compact] é a versão só com o nome, usada ao
/// arrastar.
class FolderShapeCard extends StatelessWidget {
  const FolderShapeCard({
    super.key,
    required this.folder,
    this.recipes = 0,
    this.subfolders = 0,
    this.onTap,
    this.compact = false,
    this.outlined = false,
  });

  final Folder folder;
  final int recipes;
  final int subfolders;
  final VoidCallback? onTap;
  final bool compact;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: folder.tileColor,
      motif: folder.tileMotif,
      fallbackColor: TileColor.violet,
    );
    final onColor = outlined ? colors.ink : tile.onColor;
    final mutedColor =
        outlined ? colors.textMuted : onColor.withValues(alpha: 0.82);
    final pad = compact ? AppSpacing.xs : AppSpacing.sm;

    return Material(
      color: outlined ? colors.paperSoft : tile.background,
      shape: FolderBorder(
        side: outlined
            ? BorderSide(color: tile.background, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!outlined)
              TilePattern(
                motif: tile.motif,
                background: tile.background,
                patternColor: tile.patternColor,
                patternColorAlt: tile.patternColorAlt,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                pad + 4,
                kFolderTabHeight + pad,
                pad + 4,
                pad + 2,
              ),
              child: Column(
                mainAxisAlignment: compact
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact) _buildCount(context, onColor, mutedColor),
                  Text(
                    folder.name,
                    style: (compact
                            ? context.texts.labelLarge
                            : AppTextStyles.display(19))
                        ?.copyWith(
                      color: onColor,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "12 receitas" com o número grande; sem receita mostra as subpastas, e
  /// sem nenhuma das duas, "Vazia".
  Widget _buildCount(BuildContext context, Color onColor, Color mutedColor) {
    final labelStyle = context.texts.labelLarge?.copyWith(color: mutedColor);
    if (recipes == 0 && subfolders == 0) {
      return Text('Vazia', style: labelStyle);
    }
    final showRecipes = recipes > 0;
    final n = showRecipes ? recipes : subfolders;
    final label = showRecipes
        ? (n == 1 ? 'receita' : 'receitas')
        : (n == 1 ? 'pasta' : 'pastas');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$n',
          style: AppTextStyles.display(34).copyWith(color: onColor, height: 1),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
