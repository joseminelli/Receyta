import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

const _width = 1080;
const _margin = 56.0;
const _headerHeight = 460.0;
const _bigHeight = 420.0;
const _statHeight = 230.0;
const _gap = 28.0;
const _topHeight = 300.0;
const _footerHeight = 200.0;

/// Altura da imagem: cabeçalho, número grande, duas fileiras de quatro dados,
/// a receita campeã (se houver) e a assinatura.
double retroCardHeight(Retrospective r) =>
    _headerHeight +
    _gap +
    _bigHeight +
    _gap +
    2 * _statHeight +
    _gap +
    (r.topRecipe == null ? 0 : _gap + _topHeight) +
    _footerHeight;

/// Desenha, fora da árvore de widgets, o cartão da retrospectiva pra
/// compartilhar — mesmo desenho dos cartões de dia e de semana: cabeçalho
/// colorido com a textura do app, blocos claros embaixo e a assinatura do
/// Receyta. Devolve o PNG.
Future<Uint8List?> renderRetroCardPng(Retrospective r) async {
  const colors = AppColors.light;
  final height = retroCardHeight(r);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, _width.toDouble(), height),
    Paint()..color = colors.paper,
  );

  _drawHeader(canvas, colors, r);
  var y = _headerHeight + _gap;
  _drawBigNumber(canvas, colors, r, y);
  y += _bigHeight + _gap;
  _drawStats(canvas, colors, r, y);
  y += 2 * _statHeight + _gap;
  if (r.topRecipe != null) {
    y += _gap;
    _drawTopRecipe(canvas, colors, r, y);
    y += _topHeight;
  }
  _drawFooter(canvas, colors, y + 28);

  final image = await recorder.endRecording().toImage(_width, height.ceil());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

Paint _tilePaint(TileAppearance tile, {double size = 112}) => Paint()
  ..shader = tileShader(
    motif: tile.motif,
    background: tile.background,
    patternColor: tile.patternColor,
    patternColorAlt: tile.patternColorAlt,
    tile: size,
    devicePixelRatio: 1,
  );

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

void _drawHeader(Canvas canvas, AppColors colors, Retrospective r) {
  final tile = resolveTileAppearance(
    colors,
    color: TileColor.coral,
    motif: TileMotif.arco,
  );
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
  canvas.drawRect(rect, _tilePaint(tile));
  canvas.restore();

  final isYear = r.period.kind == RetroKind.year;
  _text(
    isYear ? 'MEU ANO NA COZINHA' : 'MEU MÊS NA COZINHA',
    TextStyle(
      color: tile.onColor,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 6,
    ),
  ).paint(canvas, const Offset(_margin, 110));

  _text(
    isYear ? r.period.label : r.period.label.split(' ').first,
    AppTextStyles.display(isYear ? 220 : 170).copyWith(color: tile.onColor),
    maxWidth: _width - _margin * 2,
  ).paint(canvas, const Offset(_margin, 170));

  if (!isYear) {
    _text(
      '${r.period.start.year}',
      TextStyle(
        color: tile.onColor.withValues(alpha: 0.9),
        fontSize: 52,
        fontWeight: FontWeight.w600,
      ),
    ).paint(canvas, const Offset(_margin, 372));
  }
}

void _drawBigNumber(
    Canvas canvas, AppColors colors, Retrospective r, double y) {
  final panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(_margin, y, _width - _margin * 2, _bigHeight),
    const Radius.circular(54),
  );
  canvas.drawRRect(panel, Paint()..color = colors.ink);

  final number = _text(
    '${r.cookCount}',
    AppTextStyles.display(250).copyWith(color: colors.lime, height: 0.95),
  );
  number.paint(canvas, Offset(_margin + 56, y + 40));

  final label = _text(
    r.cookCount == 1 ? 'vez que você\ncozinhou' : 'vezes que você\ncozinhou',
    TextStyle(
      color: colors.onSaturated,
      fontSize: 48,
      fontWeight: FontWeight.w600,
      height: 1.15,
    ),
    maxWidth: _width - _margin * 2 - number.width - 56 * 3,
    maxLines: 3,
  );
  label.paint(
    canvas,
    Offset(
      _margin + 56 + number.width + 36,
      y + (_bigHeight - label.height) / 2,
    ),
  );
}

void _drawStats(Canvas canvas, AppColors colors, Retrospective r, double y) {
  final cells = <(String, String)>[
    (
      'TEMPO NO FOGÃO',
      r.totalMinutes > 0 ? formatCookingTime(r.totalMinutes) : '—',
    ),
    ('RECEITAS DIFERENTES', '${r.distinctRecipes}'),
    (
      'MAIOR SEQUÊNCIA',
      r.bestStreak == 1 ? '1 dia' : '${r.bestStreak} dias',
    ),
    (
      'DIA FAVORITO',
      r.busiestWeekday == null ? '—' : retroWeekdayName(r.busiestWeekday!),
    ),
  ];
  const cellWidth = (_width - _margin * 2 - _gap) / 2;
  for (var i = 0; i < cells.length; i++) {
    final col = i % 2;
    final row = i ~/ 2;
    final rect = Rect.fromLTWH(
      _margin + col * (cellWidth + _gap),
      y + row * (_statHeight + _gap),
      cellWidth,
      _statHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(54)),
      Paint()..color = colors.paperSoft,
    );
    _text(
      cells[i].$1,
      TextStyle(
        color: colors.textMuted,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
      maxWidth: cellWidth - 80,
    ).paint(canvas, Offset(rect.left + 40, rect.top + 40));
    _text(
      cells[i].$2,
      AppTextStyles.display(78).copyWith(color: colors.ink),
      maxWidth: cellWidth - 80,
    ).paint(canvas, Offset(rect.left + 40, rect.top + 100));
  }
}

void _drawTopRecipe(
  Canvas canvas,
  AppColors colors,
  Retrospective r,
  double y,
) {
  final top = r.topRecipe!;
  final tile = resolveTileAppearance(
    colors,
    color: top.tileColor,
    motif: top.tileMotif,
    seedId: top.id,
  );
  final rect = RRect.fromRectAndRadius(
    Rect.fromLTWH(_margin, y, _width - _margin * 2, _topHeight),
    const Radius.circular(54),
  );
  canvas.save();
  canvas.clipRRect(rect, doAntiAlias: true);
  canvas.drawRect(rect.outerRect, _tilePaint(tile, size: 96));
  canvas.restore();

  _text(
    'RECEITA CAMPEÃ',
    TextStyle(
      color: tile.onColor,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 5,
    ),
  ).paint(canvas, Offset(_margin + 48, y + 44));

  TextPainter? name;
  for (final size in const [78.0, 66.0, 56.0, 48.0]) {
    name = _text(
      top.name,
      AppTextStyles.display(size).copyWith(color: tile.onColor, height: 1),
      maxWidth: _width - _margin * 2 - 96,
      maxLines: 2,
    );
    if (!name.didExceedMaxLines) break;
  }
  name!.paint(canvas, Offset(_margin + 48, y + 100));

  final detail = StringBuffer(
    top.times == 1 ? 'feita 1 vez' : 'feita ${top.times} vezes',
  );
  if (r.topTag != null) detail.write('  ·  tag favorita: ${r.topTag!.name}');
  _text(
    detail.toString(),
    TextStyle(
      color: tile.onColor.withValues(alpha: 0.92),
      fontSize: 38,
      fontWeight: FontWeight.w600,
    ),
    maxWidth: _width - _margin * 2 - 96,
  ).paint(canvas, Offset(_margin + 48, y + _topHeight - 84));
}

void _drawFooter(Canvas canvas, AppColors colors, double y) {
  final brand = _text(
    'Receyta',
    AppTextStyles.display(76).copyWith(color: colors.ink),
    maxWidth: _width.toDouble(),
    align: TextAlign.center,
  );
  brand.paint(canvas, Offset((_width - brand.width) / 2, y));
  final tagline = _text(
    'Suas receitas, num lugar só',
    TextStyle(
      color: colors.textMuted,
      fontSize: 36,
      fontWeight: FontWeight.w500,
    ),
    maxWidth: _width.toDouble(),
    align: TextAlign.center,
  );
  tagline.paint(canvas, Offset((_width - tagline.width) / 2, y + 92));
}
