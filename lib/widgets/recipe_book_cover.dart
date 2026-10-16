import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_pattern.dart';

const _w = 1240;
const _h = 1754;
const _pad = 110.0;

/// Capa do livro de receitas em PDF: página inteira escura com a textura do
/// app, o selo "Livro de receitas", o título grande e a contagem. Desenhada
/// fora da árvore de widgets e entregue como PNG, pelo mesmo motivo do banner
/// da receita (o PDF não carrega a fonte do app nem as texturas).
Future<Uint8List?> renderRecipeBookCover({
  required String title,
  required String subtitle,
}) async {
  const colors = AppColors.light;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble());

  canvas.drawRect(
    rect,
    Paint()
      ..shader = tileShader(
        motif: TileMotif.ponto,
        background: colors.ink,
        patternColor: colors.inkPattern,
        patternColorAlt: colors.inkPatternAlt,
        tile: 190,
        devicePixelRatio: 1,
      ),
  );

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(_pad, _pad, 300, 64),
      const Radius.circular(32),
    ),
    Paint()..color = colors.lime,
  );
  _text(
    'RECEYTA',
    TextStyle(
      color: colors.ink,
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: 6,
    ),
  ).paint(canvas, const Offset(_pad + 40, _pad + 14));

  const width = _w - _pad * 2;
  var size = 190.0;
  late TextPainter heading;
  for (; size >= 90; size -= 10) {
    heading = _text(
      title,
      AppTextStyles.display(size)
          .copyWith(color: colors.onSaturated, height: 1.0),
      maxWidth: width,
      maxLines: 4,
    );
    if (!heading.didExceedMaxLines) break;
  }
  final top = _h - _pad - 150 - heading.height;
  heading.paint(canvas, Offset(_pad, top));

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(_pad, _h - _pad - 110, 120, 12),
      const Radius.circular(6),
    ),
    Paint()..color = colors.lime,
  );
  _text(
    subtitle,
    TextStyle(
      color: colors.onSaturated.withValues(alpha: 0.85),
      fontSize: 44,
      fontWeight: FontWeight.w600,
    ),
    maxWidth: width,
  ).paint(canvas, Offset(_pad, _h - _pad - 70));

  final picture = recorder.endRecording();
  final image = await picture.toImage(_w, _h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  picture.dispose();
  image.dispose();
  return data?.buffer.asUint8List();
}

TextPainter _text(
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  int maxLines = 1,
}) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
}
