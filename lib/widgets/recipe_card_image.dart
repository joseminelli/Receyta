import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

const _width = 1080;
const _height = 1920;
const _margin = 56.0;
const _headerHeight = 820.0;
const _metricsTop = _headerHeight + 28;
const _metricHeight = 150.0;
const _gap = 24.0;
const _panelBottom = 1620.0;
const _lineHeight = 60.0;

/// Cartão de uma receita pra compartilhar como imagem (1080×1920, 9:16, o
/// formato de stories, com folga no topo e no pé pra a interface do app):
/// capa com a foto ou o azulejo e o nome grande, tempos e porções, os
/// primeiros ingredientes num bloco escuro e a assinatura do Receyta. Mesmo
/// desenho dos cartões de dia e da retrospectiva, desenhado fora da árvore de
/// widgets. [photo] são os bytes da foto da receita, se ela tem uma. Devolve o
/// PNG.
Future<Uint8List?> renderRecipeCardPng(
  RecipeDetail detail, {
  Uint8List? photo,
}) async {
  const colors = AppColors.light;
  final recipe = detail.recipe;
  final tile = resolveTileAppearance(
    colors,
    color: recipe.tileColor,
    motif: recipe.tileMotif,
    seedId: recipe.id,
  );
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, _width.toDouble(), _height.toDouble()),
    Paint()..color = colors.paper,
  );

  ui.Image? photoImage;
  if (photo != null) {
    try {
      final codec = await ui.instantiateImageCodec(photo, targetWidth: _width);
      photoImage = (await codec.getNextFrame()).image;
    } catch (_) {
      photoImage = null;
    }
  }

  final onCover = photoImage == null ? tile.onColor : colors.onSaturated;
  _drawHeader(canvas, colors, detail, tile, photoImage, onCover);
  photoImage?.dispose();

  var y = _metricsTop;
  final metrics = <(String, String)>[
    if (recipe.prepMinutes != null && recipe.prepMinutes! > 0)
      ('PREPARO', formatCookingTime(recipe.prepMinutes!)),
    if (recipe.cookMinutes != null && recipe.cookMinutes! > 0)
      ('FOGÃO', formatCookingTime(recipe.cookMinutes!)),
    if (recipe.servings != null && recipe.servings! > 0)
      ('PORÇÕES', '${recipe.servings}'),
  ];
  if (metrics.isNotEmpty) {
    _drawMetrics(canvas, colors, metrics, y);
    y += _metricHeight + _gap;
  }

  final lines = [
    for (final i in detail.ingredients)
      if (i.rawText.trim().isNotEmpty) i.rawText.trim(),
  ];
  if (lines.isNotEmpty) _drawIngredients(canvas, colors, lines, y);

  _drawFooter(canvas, colors, _panelBottom + 28);

  final image = await recorder.endRecording().toImage(_width, _height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

TextPainter _text(
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  int maxLines = 1,
  TextAlign align = TextAlign.left,
}) {
  return TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
}

void _drawHeader(
  Canvas canvas,
  AppColors colors,
  RecipeDetail detail,
  TileAppearance tile,
  ui.Image? photo,
  Color onCover,
) {
  final rect = Rect.fromLTWH(0, 0, _width.toDouble(), _headerHeight);
  canvas.save();
  canvas.clipRRect(
    RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(72),
      bottomRight: const Radius.circular(72),
    ),
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
        tile: 120,
        devicePixelRatio: 1,
      ),
  );
  if (photo != null) {
    final scale = [
      rect.width / photo.width,
      rect.height / photo.height,
    ].reduce((a, b) => a > b ? a : b);
    final src = Rect.fromCenter(
      center: Offset(photo.width / 2, photo.height / 2),
      width: rect.width / scale,
      height: rect.height / scale,
    );
    canvas.drawImageRect(
      photo,
      src,
      rect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, _headerHeight),
          [
            colors.ink.withValues(alpha: 0.45),
            colors.ink.withValues(alpha: 0),
            colors.ink.withValues(alpha: 0),
            colors.ink.withValues(alpha: 0.8),
          ],
          const [0, 0.28, 0.5, 1],
        ),
    );
  }
  canvas.restore();

  final tags = [for (final t in detail.tags.take(3)) t.name.toUpperCase()];
  _text(
    tags.isEmpty ? 'RECEITA' : tags.join('  ·  '),
    TextStyle(
      color: onCover.withValues(alpha: 0.92),
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: 6,
    ),
    maxWidth: _width - _margin * 2,
  ).paint(canvas, const Offset(_margin, 150));

  const maxWidth = _width - _margin * 2;
  late TextPainter title;
  for (var size = 150.0; size >= 66; size -= 12) {
    title = _text(
      detail.recipe.name,
      AppTextStyles.display(size).copyWith(color: onCover, height: 1.02),
      maxWidth: maxWidth,
      maxLines: 3,
    );
    if (!title.didExceedMaxLines && title.height <= _headerHeight - 250) break;
  }
  title.paint(canvas, Offset(_margin, _headerHeight - 56 - title.height));
}

void _drawMetrics(
  Canvas canvas,
  AppColors colors,
  List<(String, String)> metrics,
  double y,
) {
  final count = metrics.length;
  final cellWidth = (_width - _margin * 2 - _gap * (count - 1)) / count;
  for (var i = 0; i < count; i++) {
    final rect = Rect.fromLTWH(
      _margin + i * (cellWidth + _gap),
      y,
      cellWidth,
      _metricHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(44)),
      Paint()..color = colors.paperSoft,
    );
    _text(
      metrics[i].$1,
      TextStyle(
        color: colors.textMuted,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
      maxWidth: cellWidth - 64,
    ).paint(canvas, Offset(rect.left + 32, rect.top + 28));
    _text(
      metrics[i].$2,
      AppTextStyles.display(68).copyWith(color: colors.ink),
      maxWidth: cellWidth - 64,
    ).paint(canvas, Offset(rect.left + 32, rect.top + 64));
  }
}

void _drawIngredients(
  Canvas canvas,
  AppColors colors,
  List<String> lines,
  double top,
) {
  final panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(_margin, top, _width - _margin * 2, _panelBottom - top),
    const Radius.circular(54),
  );
  canvas.drawRRect(panel, Paint()..color = colors.ink);

  _text(
    'INGREDIENTES',
    TextStyle(
      color: colors.lime,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 5,
    ),
  ).paint(canvas, Offset(_margin + 48, top + 42));

  const bodyTop = 112.0;
  final room = ((panel.height - bodyTop - 28) / _lineHeight).floor();
  final fits = lines.length <= room;
  final shown = fits ? lines.length : (room - 1).clamp(0, lines.length);
  final textWidth = _width - _margin * 2 - 96;
  for (var i = 0; i < shown; i++) {
    _text(
      lines[i],
      TextStyle(
        color: colors.onSaturated,
        fontSize: 40,
        fontWeight: FontWeight.w500,
      ),
      maxWidth: textWidth,
    ).paint(canvas, Offset(_margin + 48, top + bodyTop + i * _lineHeight));
  }
  if (!fits) {
    final more = lines.length - shown;
    _text(
      more == 1 ? '+ 1 ingrediente' : '+ $more ingredientes',
      TextStyle(
        color: colors.lime,
        fontSize: 34,
        fontWeight: FontWeight.w700,
      ),
      maxWidth: textWidth,
    ).paint(canvas, Offset(_margin + 48, top + bodyTop + shown * _lineHeight));
  }
}

void _drawFooter(Canvas canvas, AppColors colors, double y) {
  final brand = _text(
    'Receyta',
    AppTextStyles.display(64).copyWith(color: colors.ink),
    maxWidth: _width.toDouble(),
    align: TextAlign.center,
  );
  brand.paint(canvas, Offset((_width - brand.width) / 2, y));
  final tagline = _text(
    'Suas receitas, num lugar só',
    TextStyle(
      color: colors.textMuted,
      fontSize: 32,
      fontWeight: FontWeight.w500,
    ),
    maxWidth: _width.toDouble(),
    align: TextAlign.center,
  );
  tagline.paint(canvas, Offset((_width - tagline.width) / 2, y + 78));
}
