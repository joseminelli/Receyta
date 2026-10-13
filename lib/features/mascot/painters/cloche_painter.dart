import 'package:flutter/material.dart';

import 'cloche_art.dart';
import 'mascot_painter.dart';
import 'mascot_pose.dart';
import 'open_hand.dart';

class _Layer {
  const _Layer(this.tone, this.path);

  final ClocheTone tone;
  final Path path;
}

/// Mascote Cloche. O corpo vem da vetorização da arte de referência
/// (`cloche_art.dart`), dividida em partes que se movem separadas: braços,
/// pernas, botão e cúpula. Olhos e boca são desenhados aqui, nas coordenadas
/// da imagem. Caixa de projeto 200×216.
class ClochePainter extends MascotPainter {
  ClochePainter({
    required super.colors,
    required super.seconds,
    required super.poseAt,
  });

  static const double designHeight = 216;

  static const _scale = MascotPainter.designWidth / clocheArtWidth;
  static const _shoulderLeft = Offset(40, 176);
  static const _shoulderRight = Offset(308, 176);
  static const _wristLeft = Offset(33.5, 272);
  static const _wristRight = Offset(314.5, 272);
  static const _cuffLeft = HandFrame(Offset(33.2, 270.4), 0.386);
  static const _cuffRight = HandFrame(Offset(314.8, 270.4), -0.386);
  static const _hipLeft = Offset(146, 248);
  static const _hipRight = Offset(201, 248);
  static const _knobPivot = Offset(175, 50);
  static const _eyeLeft = Offset(142.5, 132);
  static const _eyeRight = Offset(207.5, 132);

  static final Map<ClochePart, List<_Layer>> _layers = {
    for (final entry in clocheShapes.entries)
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
  double get groundY => 207;

  Color _tone(ClocheTone tone) => switch (tone) {
        ClocheTone.ink => colors.ink,
        ClocheTone.cream => colors.onInk,
        ClocheTone.coral => colors.coral,
        ClocheTone.coralDark => Color.lerp(colors.coral, colors.ink, 0.22)!,
        ClocheTone.coralLight => colors.coralLight,
      };

  @override
  void paintBody(Canvas canvas, MascotPose pose) {
    canvas.scale(_scale);
    canvas.translate(1.5, 0);
    _paintArm(canvas, pose, left: true);
    _paintArm(canvas, pose, left: false);
    _paintLeg(canvas, ClochePart.legLeft, _hipLeft, pose.legLeft);
    _paintLeg(canvas, ClochePart.legRight, _hipRight, -pose.legRight);
    _paintKnob(canvas, pose);
    _paintLayers(canvas, ClochePart.body);
    _paintFace(canvas, pose);
  }

  void _paintLayers(Canvas canvas, ClochePart part) {
    for (final layer in _layers[part]!) {
      final color = _tone(layer.tone);
      canvas.drawPath(layer.path, Paint()..color = color);
      canvas.drawPath(
        layer.path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = layer.tone == ClocheTone.ink ? 0.3 : 0.8
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  static final Path _armPath = Path()
    ..moveTo(44, 170)
    ..cubicTo(30, 184, 27, 216, 27.4, 246)
    ..cubicTo(27.8, 258, 31.5, 268, 35, 277);

  void _paintArm(Canvas canvas, MascotPose pose, {required bool left}) {
    final pivot = left ? _shoulderLeft : _shoulderRight;
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(left ? pose.armLeft : -pose.armRight);
    canvas.translate(-pivot.dx, -pivot.dy);
    _paintArmTube(canvas, left);
    paintHand(
      canvas,
      wrist: left ? _wristLeft : _wristRight,
      wristAngle: left ? pose.wristLeft : -pose.wristRight,
      open: left ? pose.handLeft : pose.handRight,
      paintClosed: () => _paintLayers(
        canvas,
        left ? ClochePart.handLeft : ClochePart.handRight,
      ),
      paintOpen: () => OpenHand.paint(
        canvas,
        colors,
        left: left,
        target: left ? _cuffLeft : _cuffRight,
        scale: 1,
      ),
    );
    canvas.restore();
  }

  void _paintLeg(Canvas canvas, ClochePart part, Offset hip, double angle) {
    canvas.save();
    canvas.translate(hip.dx, hip.dy);
    canvas.rotate(angle);
    canvas.translate(-hip.dx, -hip.dy);
    _paintLayers(canvas, part);
    canvas.restore();
  }

  /// O braço é um tubo contínuo, desde o ombro escondido atrás da cúpula até o
  /// punho. A pontinha que aparece ao lado da cúpula é só a parte do tubo que
  /// fica fora da silhueta dela.
  void _paintArmTube(Canvas canvas, bool left) {
    canvas.save();
    if (!left) {
      canvas.translate(348, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(
      _armPath,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 27.4,
    );
    canvas.drawPath(
      _armPath,
      Paint()
        ..color = colors.onInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 21,
    );
    canvas.restore();
  }

  void _paintKnob(Canvas canvas, MascotPose pose) {
    canvas.save();
    if (pose.lid > 0) {
      canvas.translate(_knobPivot.dx, _knobPivot.dy);
      canvas.rotate(pose.lid * 0.25);
      canvas.translate(-_knobPivot.dx, -_knobPivot.dy - pose.lid * 12);
    }
    _paintLayers(canvas, ClochePart.knob);
    canvas.restore();
  }

  void _paintFace(Canvas canvas, MascotPose pose) {
    _paintEye(canvas, _eyeLeft, pose, -1);
    _paintEye(canvas, _eyeRight, pose, 1);
    _paintSmile(canvas, pose);
  }

  void _paintEye(Canvas canvas, Offset center, MascotPose pose, int side) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, 1 - pose.blink * 0.9);
    canvas.drawCircle(Offset.zero, 27, fill(colors.ink));
    final white = Path()
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: 23.6));
    canvas.drawPath(white, fill(colors.onInk));
    canvas.save();
    canvas.clipPath(white);
    final pupil = Offset(pose.look.dx * 8, pose.look.dy * 7);
    canvas.drawCircle(pupil, 17, fill(colors.ink));
    canvas.drawCircle(
      pupil + const Offset(-9.5, -6.5),
      5.8,
      fill(colors.onSaturated),
    );
    if (pose.sad > 0.02) _paintEyelid(canvas, pose.sad, side);
    canvas.restore();
    canvas.restore();
  }

  /// Pálpebra caída: cobre mais o canto de fora, o que dá o ar de tristeza.
  void _paintEyelid(Canvas canvas, double sad, int side) {
    final outer = side * 30.0;
    final inside = -side * 30.0;
    final lid = Path()
      ..moveTo(outer, -40)
      ..lineTo(inside, -40)
      ..lineTo(inside, -21 + 4 * sad)
      ..lineTo(outer, -21 + 19 * sad)
      ..close();
    canvas.drawPath(lid, fill(_tone(ClocheTone.coral)));
    canvas.drawLine(
      Offset(outer, -21 + 19 * sad),
      Offset(inside, -21 + 4 * sad),
      Paint()
        ..color = colors.ink
        ..strokeWidth = 3.2,
    );
  }

  void _paintSmile(Canvas canvas, MascotPose pose) {
    if (pose.sad >= 0.3) {
      final frown = Path()
        ..moveTo(150, 187)
        ..quadraticBezierTo(175, 166, 200, 187);
      canvas.drawPath(
        frown,
        Paint()
          ..color = colors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    if (pose.mouth >= 0.2) {
      paintMouth(canvas, const Offset(175, 177), 58, pose);
      return;
    }
    final line = Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final smile = Path()
      ..moveTo(148, 175)
      ..quadraticBezierTo(175, 197, 201, 177);
    canvas.drawPath(smile, line);
  }
}
