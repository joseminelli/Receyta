import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/typography.dart';

/// "R$" pequeno e o valor em display: o número é o que se lê.
class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.cents,
    required this.size,
    required this.color,
    this.showSymbol = true,
  });

  final int cents;
  final double size;
  final Color color;
  final bool showSymbol;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(cents).replaceFirst('R\$ ', '');
    return Text.rich(
      TextSpan(
        children: [
          if (showSymbol)
            TextSpan(
              text: 'R\$ ',
              style: context.texts.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          TextSpan(
            text: amount,
            style: AppTextStyles.display(size).copyWith(color: color),
          ),
        ],
      ),
      maxLines: 1,
    );
  }
}
