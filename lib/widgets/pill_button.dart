import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Papel visual do botão. Define o par fundo/texto — nunca combine cores à mão,
/// porque as regras de pareamento da §9.2 não são simétricas.
enum PillButtonVariant {
  /// Fundo `ink`, texto `lime`. Ação primária sobre superfície clara.
  ///
  /// É a única forma de usar lime sobre `paper`: como texto dentro de um bloco
  /// escuro. Lime direto sobre paper reprova em contraste (§9.2).
  primary,

  /// Fundo `lime`, texto `ink`. Ação primária sobre superfície escura ou
  /// saturada — na tela de Compras, no hero de receita.
  accent,

  /// Fundo `paperSoft`, texto `ink`. Ação secundária sobre `paper`.
  secondary,

  /// Sem fundo, texto `ink`. Ação terciária.
  ghost,

  /// Fundo `danger`, texto branco. Ação destrutiva (apagar, esvaziar) —
  /// mesmo par do `StateBadge`/`CircleIconButton` quando marcados de perigo.
  danger,
}

/// Botão em pílula total (raio 99, §9.8).
///
/// Sem borda, sem sombra, sem gradiente — a separação vem do bloco de cor.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.dense = false,
  });

  final String label;

  /// Nulo desabilita o botão.
  final VoidCallback? onPressed;

  final PillButtonVariant variant;
  final IconData? icon;

  /// Reduz o padding horizontal. A altura mínima de toque é preservada.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    final (background, foreground) = switch (variant) {
      PillButtonVariant.primary => (colors.ink, colors.lime),
      PillButtonVariant.accent => (colors.lime, colors.ink),
      PillButtonVariant.secondary => (colors.paperSoft, colors.ink),
      PillButtonVariant.ghost => (Colors.transparent, colors.ink),
      PillButtonVariant.danger => (colors.danger, colors.onSaturated),
    };

    // Desabilitado perde saturação sem virar cinza: mistura com a superfície.
    final effectiveBackground =
        enabled ? background : Color.alphaBlend(background.withValues(alpha: 0.35), colors.paper);
    final effectiveForeground = enabled ? foreground : colors.textMuted;

    return Material(
      color: effectiveBackground,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTapTarget,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: effectiveForeground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: context.texts.labelLarge?.copyWith(
                    color: effectiveForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
