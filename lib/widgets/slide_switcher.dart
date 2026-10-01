import 'package:flutter/material.dart';

/// Troca de conteúdo com deslize horizontal: avançar ([index] maior) empurra o
/// atual pra esquerda e entra o novo pela direita; voltar faz o contrário. Usado
/// no mês e no dia do planejamento — o gesto de passar de página, em vez de um
/// fade parado.
///
/// [index] é uma ordem estável do conteúdo (mês = ano*12+mês, dia = dias desde
/// uma data fixa). Mudou, troca; igual, só reconstrói o filho. Os dois filhos
/// (o que sai e o que entra) ficam vivos durante o deslize.
class SlideSwitcher extends StatefulWidget {
  const SlideSwitcher({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final Widget child;
  final Duration duration;

  @override
  State<SlideSwitcher> createState() => _SlideSwitcherState();
}

class _SlideSwitcherState extends State<SlideSwitcher> {
  bool _forward = true;

  @override
  void didUpdateWidget(covariant SlideSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.index != old.index) _forward = widget.index > old.index;
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = ValueKey<int>(widget.index);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: widget.duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == currentKey;
          final from = incoming
              ? Offset(_forward ? 1 : -1, 0)
              : Offset(_forward ? -1 : 1, 0);
          return SlideTransition(
            position: Tween<Offset>(begin: from, end: Offset.zero)
                .animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(key: currentKey, child: widget.child),
      ),
    );
  }
}
