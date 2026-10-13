import 'package:flutter/material.dart';

import 'mascot_painter.dart';
import 'mascot_pose.dart';

/// Mascote Cloche: cúpula larga e brilhante com botão, faixa pespontada na
/// borda, bochechas, sobrancelhas expressivas e pernas curtas. Caixa de
/// projeto 200×268.
class ClochePainter extends MascotPainter {
  ClochePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 268;

  @override
  double get groundY => 252;

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    _paintLegs(canvas);
    paintArm(canvas, -1, pose.armLeft, const Offset(24, 160), reach: 0.85);
    paintArm(canvas, 1, pose.armRight, const Offset(176, 160), reach: 0.85);
    _paintKnob(canvas);
    _paintDome(canvas);
    _paintBand(canvas);
    _paintFace(canvas, pose);
  }

  void _paintLegs(Canvas canvas) {
    for (final x in const [76.0, 110.0]) {
      rrect(
        canvas,
        Rect.fromLTWH(x, 170, 14, 66),
        7,
        colors.coral,
        shaded: true,
      );
    }
    rrect(
      canvas,
      const Rect.fromLTWH(56, 228, 44, 24),
      12,
      colors.coralLight,
      shaded: true,
    );
    rrect(
      canvas,
      const Rect.fromLTWH(100, 228, 44, 24),
      12,
      colors.coralLight,
      shaded: true,
    );
  }

  void _paintKnob(Canvas canvas) {
    final knob = Path()
      ..addOval(Rect.fromCircle(center: const Offset(100, 46), radius: 12));
    shape(canvas, knob, colors.coral, shaded: true);
    canvas.drawCircle(
      const Offset(96, 42),
      3,
      fill(colors.onSaturated.withValues(alpha: 0.6)),
    );
  }

  void _paintDome(Canvas canvas) {
    final dome = Path()
      ..moveTo(20, 160)
      ..cubicTo(20, 92, 56, 56, 100, 56)
      ..cubicTo(144, 56, 180, 92, 180, 160)
      ..close();
    canvas.drawPath(dome, fill(colors.coral));
    final bounds = dome.getBounds();
    canvas.save();
    canvas.clipPath(dome);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          colors: [
            colors.onSaturated.withValues(alpha: 0.35),
            colors.onSaturated.withValues(alpha: 0),
            colors.ink.withValues(alpha: 0.22),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(bounds),
    );
    canvas.restore();
    canvas.drawPath(dome, outline);
    final shineColor = colors.onSaturated.withValues(alpha: 0.5);
    final shine = Path()
      ..moveTo(36, 128)
      ..quadraticBezierTo(36, 88, 66, 70);
    canvas.drawPath(
      shine,
      Paint()
        ..color = shineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(const Offset(40, 144), 3.5, fill(shineColor));
  }

  void _paintBand(Canvas canvas) {
    rrect(
      canvas,
      const Rect.fromLTRB(8, 148, 192, 176),
      14,
      colors.coralLight,
      shaded: true,
    );
    final stitch = Paint()
      ..color = colors.ink.withValues(alpha: 0.35)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 26.0; x < 176; x += 14) {
      canvas.drawLine(Offset(x, 162), Offset(x + 6, 162), stitch);
    }
  }

  void _paintFace(Canvas canvas, MascotPose pose) {
    final cheek = fill(colors.coralMuted.withValues(alpha: 0.8));
    canvas.drawCircle(const Offset(58, 126), 8, cheek);
    canvas.drawCircle(const Offset(142, 126), 8, cheek);
    paintEye(canvas, const Offset(78, 106), pose, 16);
    paintEye(canvas, const Offset(122, 106), pose, 16);
    final lift = -pose.look.dy * 4;
    for (final cx in const [78.0, 122.0]) {
      final brow = Path()
        ..moveTo(cx - 10, 87 + lift)
        ..quadraticBezierTo(cx, 81 + lift, cx + 10, 87 + lift);
      canvas.drawPath(brow, outline);
    }
    paintMouth(canvas, const Offset(100, 132), 30, pose);
  }
}
