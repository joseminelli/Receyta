import 'package:flutter/material.dart';
import 'package:receyta/features/mascot/painters/mascot_painter.dart';
import 'package:receyta/features/mascot/painters/mascot_pose.dart';

import 'clean_mascots.dart';

/// O Pote (Tito) desenhado à mão, na mesma técnica do [CleanClochePainter].
/// Coordenadas em pixels da imagem de referência (317 de largura).
class CleanPotePainter extends MascotPainter {
  CleanPotePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 309;
  static const double _artWidth = 317;
  static const _scale = MascotPainter.designWidth / _artWidth;
  static const _armMirror = 300.5;
  static const _legMirror = 303.0;

  static const _shoulder = Offset(44, 272);
  static const _wrist = Offset(29.5, 357);
  static const _handLean = -0.13;
  static const _hipLeft = Offset(127, 358);
  static const _lidPivot = Offset(151, 98);

  static final Path _arm = Path()
    ..moveTo(44, 272)
    ..cubicTo(40, 300, 33, 330, 29.5, 357);

  Color get _lime => colors.limePattern;
  Color get _limeDark => Color.lerp(colors.limePattern, colors.ink, 0.2)!;

  @override
  double get groundY => 288;

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    canvas.scale(_scale);
    canvas.translate(6.5, 0);
    _paintArm(canvas, pose, left: true);
    _paintArm(canvas, pose, left: false);
    _paintLeg(canvas, pose, left: true);
    _paintLeg(canvas, pose, left: false);
    _paintGlass(canvas);
    _paintContent(canvas);
    _paintLabel(canvas);
    _paintFace(canvas, pose);
    _paintLid(canvas, pose);
  }

  void _mirrored(Canvas canvas, double axis, bool left, void Function() draw) {
    canvas.save();
    if (!left) {
      canvas.translate(axis, 0);
      canvas.scale(-1, 1);
    }
    draw();
    canvas.restore();
  }

  void _paintArm(Canvas canvas, MascotPose pose, {required bool left}) {
    final angle = left ? pose.armLeft : -pose.armRight;
    final pivot =
        left ? _shoulder : Offset(_armMirror - _shoulder.dx, _shoulder.dy);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _mirrored(canvas, _armMirror, left, () {
      drawTube(
        canvas,
        _arm,
        width: 19,
        fill: colors.onInk,
        ink: colors.ink,
        line: 3.8,
      );
      drawShape(
        canvas,
        roundedPolygon(
          const [
            Offset(30, 261),
            Offset(60, 267),
            Offset(51, 298),
            Offset(23, 290),
          ],
          7,
        ),
        colors.ink,
        colors.ink,
        line: 1,
      );
    });
    final wrist = left ? _wrist : Offset(_armMirror - _wrist.dx, _wrist.dy);
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(
      (left ? pose.wristLeft : -pose.wristRight) +
          (left ? -_handLean : _handLean),
    );
    canvas.scale(0.9);
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
    final hip = left ? _hipLeft : Offset(_legMirror - _hipLeft.dx, _hipLeft.dy);
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(angle);
    canvas.translate(-hip.dx, -hip.dy);
    _mirrored(canvas, _legMirror, left, () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(113, 352, 141, 376),
          const Radius.circular(4),
        ),
        Paint()..color = colors.ink,
      );
      final leg = Path()
        ..moveTo(127, 366)
        ..lineTo(125, 444);
      drawTube(
        canvas,
        leg,
        width: 22,
        fill: colors.onInk,
        ink: colors.ink,
      );
      final shoe = roundedPolygon(
        const [
          Offset(138, 454),
          Offset(138, 431),
          Offset(112, 423),
          Offset(84, 432),
          Offset(79, 447),
          Offset(98, 454),
        ],
        10,
        radii: const [6, 8, 26, 16, 12, 8],
      );
      drawShape(canvas, shoe, colors.onInk, colors.ink);
    });
    canvas.restore();
  }

  void _paintGlass(Canvas canvas) {
    final glass = roundedPolygon(
      const [
        Offset(84, 98),
        Offset(46, 126),
        Offset(46, 332),
        Offset(96, 362),
        Offset(247, 347),
        Offset(256, 334),
        Offset(256, 126),
        Offset(218, 98),
      ],
      14,
      radii: const [6, 9, 14, 12, 12, 14, 9, 6],
    );
    drawShape(canvas, glass, colors.onInk, colors.ink);
  }

  void _paintContent(Canvas canvas) {
    final content = roundedPolygon(
      const [
        Offset(58, 156),
        Offset(205, 122),
        Offset(246, 138),
        Offset(246, 326),
        Offset(238, 340),
        Offset(98, 351),
        Offset(58, 328),
      ],
      8,
      radii: const [3, 8, 8, 10, 8, 12, 10],
    );
    canvas.drawPath(content, Paint()..color = colors.violetDeep);
    canvas.save();
    canvas.clipPath(content);
    final glare = roundedPolygon(
      const [
        Offset(176, 154),
        Offset(250, 138),
        Offset(250, 162),
        Offset(158, 166),
      ],
      6,
    );
    canvas.drawPath(
      glare,
      Paint()..color = colors.violet.withValues(alpha: 0.6),
    );
    final bubble = Paint()..color = colors.violet;
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          Offset(58 + i * 34.0 + (row.isOdd ? 17 : 0), 314.0 + row * 25),
          14.6,
          bubble,
        );
      }
    }
    final dots = Paint()..color = colors.ink.withValues(alpha: 0.85);
    const spots = [
      (Offset(130.8, 145.3), 3.6),
      (Offset(150, 144.3), 3.6),
      (Offset(138.3, 154.5), 3.6),
      (Offset(153.8, 156.5), 3.6),
      (Offset(165.8, 149.3), 3.9),
      (Offset(179.5, 133), 3.9),
      (Offset(191, 140.8), 3.9),
      (Offset(204.5, 132.3), 3.9),
      (Offset(216.3, 139), 3.9),
      (Offset(185, 152), 2.3),
      (Offset(100, 151.8), 1.7),
    ];
    for (final (center, radius) in spots) {
      canvas.drawCircle(center, radius, dots);
    }
    canvas.restore();
    canvas.drawPath(
      content,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintLabel(Canvas canvas) {
    final side = roundedPolygon(
      const [Offset(48, 152), Offset(90, 166), Offset(90, 309), Offset(48, 289)],
      3,
    );
    final front = roundedPolygon(
      const [
        Offset(90, 166),
        Offset(254, 160),
        Offset(254, 301),
        Offset(90, 309),
      ],
      3,
    );
    drawShape(canvas, side, _limeDark, colors.ink);
    drawShape(canvas, front, _lime, colors.ink);
  }

  void _paintFace(Canvas canvas, MascotPose pose) {
    final freckles = Paint()..color = colors.ink.withValues(alpha: 0.4);
    for (final p in const [
      Offset(119.7, 250),
      Offset(114.5, 257.8),
      Offset(124.5, 257.8),
      Offset(207.5, 250),
      Offset(202.5, 257.8),
      Offset(212.5, 257.8),
    ]) {
      canvas.drawCircle(p, 2.4, freckles);
    }
    drawEyes(
      canvas,
      colors,
      pose,
      left: const Offset(134.5, 222),
      right: const Offset(188.5, 222),
      outer: 22.5,
      inner: 19.3,
      pupil: 14.5,
      lookX: 12,
      lookY: 9,
      white: colors.onSaturated,
      lid: _lime,
      lidReach: 24,
    );
    final line = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (pose.sad >= 0.3) {
      canvas.drawPath(
        Path()
          ..moveTo(138, 271)
          ..quadraticBezierTo(160, 254, 183, 271),
        line,
      );
    } else if (pose.mouth >= 0.2) {
      paintMouth(canvas, const Offset(160, 263), 56, pose);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(133.5, 261.9)
          ..quadraticBezierTo(140, 265, 146.4, 261)
          ..quadraticBezierTo(168, 277, 186.7, 262.8),
        line,
      );
      canvas.drawPath(
        Path()
          ..moveTo(148.9, 251.3)
          ..quadraticBezierTo(148.8, 259, 146.4, 261),
        line,
      );
    }
  }

  void _paintLid(Canvas canvas, MascotPose pose) {
    canvas.save();
    if (pose.lid > 0) {
      canvas.translate(_lidPivot.dx, _lidPivot.dy);
      canvas.rotate(pose.lid * 0.1);
      canvas.translate(-_lidPivot.dx, -_lidPivot.dy - pose.lid * 24);
    }
    final body = Path()
      ..moveTo(70, 34)
      ..lineTo(70, 86)
      ..quadraticBezierTo(151, 112, 232, 86)
      ..lineTo(232, 34)
      ..close();
    canvas.drawPath(body, Paint()..color = colors.violet);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
      const Rect.fromLTRB(60, 20, 99, 120),
      Paint()..color = colors.violetDeep,
    );
    canvas.restore();
    canvas.drawPath(
      body,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = cleanLine
        ..strokeJoin = StrokeJoin.round,
    );
    final top = Path()..addOval(const Rect.fromLTRB(70, 21, 232, 46));
    drawShape(canvas, top, colors.violet, colors.ink);
    canvas.drawOval(
      const Rect.fromLTRB(79, 26, 223, 41),
      Paint()
        ..color = colors.violetDeep.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.restore();
  }
}
