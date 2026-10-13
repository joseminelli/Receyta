import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import 'hand_art.dart';

/// Posição e inclinação do punho de uma luva, em pixels da imagem de origem.
class CuffFrame {
  const CuffFrame(this.center, this.angle);

  final Offset center;
  final double angle;
}

class _Layer {
  const _Layer(this.tone, this.path);

  final HandTone tone;
  final Path path;
}

/// Mão aberta da arte do Cloche (pose com os dedos em leque), vetorizada como
/// o resto. Serve aos dois personagens: o desenho é alinhado pelo punho à luva
/// fechada de cada um, com [scale] ajustando o tamanho.
class OpenHand {
  static const _sourceLeft = CuffFrame(Offset(45.1, 279.8), -0.240);
  static const _sourceRight = CuffFrame(Offset(304.0, 279.9), 0.257);

  static final Map<HandPart, List<_Layer>> _layers = {
    for (final entry in handShapes.entries)
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

  static void paint(
    Canvas canvas,
    AppColors colors, {
    required bool left,
    required CuffFrame target,
    required double scale,
  }) {
    final source = left ? _sourceLeft : _sourceRight;
    canvas.save();
    canvas.translate(target.center.dx, target.center.dy);
    canvas.rotate(target.angle - source.angle);
    canvas.scale(scale);
    canvas.translate(-source.center.dx, -source.center.dy);
    for (final layer in _layers[left ? HandPart.handLeft : HandPart.handRight]!) {
      final isInk = layer.tone == HandTone.ink;
      final color = isInk ? colors.ink : colors.onInk;
      canvas.drawPath(layer.path, Paint()..color = color);
      canvas.drawPath(
        layer.path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = isInk ? 0.3 : 0.8
          ..strokeJoin = StrokeJoin.round,
      );
    }
    canvas.restore();
  }
}
