import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:receyta/features/mascot/painters/mascot_painter.dart';
import 'package:receyta/features/mascot/painters/mascot_pose.dart';
import 'package:receyta/theme/tokens.dart';

/// Desenhistas "limpos" dos mascotes para as imagens de marketing: tudo é
/// geometria desenhada à mão (polígonos de cantos arredondados, elipses,
/// tubos com contorno uniforme e luvas construídas dedo a dedo), sem nenhum
/// contorno vetorizado de imagem. Usam a referência só como guia de
/// proporção e cor. Não fazem parte do app.

const double cleanLine = 4.2;

Path roundedPolygon(List<Offset> pts, double radius, {List<double>? radii}) {
  final n = pts.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n];
    final v1 = p0 - p1, v2 = p2 - p1;
    final l1 = v1.distance, l2 = v2.distance;
    final r = math.min(radii?[i] ?? radius, math.min(l1, l2) / 2);
    final a = p1 + v1 / l1 * r;
    final b = p1 + v2 / l2 * r;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(p1.dx, p1.dy, b.dx, b.dy);
  }
  return path..close();
}

void drawShape(
  Canvas canvas,
  Path path,
  Color fill,
  Color ink, {
  double line = cleanLine,
}) {
  canvas.drawPath(path, Paint()..color = fill);
  canvas.drawPath(
    path,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = line
      ..strokeJoin = StrokeJoin.round,
  );
}

void drawTube(
  Canvas canvas,
  Path path, {
  required double width,
  required Color fill,
  required Color ink,
  double line = cleanLine,
  StrokeCap cap = StrokeCap.butt,
}) {
  canvas.drawPath(
    path,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 2 * line
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.drawPath(
    path,
    Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = cap
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Luva de desenho animado, de punho em (0,0) apontando para baixo (+y), com o
/// polegar do lado +x (mão esquerda; a direita é o espelho). [open] vai de 0
/// (relaxada, dedos juntos e curtos) a 1 (aberta, dedos em leque) e muda
/// continuamente o tamanho e a abertura dos dedos e do polegar. Os dedos são
/// cápsulas desenhadas primeiro como silhueta escura e depois como creme, o
/// que une tudo numa forma só, sem linhas no meio.
void drawGlove(
  Canvas canvas,
  AppColors colors, {
  required bool left,
  required double open,
  double line = cleanLine,
}) {
  final o = open.clamp(0.0, 1.0);
  final ink = colors.ink, cream = colors.onInk;
  canvas.save();
  if (!left) canvas.scale(-1, 1);

  final spread = lerpDouble(0.06, 0.30, o)!;
  final lengthK = lerpDouble(0.42, 1.0, o)!;
  final spacing = lerpDouble(9.2, 11.6, o)!;
  const lengths = [22.0, 27.0, 29.0, 27.0];
  const fingerWidth = 13.0;
  final fingers = <(Offset, Offset)>[];
  for (var i = 0; i < 4; i++) {
    final phi = (i - 1.5) * spread;
    final base = Offset((i - 1.5) * spacing, 38);
    final dir = Offset(math.sin(phi), math.cos(phi));
    fingers.add((base, base + dir * (lengths[i] * lengthK)));
  }
  final thumbLean = lerpDouble(0.32, 1.15, o)!;
  const thumbBase = Offset(17, 27);
  final thumbTip = thumbBase +
      Offset(math.sin(thumbLean), math.cos(thumbLean)) *
          lerpDouble(14, 22, o)!;
  final palm = Rect.fromCenter(
    center: const Offset(0, 26),
    width: 41,
    height: 36,
  );

  final inkStroke = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (final (a, b) in fingers) {
    canvas.drawLine(a, b, inkStroke..strokeWidth = fingerWidth + 2 * line);
  }
  canvas.drawLine(thumbBase, thumbTip, inkStroke..strokeWidth = 13 + 2 * line);
  canvas.drawOval(palm.inflate(line), Paint()..color = ink);

  final creamStroke = Paint()
    ..color = cream
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  for (final (a, b) in fingers) {
    canvas.drawLine(a, b, creamStroke..strokeWidth = fingerWidth);
  }
  canvas.drawLine(thumbBase, thumbTip, creamStroke..strokeWidth = 13);
  canvas.drawOval(palm, Paint()..color = cream);

  final crease = Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeWidth = line * 0.6;
  for (var i = 0; i < 3; i++) {
    final phi = (i - 1) * spread;
    final base = Offset((i - 1) * spacing, 40);
    final len = lerpDouble(8, 22, o)!;
    canvas.drawLine(
      base,
      base + Offset(math.sin(phi), math.cos(phi)) * len,
      crease,
    );
  }

  final cuff = RRect.fromRectAndRadius(
    const Rect.fromLTRB(-18, -6, 18, 10),
    const Radius.circular(6),
  );
  canvas.drawRRect(cuff, Paint()..color = cream);
  canvas.drawRRect(
    cuff,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = line * 0.9
      ..strokeJoin = StrokeJoin.round,
  );
  canvas.restore();
}

void drawEyes(
  Canvas canvas,
  AppColors colors,
  MascotPose pose, {
  required Offset left,
  required Offset right,
  required double outer,
  required double inner,
  required double pupil,
  required double lookX,
  required double lookY,
  required Color white,
  required Color lid,
  required double lidReach,
}) {
  for (final (center, side) in [(left, -1), (right, 1)]) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, 1 - pose.blink * 0.9);
    canvas.drawCircle(Offset.zero, outer, Paint()..color = colors.ink);
    final eye = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: inner));
    canvas.drawPath(eye, Paint()..color = white);
    canvas.save();
    canvas.clipPath(eye);
    final p = Offset(pose.look.dx * lookX, pose.look.dy * lookY);
    canvas.drawCircle(p, pupil, Paint()..color = colors.ink);
    canvas.drawCircle(
      p + Offset(-pupil * 0.62, -pupil * 0.12),
      pupil * 0.32,
      Paint()..color = colors.onSaturated,
    );
    if (pose.sad > 0.02) {
      final sad = pose.sad;
      final out = side * lidReach, inn = -side * lidReach;
      final shape = Path()
        ..moveTo(out, -lidReach * 1.5)
        ..lineTo(inn, -lidReach * 1.5)
        ..lineTo(inn, -inner * 0.9 + inner * 0.15 * sad)
        ..lineTo(out, -inner * 0.9 + inner * 0.85 * sad)
        ..close();
      canvas.drawPath(shape, Paint()..color = lid);
      canvas.drawLine(
        Offset(out, -inner * 0.9 + inner * 0.85 * sad),
        Offset(inn, -inner * 0.9 + inner * 0.15 * sad),
        Paint()
          ..color = colors.ink
          ..strokeWidth = 3.4,
      );
    }
    canvas.restore();
    canvas.restore();
  }
}

class CleanClochePainter extends MascotPainter {
  CleanClochePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 216;
  static const double _artWidth = 352;
  static const _scale = MascotPainter.designWidth / _artWidth;
  static const _mirror = 352.0;

  static const _shoulder = Offset(46, 176);
  static const _wrist = Offset(35, 277);
  static const _handLean = 0.37;
  static const _hipLeft = Offset(146, 246);
  static const _knobPivot = Offset(176, 52);

  static final Path _arm = Path()
    ..moveTo(44, 170)
    ..cubicTo(30, 184, 27, 216, 27.4, 246)
    ..cubicTo(27.8, 258, 31.5, 268, 35, 277);

  Color get _coral => colors.coral;
  Color get _coralDark => Color.lerp(colors.coral, colors.ink, 0.22)!;

  @override
  double get groundY => 207;

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    canvas.scale(_scale);
    _paintArm(canvas, pose, left: true);
    _paintArm(canvas, pose, left: false);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(136, 236, 216, 256),
        const Radius.circular(4),
      ),
      Paint()..color = colors.ink,
    );
    _paintLeg(canvas, pose, left: true);
    _paintLeg(canvas, pose, left: false);
    _paintKnob(canvas, pose);
    _paintDome(canvas);
    _paintBand(canvas);
    _paintFace(canvas, pose);
  }

  void _mirrored(Canvas canvas, bool left, void Function() draw) {
    canvas.save();
    if (!left) {
      canvas.translate(_mirror, 0);
      canvas.scale(-1, 1);
    }
    draw();
    canvas.restore();
  }

  void _paintArm(Canvas canvas, MascotPose pose, {required bool left}) {
    final angle = left ? pose.armLeft : -pose.armRight;
    final pivot = left ? _shoulder : Offset(_mirror - _shoulder.dx, _shoulder.dy);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _mirrored(canvas, left, () {
      drawTube(
        canvas,
        _arm,
        width: 21,
        fill: colors.onInk,
        ink: colors.ink,
        line: 3.2,
      );
    });
    final wrist =
        left ? _wrist : Offset(_mirror - _wrist.dx, _wrist.dy);
    final wristAngle = left ? pose.wristLeft : -pose.wristRight;
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(wristAngle + (left ? -_handLean : _handLean));
    drawGlove(
      canvas,
      colors,
      left: left,
      open: left ? pose.handLeft : pose.handRight,
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintLeg(Canvas canvas, MascotPose pose, {required bool left}) {
    final angle = left ? pose.legLeft : -pose.legRight;
    final hip = left ? _hipLeft : Offset(_mirror - _hipLeft.dx, _hipLeft.dy);
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(angle);
    canvas.translate(-hip.dx, -hip.dy);
    _mirrored(canvas, left, () {
      final leg = Path()
        ..moveTo(150, 250)
        ..lineTo(135, 330);
      drawTube(
        canvas,
        leg,
        width: 22,
        fill: _coral,
        ink: colors.ink,
      );
      final shoe = roundedPolygon(
        const [
          Offset(152, 361),
          Offset(152, 334),
          Offset(126, 324),
          Offset(94, 338),
          Offset(90, 356),
          Offset(112, 362),
        ],
        10,
        radii: const [6, 8, 28, 18, 14, 8],
      );
      drawShape(canvas, shoe, _coralDark, colors.ink);
      final shine = Path()
        ..moveTo(104, 342)
        ..quadraticBezierTo(112, 336, 122, 335);
      canvas.drawPath(
        shine,
        Paint()
          ..color = colors.coralLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );
    });
    canvas.restore();
  }

  void _paintKnob(Canvas canvas, MascotPose pose) {
    canvas.save();
    if (pose.lid > 0) {
      canvas.translate(_knobPivot.dx, _knobPivot.dy);
      canvas.rotate(pose.lid * 0.25);
      canvas.translate(-_knobPivot.dx, -_knobPivot.dy - pose.lid * 12);
    }
    final knob = Path()
      ..addOval(Rect.fromCircle(center: const Offset(176, 34), radius: 19));
    drawShape(canvas, knob, _coralDark, colors.ink);
    canvas.drawCircle(
      const Offset(170, 28),
      4.2,
      Paint()..color = colors.onSaturated.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  Path get _dome => Path()
    ..moveTo(32, 212)
    ..cubicTo(32, 118, 92, 52, 176, 52)
    ..cubicTo(260, 52, 320, 118, 320, 212)
    ..close();

  void _paintDome(Canvas canvas) {
    final dome = _dome;
    canvas.drawPath(dome, Paint()..color = _coral);
    canvas.save();
    canvas.clipPath(dome);
    final shade = Path()
      ..moveTo(214, 40)
      ..cubicTo(262, 84, 289, 148, 289, 215)
      ..lineTo(340, 215)
      ..lineTo(340, 40)
      ..close();
    canvas.drawPath(shade, Paint()..color = _coralDark);
    canvas.restore();
    canvas.drawPath(
      dome,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = cleanLine
        ..strokeJoin = StrokeJoin.round,
    );
    final streak = Path()
      ..moveTo(53, 182)
      ..cubicTo(58, 136, 86, 98, 128, 74);
    canvas.drawPath(
      streak,
      Paint()
        ..color = colors.coralLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintBand(Canvas canvas) {
    final band = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(14, 210, 338, 244),
          const Radius.circular(17),
        ),
      );
    drawShape(canvas, band, _coralDark, colors.ink);
  }

  void _paintFace(Canvas canvas, MascotPose pose) {
    drawEyes(
      canvas,
      colors,
      pose,
      left: const Offset(142.5, 132),
      right: const Offset(209.5, 132),
      outer: 27,
      inner: 23.6,
      pupil: 17,
      lookX: 8,
      lookY: 7,
      white: colors.onInk,
      lid: _coral,
      lidReach: 30,
    );
    final line = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    if (pose.sad >= 0.3) {
      canvas.drawPath(
        Path()
          ..moveTo(150, 187)
          ..quadraticBezierTo(176, 166, 202, 187),
        line,
      );
    } else if (pose.mouth >= 0.2) {
      paintMouth(canvas, const Offset(176, 177), 58, pose);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(149, 175)
          ..quadraticBezierTo(176, 197, 203, 177),
        line,
      );
    }
  }
}
