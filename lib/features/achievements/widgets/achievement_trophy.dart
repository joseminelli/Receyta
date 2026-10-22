import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Troféu desenhado à mão, na cor [color] com degradê de luz e sombra, uma
/// estrela na taça e um brilho na lateral. Entra com um estouro elástico.
class AchievementTrophy extends StatelessWidget {
  const AchievementTrophy({
    super.key,
    required this.color,
    required this.starColor,
    this.size = 132,
  });

  final Color color;

  /// Cor da estrela gravada na taça (escura, pra contrastar com [color]).
  final Color starColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
      child: CustomPaint(
        size: Size.square(size),
        painter: _TrophyPainter(color: color, starColor: starColor),
      ),
    );
  }
}

class _TrophyPainter extends CustomPainter {
  const _TrophyPainter({required this.color, required this.starColor});

  final Color color;
  final Color starColor;

  Color _shade(double delta) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + delta).clamp(0.0, 1.0)).toColor();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final light = _shade(0.18);
    final dark = _shade(-0.2);

    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = dark;
    canvas.drawPath(
      Path()
        ..moveTo(28, 22)
        ..lineTo(19, 22)
        ..cubicTo(13, 22, 13, 42, 29, 46),
      handle,
    );
    canvas.drawPath(
      Path()
        ..moveTo(72, 22)
        ..lineTo(81, 22)
        ..cubicTo(87, 22, 87, 42, 71, 46),
      handle,
    );

    final metal = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, color, dark],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100));

    canvas.drawRect(const Rect.fromLTWH(44, 70, 12, 16), metal);
    canvas.drawRRect(
      RRect.fromLTRBR(28, 85, 72, 94, const Radius.circular(3)),
      metal,
    );
    canvas.drawPath(
      Path()
        ..moveTo(26, 12)
        ..lineTo(74, 12)
        ..lineTo(74, 40)
        ..cubicTo(74, 60, 63, 72, 50, 72)
        ..cubicTo(37, 72, 26, 60, 26, 40)
        ..close(),
      metal,
    );

    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 12.0 : 5.4;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(50 + r * math.cos(a), 38 + r * math.sin(a));
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = starColor);

    canvas.drawPath(
      Path()
        ..moveTo(33, 18)
        ..lineTo(33, 40)
        ..cubicTo(33, 51, 38, 60, 44, 65),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(_TrophyPainter old) =>
      old.color != color || old.starColor != starColor;
}
