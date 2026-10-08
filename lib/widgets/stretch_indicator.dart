import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// O retângulo do indicador no instante [t] (0 a 1) de uma troca de [from]
/// para [to], com o efeito de "esticar e voltar": a borda da frente sai
/// primeiro e a de trás só começa depois — o indicador se alonga até cobrir as
/// duas opções e então se recolhe no destino. Indo pra direita a frente é a
/// borda direita; indo pra esquerda, a esquerda.
Rect stretchRect(Rect from, Rect to, double t) {
  final forward = to.center.dx >= from.center.dx;
  final lead = const Interval(0, 0.62, curve: Curves.easeOutCubic).transform(t);
  final trail =
      const Interval(0.28, 1, curve: Curves.easeInOutCubic).transform(t);
  final move = Curves.easeOutCubic.transform(t);
  return Rect.fromLTRB(
    lerpDouble(from.left, to.left, forward ? trail : lead)!,
    lerpDouble(from.top, to.top, move)!,
    lerpDouble(from.right, to.right, forward ? lead : trail)!,
    lerpDouble(from.bottom, to.bottom, move)!,
  );
}

/// Duração padrão da troca com o efeito de esticar.
const kStretchDuration = Duration(milliseconds: 400);

/// Indicador que desliza entre [count] opções lado a lado, esticando no meio
/// do caminho (ver [stretchRect]). Quem usa diz onde fica a opção [index] em
/// [slotRect] (dado o tamanho disponível) e o que desenhar em [child]; o
/// indicador ocupa todo o espaço do pai.
class StretchIndicator extends StatefulWidget {
  const StretchIndicator({
    super.key,
    required this.index,
    required this.slotRect,
    required this.child,
    this.duration = kStretchDuration,
  });

  final int index;
  final Rect Function(int index, Size size) slotRect;
  final Widget child;
  final Duration duration;

  @override
  State<StretchIndicator> createState() => _StretchIndicatorState();
}

class _StretchIndicatorState extends State<StretchIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);

  Size _size = Size.zero;
  Rect? _from;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _rectNow(int index) {
    final to = widget.slotRect(index, _size);
    final from = _from;
    if (from == null || !_controller.isAnimating && _controller.value >= 1) {
      return to;
    }
    return stretchRect(from, to, _controller.value);
  }

  @override
  void didUpdateWidget(covariant StretchIndicator old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && _size != Size.zero) {
      // Parte de onde o indicador está agora (a troca pode ter interrompido
      // outra no meio), não de onde a opção antiga fica.
      _from = _rectNow(old.index);
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: _rectNow(widget.index),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}
