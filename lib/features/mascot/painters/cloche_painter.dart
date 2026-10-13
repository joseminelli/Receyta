import 'package:flutter/material.dart';

import 'cloche_art.dart';
import 'mascot_painter.dart';
import 'mascot_pose.dart';

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
    _paintArm(canvas, ClochePart.armLeft, _shoulderLeft, pose.armLeft);
    _paintArm(canvas, ClochePart.armRight, _shoulderRight, -pose.armRight);
    _paintLayers(canvas, ClochePart.legLeft);
    _paintLayers(canvas, ClochePart.legRight);
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

  static final Path _armOuter = Path()
    ..addPolygon(const [
      Offset(32, 170),
      Offset(26, 178),
      Offset(20.5, 186),
      Offset(16.5, 195),
      Offset(14.6, 204),
      Offset(14, 214),
      Offset(13.7, 230),
      Offset(13.6, 246),
      Offset(41.4, 246),
      Offset(41.4, 170),
    ], true);

  static final Path _armInner = Path()
    ..addPolygon(const [
      Offset(35.2, 170),
      Offset(29.2, 178),
      Offset(23.7, 186),
      Offset(19.7, 195),
      Offset(17.8, 204),
      Offset(17.2, 214),
      Offset(16.9, 230),
      Offset(16.8, 246),
      Offset(38.5, 246),
      Offset(38.5, 170),
    ], true);

  void _paintArm(Canvas canvas, ClochePart part, Offset pivot, double angle) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    _paintUpperArm(canvas, part == ClochePart.armLeft);
    canvas.save();
    canvas.clipRect(const Rect.fromLTRB(-50, 238, 450, 500));
    _paintLayers(canvas, part);
    canvas.restore();
    canvas.restore();
  }

  /// Tubo do braço desde o ombro, escondido atrás da cúpula, até o antebraço.
  /// A pontinha que aparece ao lado da cúpula é só a parte do tubo que fica
  /// fora da silhueta dela.
  void _paintUpperArm(Canvas canvas, bool left) {
    canvas.save();
    if (!left) {
      canvas.translate(348, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawPath(_armOuter, fill(colors.ink));
    canvas.drawPath(_armInner, fill(colors.onInk));
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
    _paintEye(canvas, _eyeLeft, pose);
    _paintEye(canvas, _eyeRight, pose);
    _paintSmile(canvas, pose);
  }

  void _paintEye(Canvas canvas, Offset center, MascotPose pose) {
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
    canvas.restore();
    canvas.restore();
  }

  void _paintSmile(Canvas canvas, MascotPose pose) {
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
