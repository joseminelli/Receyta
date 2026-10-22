import 'package:flutter/material.dart';

import 'package:receyta/widgets/app_toast.dart';

/// Papel visual do snackbar: success vira toast `lime`, error vira `danger`.
enum AppSnackBarVariant { success, error }

/// Fachada antiga: delega pro [AppToast] pra não tocar nos call sites. A
/// `message` é partida em título curto + descrição pra caber na pílula:
/// "Casa criada. Agora convide alguém." vira título "Casa criada" e corpo
/// "Agora convide alguém."; frase curta única vira só a pílula; frase longa
/// ganha um título padrão e fica inteira no corpo. [title] explícito vence.
abstract class AppSnackBar {
  static const _maxTitle = 40;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarVariant variant = AppSnackBarVariant.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final isError = variant == AppSnackBarVariant.error;
    final (resolvedTitle, description) = title != null
        ? (title, message)
        : _split(message, isError ? 'Algo deu errado' : 'Tudo certo');
    AppToast.show(
      context,
      title: resolvedTitle,
      description: description ?? _undoHint(actionLabel),
      kind: isError ? AppToastKind.error : AppToastKind.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Toast com "Desfazer" e sem descrição ganha uma frase de apoio — é ela que
  /// abre o corpo e dá a animação líquida; outras ações ficam inline na pílula.
  static String? _undoHint(String? actionLabel) =>
      actionLabel?.toLowerCase() == 'desfazer'
          ? 'Foi sem querer? Você pode desfazer.'
          : null;

  static (String, String?) _split(String message, String fallbackTitle) {
    final text = message.trim();
    final trimmed =
        text.endsWith('.') ? text.substring(0, text.length - 1) : text;
    final cut = trimmed.indexOf('. ');
    if (cut > 0 && cut <= _maxTitle) {
      return (trimmed.substring(0, cut), trimmed.substring(cut + 2).trim());
    }
    if (cut < 0 && trimmed.length <= _maxTitle) return (trimmed, null);
    return (fallbackTitle, text);
  }
}
