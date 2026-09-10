import 'package:flutter/material.dart';

/// `ScaffoldMessengerState` da raiz do app. Existe para o snackbar de "Desfazer"
/// da exclusão (RF-01.6) sobreviver ao `pop` que fecha a tela de detalhe.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Snackbar na raiz — não some quando a rota atual sai da árvore.
void showRootSnackBar(SnackBar snackBar) {
  rootMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
