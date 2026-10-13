import 'package:flutter/material.dart';

import 'mascot_painter.dart';
import 'mascot_pose.dart';

/// Mascote Pote: vidro com conteúdo violeta, rótulo lime curvo e tampa em
/// cilindro. Caixa de projeto 200×360.
class PotePainter extends MascotPainter {
  PotePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 360;

  @override
  double get groundY => 340;

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    _paintLegs(canvas);
    paintArm(canvas, -1, pose.armLeft, const Offset(44, 176));
    paintArm(canvas, 1, pose.armRight, const Offset(156, 176));
    shape(canvas, _glassPath, colors.onInk);
    _paintContent(canvas);
    _paintLabel(canvas, pose);
    _paintGlassShine(canvas);
    _paintLid(canvas);
  }

  void _paintLegs(Canvas canvas) {
    for (final x in const [72.0, 110.0]) {
      rrect(
        canvas,
        Rect.fromLTWH(x, 262, 18, 64),
        8,
        colors.onInk,
        shaded: true,
      );
    }
    rrect(
      canvas,
      const Rect.fromLTWH(60, 322, 36, 18),
      9,
      colors.onInk,
      shaded: true,
    );
    rrect(
      canvas,
      const Rect.fromLTWH(104, 322, 36, 18),
      9,
      colors.onInk,
      shaded: true,
    );
  }

  Path get _glassPath {
    final neck = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(56, 58, 144, 90),
          const Radius.circular(8),
        ),
      );
    final body = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(42, 76, 158, 272),
          const Radius.circular(24),
        ),
      );
    return Path.combine(PathOperation.union, neck, body);
  }

  void _paintContent(Canvas canvas) {
    const area = Rect.fromLTRB(47, 92, 153, 267);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(area, const Radius.circular(19)),
    );
    canvas.drawRect(area, fill(colors.violet));
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 6; col++) {
        final offset = row.isOdd ? 12.0 : 0.0;
        canvas.drawCircle(
          Offset(47 + col * 24.0 + offset, 222 + row * 22.0),
          10,
          fill(colors.violetPattern),
        );
      }
    }
    final top = Path()
      ..moveTo(47, 106)
      ..lineTo(153, 92)
      ..lineTo(153, 128)
      ..lineTo(47, 128)
      ..close();
    canvas.drawPath(top, fill(colors.violetDeep));
    final dots = fill(colors.ink.withValues(alpha: 0.55));
    for (final p in const [
      Offset(70, 108),
      Offset(82, 104),
      Offset(96, 106),
      Offset(110, 100),
      Offset(124, 102),
      Offset(138, 98),
      Offset(90, 113),
      Offset(118, 111),
    ]) {
      canvas.drawCircle(p, 1.6, dots);
    }
    canvas.drawRect(area, shade(area));
    canvas.restore();
  }

  Path get _labelPath => Path()
    ..moveTo(38, 120)
    ..quadraticBezierTo(100, 130, 162, 120)
    ..lineTo(162, 208)
    ..quadraticBezierTo(100, 220, 38, 208)
    ..close();

  void _paintLabel(Canvas canvas, MascotPose pose) {
    shape(canvas, _labelPath, colors.lime, shaded: true);
    final freckles = fill(colors.ink.withValues(alpha: 0.45));
    for (final p in const [
      Offset(56, 178),
      Offset(61, 184),
      Offset(66, 177),
      Offset(134, 177),
      Offset(139, 184),
      Offset(144, 178),
    ]) {
      canvas.drawCircle(p, 1.4, freckles);
    }
    paintEye(canvas, const Offset(82, 158), pose, 15);
    paintEye(canvas, const Offset(118, 158), pose, 15);
    paintMouth(canvas, const Offset(100, 184), 24, pose);
  }

  void _paintGlassShine(Canvas canvas) {
    final shine = fill(colors.onSaturated.withValues(alpha: 0.5));
    for (final r in const [
      Rect.fromLTRB(52, 98, 58, 114),
      Rect.fromLTRB(52, 218, 58, 256),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        shine,
      );
    }
  }

  void _paintLid(Canvas canvas) {
    final body = Path()
      ..moveTo(54, 22)
      ..lineTo(54, 56)
      ..quadraticBezierTo(100, 72, 146, 56)
      ..lineTo(146, 22)
      ..close();
    shape(canvas, body, colors.violetDeep, shaded: true);
    final groove = Paint()
      ..color = colors.ink.withValues(alpha: 0.25)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 66.0; x <= 134; x += 12) {
      final t = (x - 54) / 92;
      canvas.drawLine(Offset(x, 28), Offset(x, 56 + 32 * t * (1 - t)), groove);
    }
    final top = Path()..addOval(const Rect.fromLTRB(54, 8, 146, 36));
    shape(canvas, top, colors.violet);
    canvas.drawOval(
      const Rect.fromLTRB(63, 13, 137, 31),
      Paint()
        ..color = colors.onSaturated.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
