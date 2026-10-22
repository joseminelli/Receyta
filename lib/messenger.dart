import 'package:flutter/material.dart';

import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/app_toast.dart';

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

/// Abre um toast em loading; use o handle pra virar sucesso/erro no lugar.
AppToastHandle? showAppLoading(String title) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return null;
  return AppToast.loading(context, title);
}

/// Loading que resolve sozinho em sucesso/erro conforme o [future].
Future<T> appToastPromise<T>(
  Future<T> future, {
  required String loading,
  required String Function(T value) success,
  required String Function(Object error) error,
}) {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return future;
  return AppToast.promise(
    context,
    future,
    loading: loading,
    success: success,
    error: error,
  );
}
