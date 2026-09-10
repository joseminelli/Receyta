import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';

/// Métrica de receita: valor em Bricolage 800 sobre um label caps.
///
/// Usada em fila no detalhe da receita — preparo, fogão, porções. O contraste
/// entre o valor grande e o label de 10px é o mesmo salto de escala do resto
/// da linguagem, em miniatura (§9.1).
class MetricStat extends StatelessWidget {
  const MetricStat({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.color,
    this.labelColor,
    this.valueSize = 20,
  });

  final String value;

  /// Sufixo curto ao lado do valor ("m", "g"), renderizado bem menor — um
  /// índice, não parte do número.
  final String? unit;

  /// Renderizado em maiúsculas.
  final String label;

  /// Padrão: `ink`. Sobre bloco saturado, passe branco.
  final Color? color;

  /// Padrão: `textMuted`. Sobre `coral` ou `violet`, use a versão clara do
  /// próprio matiz — nunca cinza (§9.2).
  final Color? labelColor;

  /// Tamanho do valor. Detalhe da receita usa grande (§9.1, salto de escala).
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unit = this.unit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: value,
            children: unit == null
                ? null
                : [
                    TextSpan(
                      text: unit,
                      style: TextStyle(fontSize: valueSize * 0.4),
                    ),
                  ],
          ),
          style: AppTextStyles.display(valueSize).copyWith(
            color: color ?? colors.ink,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs / 2),
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: labelColor ?? colors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
