import 'package:flutter/material.dart';

import 'mascot_painter.dart';
import 'mascot_pose.dart';
import 'pote_art.dart';

class _Layer {
  const _Layer(this.tone, this.path);

  final PoteTone tone;
  final Path path;
}

/// Mascote Pote. O corpo vem da vetorização da arte de referência
/// (`pote_art.dart`), dividida em partes que se movem separadas: braços,
/// pernas, corpo e tampa. Olhos, boca, sardas e pontinhos do conteúdo são
/// desenhados aqui, nas coordenadas da imagem. Caixa de projeto 200×309.
class PotePainter extends MascotPainter {
  PotePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 309;

  static const _scale = MascotPainter.designWidth / poteArtWidth;
  static const _shoulderLeft = Offset(46, 272);
  static const _shoulderRight = Offset(252, 270);
  static const _lidPivot = Offset(151, 98);
  static const _eyeLeft = Offset(134.5, 222);
  static const _eyeRight = Offset(188.5, 222);

  static final Map<PotePart, List<_Layer>> _layers = {
    for (final entry in poteShapes.entries)
      entry.key: [
        for (final shape in entry.value)
          _Layer(shape.tone, _toPath(shape.loops)),
      ],
  };

  static Path _toPath(List<List<double>> loops) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final loop in loops) {
      path.addPolygon(
        [for (var i = 0; i < loop.length; i += 2) Offset(loop[i], loop[i + 1])],
        true,
      );
    }
    return path;
  }

  @override
  double get groundY => 288;

  Color _tone(PoteTone tone) => switch (tone) {
        PoteTone.ink => colors.ink,
        PoteTone.cream => colors.onInk,
        PoteTone.white => colors.onSaturated,
        PoteTone.lime => colors.limePattern,
        PoteTone.limeDark => Color.lerp(colors.limePattern, colors.ink, 0.2)!,
        PoteTone.violet => colors.violet,
        PoteTone.violetDeep => colors.violetDeep,
      };

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    canvas.scale(_scale);
    canvas.translate(6.5, 0);
    _paintArm(canvas, PotePart.armLeft, _shoulderLeft, pose.armLeft);
    _paintArm(canvas, PotePart.armRight, _shoulderRight, -pose.armRight);
    _paintLayers(canvas, PotePart.legLeft);
    _paintLayers(canvas, PotePart.legRight);
    _paintLayers(canvas, PotePart.body);
    _paintContentDots(canvas);
    _paintFace(canvas, pose);
    _paintLid(canvas, pose);
  }

  void _paintLayers(Canvas canvas, PotePart part) {
    for (final layer in _layers[part]!) {
      final color = _tone(layer.tone);
      canvas.drawPath(layer.path, Paint()..color = color);
      canvas.drawPath(
        layer.path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer.tone == PoteTone.ink ? 0.3 : 0.8
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _paintArm(Canvas canvas, PotePart part, Offset pivot, double angle) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _paintLayers(canvas, part);
    canvas.restore();
  }

  void _paintLid(Canvas canvas, MascotPose pose) {
    canvas.save();
    if (pose.lid > 0) {
      canvas.translate(_lidPivot.dx, _lidPivot.dy);
      canvas.rotate(pose.lid * 0.1);
      canvas.translate(-_lidPivot.dx, -_lidPivot.dy - pose.lid * 24);
    }
    _paintLayers(canvas, PotePart.lid);
    canvas.restore();
  }

  void _paintContentDots(Canvas canvas) {
    final dots = fill(colors.ink.withValues(alpha: 0.85));
    const spots = [
      (Offset(130.8, 145.3), 3.5),
      (Offset(150, 144.3), 3.5),
      (Offset(138.3, 154.5), 3.5),
      (Offset(153.8, 156.5), 3.5),
      (Offset(165.8, 149.3), 3.8),
      (Offset(179.5, 133), 3.8),
      (Offset(191, 140.8), 3.8),
      (Offset(204.5, 132.3), 3.8),
      (Offset(216.3, 139), 3.8),
      (Offset(185, 152), 2.2),
      (Offset(100, 151.8), 1.6),
    ];
    for (final (center, radius) in spots) {
      canvas.drawCircle(center, radius, dots);
    }
  }

  void _paintFace(Canvas canvas, MascotPose pose) {
    final freckles = fill(colors.ink.withValues(alpha: 0.4));
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
    _paintEye(canvas, _eyeLeft, pose);
    _paintEye(canvas, _eyeRight, pose);
    _paintSmile(canvas, pose);
  }

  void _paintEye(Canvas canvas, Offset center, MascotPose pose) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, 1 - pose.blink * 0.9);
    canvas.drawCircle(Offset.zero, 22.5, fill(colors.ink));
    final white = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 19.3));
    canvas.drawPath(white, fill(colors.onSaturated));
    canvas.save();
    canvas.clipPath(white);
    final pupil = Offset(pose.look.dx * 12, pose.look.dy * 9);
    canvas.drawCircle(pupil, 14.5, fill(colors.ink));
    canvas.drawCircle(
      pupil + const Offset(-10, -1.5),
      4.6,
      fill(colors.onSaturated),
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintSmile(Canvas canvas, MascotPose pose) {
    if (pose.mouth >= 0.2) {
      paintMouth(canvas, const Offset(160, 263), 56, pose);
      return;
    }
    final line = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final main = Path()
      ..moveTo(133.5, 261.9)
      ..quadraticBezierTo(140, 265, 146.4, 261)
      ..quadraticBezierTo(168, 277, 186.7, 262.8);
    final hook = Path()
      ..moveTo(148.9, 251.3)
      ..quadraticBezierTo(148.8, 259, 146.4, 261);
    canvas.drawPath(main, line);
    canvas.drawPath(hook, line);
  }
}
