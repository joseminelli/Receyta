import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';

export 'package:receyta/core/tile_style.dart' show TileMotif;

/// Módulo determinístico a partir de um id (§9.4) — sem campo no banco.
///
/// A mesma receita mantém a estampa para sempre e em qualquer dispositivo:
/// `String.hashCode` é estável dentro de um mesmo runtime, e o plano aceita
/// essa premissa. Se ela ganhar foto depois, a foto cobre o padrão.
TileMotif tileMotifForId(String id) =>
    TileMotif.values[id.hashCode.abs() % TileMotif.values.length];

/// Preenche o espaço com um bloco de cor chapado e o azulejo por cima,
/// tom sobre tom (§9.4).
///
/// Entra só em blocos que substituem foto — hero de receita, tile de pasta,
/// bloco de sugestão, canto de cabeçalho. **Nunca** atrás de texto corrido,
/// lista de ingredientes ou barra de navegação.
///
/// O desenho de um tile é rasterizado uma vez por `(módulo, cores, tile, dpr)`
/// e reusado como shader repetido — 60 cards com padrão custam uma
/// `drawRect` por card, não um path por pixel.
class TilePattern extends StatelessWidget {
  const TilePattern({
    super.key,
    required this.motif,
    required this.background,
    required this.patternColor,
    this.patternColorAlt,
    this.tile = 40,
  });

  final TileMotif motif;

  /// Cor chapada do bloco. Vem da seção (§9.2), não do módulo.
  final Color background;

  /// Variante clara do próprio matiz, contraste ~12% (§9.4).
  final Color patternColor;

  /// Segundo tom — só [TileMotif.diagonal] usa. Default: [patternColor].
  final Color? patternColorAlt;

  /// Lado do tile em px lógicos. 40 por padrão, nunca abaixo de 32 (§9.4).
  final double tile;

  @override
  Widget build(BuildContext context) {
    assert(tile >= 32, 'tile miúdo faz o azulejo parecer artesanal (§9.4)');
    return CustomPaint(
      isComplex: true,
      willChange: false,
      painter: _TilePatternPainter(
        motif: motif,
        background: background,
        patternColor: patternColor,
        patternColorAlt: patternColorAlt ?? patternColor,
        tile: tile,
        devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _TilePatternPainter extends CustomPainter {
  _TilePatternPainter({
    required this.motif,
    required this.background,
    required this.patternColor,
    required this.patternColorAlt,
    required this.tile,
    required this.devicePixelRatio,
  });

  final TileMotif motif;
  final Color background;
  final Color patternColor;
  final Color patternColorAlt;
  final double tile;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = background);

    final image = _tileImage(
      _TileKey(motif, patternColor, patternColorAlt, tile, devicePixelRatio),
    );
    // A imagem é `tile * dpr` px; o shader precisa encolher de volta ao lógico.
    final s = 1 / devicePixelRatio;
    final matrix = Float64List.fromList([
      s, 0, 0, 0, //
      0, s, 0, 0, //
      0, 0, 1, 0, //
      0, 0, 0, 1, //
    ]);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix,
        ),
    );
  }

  @override
  bool shouldRepaint(_TilePatternPainter old) =>
      old.motif != motif ||
      old.background != background ||
      old.patternColor != patternColor ||
      old.patternColorAlt != patternColorAlt ||
      old.tile != tile ||
      old.devicePixelRatio != devicePixelRatio;
}

// ---------------------------------------------------------------------------
// Cache de tiles rasterizados
// ---------------------------------------------------------------------------

@immutable
class _TileKey {
  const _TileKey(this.motif, this.color, this.colorAlt, this.tile, this.dpr);

  final TileMotif motif;
  final Color color;
  final Color colorAlt;
  final double tile;
  final double dpr;

  @override
  bool operator ==(Object other) =>
      other is _TileKey &&
      other.motif == motif &&
      other.color == color &&
      other.colorAlt == colorAlt &&
      other.tile == tile &&
      other.dpr == dpr;

  @override
  int get hashCode => Object.hash(motif, color, colorAlt, tile, dpr);
}

/// O azulejo (fundo + padrão) como `Shader`, pra usar fora do [TilePattern] —
/// ex. um `ShaderMask` "vazando" a textura através de texto ou ícone, em vez
/// de um bloco de cor. Reaproveita o mesmo raster das formas ([_tileImage]) e
/// só compõe o fundo por baixo, já que aqui não tem uma segunda camada de
/// fundo pra completar como no [TilePattern] normal.
Shader tileShader({
  required TileMotif motif,
  required Color background,
  required Color patternColor,
  Color? patternColorAlt,
  double tile = 40,
  required double devicePixelRatio,
}) {
  final shapes = _tileImage(_TileKey(
    motif,
    patternColor,
    patternColorAlt ?? patternColor,
    tile,
    devicePixelRatio,
  ));
  final px = shapes.width.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, px, px), Paint()..color = background);
  canvas.drawImage(shapes, Offset.zero, Paint());
  final composed = recorder.endRecording().toImageSync(shapes.width, shapes.height);

  final s = 1 / devicePixelRatio;
  final matrix = Float64List.fromList([
    s, 0, 0, 0, //
    0, s, 0, 0, //
    0, 0, 1, 0, //
    0, 0, 0, 1, //
  ]);
  return ui.ImageShader(composed, TileMode.repeated, TileMode.repeated, matrix);
}

final Map<_TileKey, ui.Image> _tileCache = {};

ui.Image _tileImage(_TileKey key) {
  final cached = _tileCache[key];
  if (cached != null) return cached;

  final px = math.max(1, (key.tile * key.dpr).round());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(key.dpr);
  _paintMotifTile(canvas, key);
  final image = recorder.endRecording().toImageSync(px, px);

  _tileCache[key] = image;
  return image;
}

void _paintMotifTile(Canvas canvas, _TileKey key) {
  final t = key.tile;
  final fill = Paint()
    ..color = key.color
    ..isAntiAlias = true;

  switch (key.motif) {
    case TileMotif.arco:
      // Quarto de círculo ancorado no canto superior esquerdo, raio = tile.
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(t, 0)
        ..arcToPoint(Offset(0, t), radius: Radius.circular(t), clockwise: false)
        ..close();
      canvas.drawPath(path, fill);

    case TileMotif.meiaLua:
      // Meio-disco na borda esquerda apontando para dentro e outro na borda
      // direita apontando para dentro — repetidos, viram meias-luas alternadas.
      canvas.drawPath(
        Path()
          ..addArc(
              Rect.fromCircle(center: Offset(0, t / 2), radius: t / 2), -math.pi / 2, math.pi),
        fill,
      );
      canvas.drawPath(
        Path()
          ..addArc(
              Rect.fromCircle(center: Offset(t, t / 2), radius: t / 2), math.pi / 2, math.pi),
        fill,
      );

    case TileMotif.diagonal:
      // Triângulo superior num tom, inferior no segundo tom (§9.4).
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(t, 0)
          ..lineTo(0, t)
          ..close(),
        fill,
      );
      canvas.drawPath(
        Path()
          ..moveTo(t, 0)
          ..lineTo(t, t)
          ..lineTo(0, t)
          ..close(),
        Paint()
          ..color = key.colorAlt
          ..isAntiAlias = true,
      );

    case TileMotif.ponto:
      // Dois pontos em diagonal — repetidos, formam a grade deslocada.
      final r = t * 0.16;
      canvas.drawCircle(Offset(t * 0.25, t * 0.25), r, fill);
      canvas.drawCircle(Offset(t * 0.75, t * 0.75), r, fill);
  }
}

// ---------------------------------------------------------------------------
// Ganchos de teste
// ---------------------------------------------------------------------------

/// Quantos tiles distintos estão rasterizados em memória. Um scroll de 60 cards
/// com 4 módulos e uma cor por módulo deve estabilizar em 4.
@visibleForTesting
int get tilePatternCacheLength => _tileCache.length;

@visibleForTesting
void clearTilePatternCache() {
  for (final image in _tileCache.values) {
    image.dispose();
  }
  _tileCache.clear();
}
