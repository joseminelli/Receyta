import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

const _w = 1568;
const _h = 600;
const _pad = 80.0;

/// Cabeçalho do PDF da receita: o bloco com a cor e a textura dela (o mesmo
/// do hero do app), o nome em Bricolage e, em cima, as tags. Desenhado fora da
/// árvore de widgets e entregue como PNG, já que o PDF não carrega a fonte do
/// app nem as texturas.
Future<Uint8List?> renderRecipePdfBanner({
  required Recipe recipe,
  List<String> tags = const [],
}) async {
  const colors = AppColors.light;
  final tile = resolveTileAppearance(
    colors,
    color: recipe.tileColor,
    motif: recipe.tileMotif,
    seedId: recipe.id,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble());

  canvas.clipRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(88)),
    doAntiAlias: true,
  );
  canvas.drawRect(
    rect,
    Paint()
      ..shader = tileShader(
        motif: tile.motif,
        background: tile.background,
        patternColor: tile.patternColor,
        patternColorAlt: tile.patternColorAlt,
        tile: 150,
        devicePixelRatio: 1,
      ),
  );

  final eyebrowText = tags.isEmpty
      ? 'RECEITA'
      : tags.take(3).map((t) => t.toUpperCase()).join('  ·  ');
  _text(
    eyebrowText,
    TextStyle(
      color: tile.onColor.withValues(alpha: 0.9),
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: 6,
    ),
    maxWidth: _w - _pad * 2,
  ).paint(canvas, const Offset(_pad, _pad));

  const width = _w - _pad * 2;
  var size = 132.0;
  late TextPainter title;
  for (; size >= 72; size -= 12) {
    title = _text(
      recipe.name,
      AppTextStyles.display(size).copyWith(color: tile.onColor, height: 1.02),
      maxWidth: width,
      maxLines: 3,
    );
    if (!title.didExceedMaxLines && title.height <= _h - _pad * 2 - 90) break;
  }
  title.paint(canvas, Offset(_pad, _h - _pad - title.height));

  final image = await recorder.endRecording().toImage(_w, _h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
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
