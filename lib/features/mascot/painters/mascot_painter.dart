import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import 'mascot_pose.dart';

/// Base dos mascotes: aplica a pose (flutuação, inclinação, escala em torno
/// dos pés) e oferece o vocabulário de desenho em caixa de projeto 200 de
/// largura — contorno, preenchimento sombreado, olho e braço. Repinta a cada
/// mudança de [seconds], sem rebuild de widget.
abstract class MascotPainter extends CustomPainter {
  MascotPainter({
    required this.colors,
    required this.seconds,
    required this.poseAt,
  }) : super(repaint: seconds);

  final AppColors colors;
  final ValueListenable<double> seconds;
  final MascotPose Function(double seconds) poseAt;

  static const double designWidth = 200;
  static const double lineWidth = 3;

  /// Linha do chão na caixa de projeto: pivô da escala e da inclinação.
  double get groundY;

  void paintBody(Canvas canvas, MascotPose pose);

  @override
  void paint(Canvas canvas, Size size) {
    final pose = poseAt(seconds.value);
    canvas.scale(size.width / designWidth);
    _paintShadow(canvas, pose);
    canvas.save();
    canvas.translate(pose.dx, pose.dy);
    canvas.translate(100, groundY);
    canvas.rotate(pose.tilt);
    canvas.scale(pose.scaleX, pose.scaleY);
    canvas.translate(-100, -groundY);
    paintBody(canvas, pose);
    canvas.restore();
    _paintBurst(canvas, pose.burst);
  }

  void _paintBurst(Canvas canvas, double progress) {
    if (progress <= 0 || progress >= 1) return;
    final palette = [
      colors.lime,
      colors.coral,
      colors.violet,
      colors.coralLight,
      colors.violetMuted,
    ];
    final origin = Offset(100, groundY * 0.4);
    final spread = 1 - math.pow(1 - progress, 3).toDouble();
    for (var i = 0; i < 20; i++) {
      final angle =
          -math.pi / 2 + (i / 19 - 0.5) * 3.2 + math.sin(i * 12.9898) * 0.25;
      final speed = 70.0 + (i % 4) * 24;
      final position = origin +
          Offset(
            math.cos(angle) * speed * spread,
            math.sin(angle) * speed * spread + 120 * progress * progress,
          );
      final paint = fill(
        palette[i % palette.length].withValues(alpha: 1 - progress * progress),
      );
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(progress * 6 + i);
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 9, height: 4.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, 3.2, paint);
      }
      canvas.restore();
    }
  }

  void _paintShadow(Canvas canvas, MascotPose pose) {
    final radius = 56 + pose.dy * 0.8;
    final rect = Rect.fromCenter(
      center: Offset(100 + pose.dx, groundY + 1),
      width: radius * 2,
      height: 14,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            colors.ink.withValues(alpha: 0.2),
            colors.ink.withValues(alpha: 0.16),
            colors.ink.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  Paint get outline => Paint()
    ..color = colors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineWidth
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  Paint fill(Color color) => Paint()..color = color;

  /// Luz vinda da esquerda: clarão, meio neutro e sombra à direita.
  Paint shade(Rect rect) => Paint()
    ..shader = LinearGradient(
      colors: [
        colors.onSaturated.withValues(alpha: 0.28),
        colors.onSaturated.withValues(alpha: 0),
        colors.ink.withValues(alpha: 0.18),
      ],
      stops: const [0, 0.45, 1],
    ).createShader(rect);

  void shape(Canvas canvas, Path path, Color color, {bool shaded = false}) {
    canvas.drawPath(path, fill(color));
    if (shaded) {
      final bounds = path.getBounds();
      canvas.save();
      canvas.clipPath(path);
      canvas.drawRect(bounds, shade(bounds));
      canvas.restore();
    }
    canvas.drawPath(path, outline);
  }

  void rrect(
    Canvas canvas,
    Rect rect,
    double radius,
    Color color, {
    bool shaded = false,
  }) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    shape(canvas, path, color, shaded: shaded);
  }

  /// Braço com manga em `ink` e luva. [side] é -1 (esquerdo) ou 1 (direito);
  /// ângulo positivo afasta o braço do corpo.
  void paintArm(
    Canvas canvas,
    int side,
    double angle,
    Offset shoulder, {
    double reach = 1,
  }) {
    canvas.save();
    canvas.translate(shoulder.dx, shoulder.dy);
    canvas.rotate(-side * angle);
    final end = Offset(side * 17.0 * reach, 60 * reach);
    final arm = Path()
      ..quadraticBezierTo(side * 18.0 * reach, 28 * reach, end.dx, end.dy);
    canvas.drawPath(
      arm,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    final metric = arm.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(metric.length * 0.32, metric.length),
      Paint()
        ..color = colors.onInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5,
    );
    _paintHand(canvas, end + Offset(side * 2.0 * reach, 12 * reach), side);
    canvas.restore();
  }

  /// Luva grande: palma oval, polegar do lado de dentro e dois vincos de dedos.
  void _paintHand(Canvas canvas, Offset center, int side) {
    final thumb = Path()
      ..addOval(
        Rect.fromCenter(
          center: center + Offset(-side * 13.0, 2),
          width: 11,
          height: 18,
        ),
      );
    shape(canvas, thumb, colors.onInk);
    final palm = Path()
      ..addOval(Rect.fromCenter(center: center, width: 28, height: 32));
    shape(canvas, palm, colors.onInk, shaded: true);
    final crease = outline..strokeWidth = 2;
    for (final dx in const [-4.5, 4.5]) {
      canvas.drawLine(
        center + Offset(dx, 15),
        center + Offset(dx, 6),
        crease,
      );
    }
  }

  void paintEye(Canvas canvas, Offset center, MascotPose pose, double radius) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1, 1 - pose.blink * 0.9);
    final white = fill(colors.onSaturated);
    canvas.drawCircle(Offset.zero, radius, white);
    canvas.drawCircle(Offset.zero, radius, outline);
    final pupil = pose.look * (radius * 0.32);
    canvas.drawCircle(pupil, radius * 0.6, fill(colors.ink));
    canvas.drawCircle(
      pupil + Offset(-radius * 0.2, -radius * 0.22),
      radius * 0.2,
      white,
    );
    canvas.drawCircle(
      pupil + Offset(radius * 0.18, radius * 0.2),
      radius * 0.09,
      white,
    );
    canvas.restore();
  }

  /// Mão com pulso girando em [wristAngle]: mistura a luva fechada da arte
  /// ([paintClosed]) com a mão aberta ([paintOpen]) conforme [open] (0 a 1),
  /// com uma transição curta entre as duas.
  void paintHand(
    Canvas canvas, {
    required Offset wrist,
    required double wristAngle,
    required double open,
    required VoidCallback paintClosed,
    required VoidCallback paintOpen,
  }) {
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(wristAngle);
    canvas.translate(-wrist.dx, -wrist.dy);
    if (open < 0.02) {
      paintClosed();
    } else if (open > 0.98) {
      paintOpen();
    } else {
      final bounds = Rect.fromLTWH(wrist.dx - 90, wrist.dy - 30, 180, 180);
      canvas.saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(0, 0, 0, 1 - open),
      );
      paintClosed();
      canvas.restore();
      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, open));
      paintOpen();
      canvas.restore();
    }
    canvas.restore();
  }

  /// Sorriso fechado em `mouth` baixo; com a boca aberta, preenche em `ink`
  /// com a língua aparecendo.
  void paintMouth(Canvas canvas, Offset center, double width, MascotPose pose) {
    final half = width / 2;
    if (pose.mouth < 0.2) {
      final smile = Path()
        ..moveTo(center.dx - half, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + 12,
          center.dx + half,
          center.dy,
        );
      canvas.drawPath(smile, outline);
      return;
    }
    final depth = 10 + pose.mouth * 16;
    final mouth = Path()
      ..moveTo(center.dx - half, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + depth * 1.6,
        center.dx + half,
        center.dy,
      )
      ..close();
    canvas.drawPath(mouth, fill(colors.ink));
    canvas.save();
    canvas.clipPath(mouth);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + depth * 0.85),
        width: width * 0.55,
        height: depth * 0.7,
      ),
      fill(colors.coralLight),
    );
    canvas.restore();
    canvas.drawPath(mouth, outline);
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
