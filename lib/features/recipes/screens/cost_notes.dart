import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/pill_button.dart';

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
      mainAxisSize: MainAxisSize.min,
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

/// "Estimativa · como é calculado": link compacto que abre as duas notas num
/// diálogo. Fica nas telas de custo no lugar das notas por extenso.
class HowItWorksLink extends StatelessWidget {
  const HowItWorksLink({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: () => AppDialog.show<void>(
          context,
          icon: Icons.info_outline,
          accent: colors.ink,
          title: 'Como é calculado',
          content: const CostDisclaimer(),
          actions: [
            PillButton(
              label: 'Entendi',
              dense: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Estimativa · como é calculado',
                style: context.texts.labelMedium
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
