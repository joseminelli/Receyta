import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Esqueleto das telas simples (histórico, tags, ingredientes, lixeira,
/// pastas): um cabeçalho baixo, na cor da tela e com a textura do app, no
/// lugar da AppBar. Ocupa pouco: botão de voltar, título grande numa linha só
/// e, se preciso, um subtítulo e uma ação à direita.
class HeaderScaffold extends StatelessWidget {
  const HeaderScaffold({
    super.key,
    required this.title,
    required this.color,
    required this.body,
    this.subtitle,
    this.trailing,
    this.motif,
  });

  final String title;

  /// Uma linha miúda abaixo do título (contagem, por exemplo).
  final String? subtitle;

  final TileColor color;
  final TileMotif? motif;

  /// Ação à direita do título (ex.: "Esvaziar").
  final Widget? trailing;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(colors, color: color, motif: motif);
    final lightBackground = tile.background.computeLuminance() > 0.6;

    return Scaffold(
      backgroundColor: colors.paper,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: lightBackground ? SystemBars.onLight : SystemBars.onDark,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.lg),
              ),
              child: Container(
                width: double.infinity,
                color: tile.background,
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -30,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: TilePattern(
                          motif: tile.motif,
                          background: tile.background,
                          patternColor: tile.patternColor,
                          patternColorAlt: tile.patternColorAlt,
                        ),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screen,
                          AppSpacing.xs,
                          AppSpacing.screen,
                          AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            CircleIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Voltar',
                              background: color == TileColor.ink
                                  ? colors.inkSoft
                                  : colors.ink,
                              onTap: () => context.pop(),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.display(32)
                                        .copyWith(color: tile.onColor),
                                  ),
                                  if (subtitle != null)
                                    Text(
                                      subtitle!.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.texts.labelSmall
                                          ?.copyWith(color: tile.onColor),
                                    ),
                                ],
                              ),
                            ),
                            if (trailing != null) trailing!,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
