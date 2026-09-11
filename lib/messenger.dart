import 'package:flutter/material.dart';

import 'package:receyta/widgets/app_snackbar.dart';

/// `NavigatorState` da raiz do app (ligada ao `GoRouter` em `router.dart`).
/// Existe pra achar o `Overlay` raiz de qualquer lugar — callback de
/// drag-and-drop, `Result.when` — sem depender de um `BuildContext` local
/// que pode já ter saído da árvore (ex.: RF-01.6, "Desfazer" após o `pop`
/// que fecha a tela de detalhe).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Atalho pro [AppSnackBar] a partir de qualquer callback sem `BuildContext`
/// à mão.
void showAppSnackBar({
  required String message,
  AppSnackBarVariant variant = AppSnackBarVariant.success,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return;
  AppSnackBar.show(
    context,
    message: message,
    variant: variant,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}
