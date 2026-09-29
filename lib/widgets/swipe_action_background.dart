import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Fundo revelado ao deslizar uma linha/cartão: superfície neutra, só o ícone
/// e o rótulo levam a cor da ação (fundo nunca tingido). [alignment] diz de
/// que lado ele aparece — esquerda (deslizando pra direita) ou direita.
class SwipeActionBackground extends StatelessWidget {
  const SwipeActionBackground({
    super.key,
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
    this.borderRadius = BorderRadius.zero,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final leading = alignment == Alignment.centerLeft;
    final children = [
      Icon(icon, color: color),
      const SizedBox(width: AppSpacing.xs),
      Text(label, style: context.texts.labelLarge?.copyWith(color: color)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: context.colors.inkSoft,
        borderRadius: borderRadius,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: leading ? children : children.reversed.toList(),
      ),
    );
  }
}
