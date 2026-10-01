import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Controle de navegação por período (mês, dia): uma pílula só com `‹ Hoje ›`.
/// As setas andam um período; "Hoje" volta pro período atual — escuro e
/// firme quando você está em outro, apagado e sem toque quando já está no
/// atual (continua visível, pro controle não mudar de largura nem sumir).
class PeriodStepper extends StatelessWidget {
  const PeriodStepper({
    super.key,
    required this.atToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.previousTooltip,
    required this.nextTooltip,
  });

  /// O período mostrado já é o atual.
  final bool atToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: AppSpacing.minTapTarget,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Arrow(
              icon: Icons.chevron_left,
              tooltip: previousTooltip,
              onTap: onPrevious,
            ),
            Semantics(
              button: true,
              enabled: !atToday,
              label: 'Voltar para hoje',
              excludeSemantics: true,
              child: InkWell(
                key: const ValueKey('stepper-today'),
                onTap: atToday
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        onToday();
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: context.texts.labelLarge!.copyWith(
                        color: atToday
                            ? colors.textMuted.withValues(alpha: 0.6)
                            : colors.ink,
                        fontWeight: atToday ? FontWeight.w500 : FontWeight.w800,
                      ),
                      child: const Text('Hoje'),
                    ),
                  ),
                ),
              ),
            ),
            _Arrow(
              icon: Icons.chevron_right,
              tooltip: nextTooltip,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: AppSpacing.minTapTarget,
          height: AppSpacing.minTapTarget,
          child: Icon(icon, color: context.colors.ink),
        ),
      ),
    );
  }
}
