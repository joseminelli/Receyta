import 'package:flutter/material.dart';

/// Envolve a tela raiz para que o botão voltar do sistema nunca feche o app.
///
/// Só faz sentido na base da pilha: telas abertas com `context.push` não usam
/// isso, porque nelas o voltar deve desempilhar normalmente.
///
/// Precisa ficar dentro do `Navigator` do go_router — um `PopScope` acima do
/// `MaterialApp` não tem rota para se registrar e é ignorado.
class RootBackGuard extends StatelessWidget {
  const RootBackGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: child);
  }
}
