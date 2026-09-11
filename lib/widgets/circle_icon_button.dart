import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Botão circular preenchido — ação secundária numa linha de lista ou bloco.
/// Mesmo desenho do botão de voltar/editar sobre o hero de receita, só que
/// reaproveitável fora dali (§9.8).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  /// Default `ink` — passe `colors.danger` pra ações destrutivas.
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: background ?? colors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, size: 20, color: foreground ?? colors.onSaturated),
          ),
        ),
      ),
    );
  }
}
