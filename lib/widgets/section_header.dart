import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Cabeçalho de seção: label caps opcional acima, título em Display S,
/// ação opcional à direita.
///
/// O salto de escala entre o label de 10px e o título de 22px é o que carrega
/// a personalidade (§9.1) — por isso o label não é opcional por estética, e sim
/// por haver seções que realmente não têm o que dizer ali.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
  });

  final String title;

  /// Texto curto acima do título. Renderizado em maiúsculas — o Flutter não
  /// tem `text-transform`, então a conversão acontece aqui.
  final String? eyebrow;

  /// Normalmente um [PillButton] pequeno ou um `IconButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final eyebrow = this.eyebrow;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow.toUpperCase(), style: context.texts.labelSmall),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                title,
                style: context.texts.displaySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.sm),
          action!,
        ],
      ],
    );
  }
}
