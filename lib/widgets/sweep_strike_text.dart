import 'package:flutter/material.dart';

/// Texto com risco animado: em vez do `TextDecoration.lineThrough`
/// instantâneo, uma linha varre da esquerda pra direita ao marcar feito (e
/// recolhe do mesmo jeito ao desmarcar) — `TextStyle.lerp` não anima
/// decoration suavemente (é um salto), então o traço é desenhado à parte,
/// por cima do texto, com a largura controlada por um `TweenAnimationBuilder`.
/// Usado no passo do modo cozinha e no item da lista de compras.
class SweepStrikeText extends StatelessWidget {
  const SweepStrikeText({
    super.key,
    required this.text,
    required this.done,
    required this.style,
    required this.lineColor,
  });

  final String text;
  final bool done;
  final TextStyle? style;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: style ?? const TextStyle(),
          child: Text(text),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: done ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            if (t == 0) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: t,
                child: Container(height: 2, color: lineColor),
              ),
            );
          },
        ),
      ],
    );
  }
}
