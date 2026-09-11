import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Diálogo padrão do app: cantos bem arredondados (§9.8), medalhão de ícone
/// no topo (mesma linguagem do `AppSnackBar`/`StateBadge`/`PillNavBar`) e
/// ações em `PillButton` — em vez do `AlertDialog` cru do Material, que não
/// carrega nenhum traço do design system.
abstract class AppDialog {
  /// Diálogo genérico: ícone + título + corpo (texto ou widget livre, como um
  /// `TextField`) + ações.
  static Future<T?> show<T>(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    String? message,
    Widget? content,
    required List<Widget> actions,
  }) {
    final colors = context.colors;
    final iconForeground =
        accent.computeLuminance() > 0.5 ? colors.ink : colors.onSaturated;

    return showDialog<T>(
      context: context,
      builder: (dialog) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          0,
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StateBadge(
              icon: icon,
              background: accent,
              foreground: iconForeground,
              size: 56,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: context.texts.displaySmall),
          ],
        ),
        content: content ??
            (message == null
                ? null
                : Text(message, style: context.texts.bodyMedium)),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: actions,
      ),
    );
  }

  /// Atalho pra confirmação sim/não com uma ação destrutiva — o caso mais
  /// comum (apagar, excluir, esvaziar).
  static Future<bool> confirm(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String message,
    String cancelLabel = 'Cancelar',
    required String confirmLabel,
  }) async {
    final ok = await show<bool>(
      context,
      icon: icon,
      accent: accent,
      title: title,
      message: message,
      actions: [
        PillButton(
          label: cancelLabel,
          variant: PillButtonVariant.ghost,
          dense: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        PillButton(
          label: confirmLabel,
          variant: PillButtonVariant.danger,
          dense: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return ok ?? false;
  }
}
