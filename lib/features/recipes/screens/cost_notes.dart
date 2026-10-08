import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Nota discreta, com ícone, usada nas telas de custo.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// "O custo é uma estimativa" + "os preços ficam só neste aparelho": os dois
/// avisos que acompanham qualquer valor de custo.
class CostDisclaimer extends StatelessWidget {
  const CostDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Note(icon: Icons.info_outline, text: kCostDisclaimer),
        SizedBox(height: AppSpacing.xs),
        _Note(icon: Icons.cloud_off_outlined, text: kPriceLocalNotice),
      ],
    );
  }
}

/// Só o aviso de que o preço fica no aparelho — vai na folha onde se digita
/// o preço, que é quando a pessoa precisa saber.
class PriceLocalNote extends StatelessWidget {
  const PriceLocalNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Note(
      icon: Icons.cloud_off_outlined,
      text: kPriceLocalNotice,
    );
  }
}
