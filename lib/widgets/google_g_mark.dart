import 'dart:math' as math;

import 'package:flutter/material.dart';

/// O "G" do Google nas quatro cores da marca, desenhado em código (sem asset
/// nem dependência): anel dividido em vermelho (topo), amarelo (esquerda),
/// verde (embaixo) e azul (direita, com a barra do meio).
class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      child: CustomPaint(size: Size.square(size), painter: const _GPainter()),
    );
  }
}

const _blue = Color(0xFF4285F4);
const _red = Color(0xFFEA4335);
const _yellow = Color(0xFFFBBC05);
const _green = Color(0xFF34A853);

class _GPainter extends CustomPainter {
  const _GPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final radius = (size.width - stroke) / 2;
    final center = size.center(Offset.zero);
    final ring = Rect.fromCircle(center: center, radius: radius);

    double rad(double deg) => deg * math.pi / 180;

    void arc(Color color, double fromDeg, double toDeg) {
      canvas.drawArc(
        ring,
        rad(fromDeg),
        rad(toDeg - fromDeg),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..isAntiAlias = true,
      );
    }

    arc(_red, -135, -45);
    arc(_yellow, 135, 225);
    arc(_green, 45, 135);
    arc(_blue, 0, 45);

    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()
        ..color = _blue
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
