import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Uma refeição do dia, como o cartão de imagem a desenha.
class DayCardMeal {
  const DayCardMeal({
    required this.recipeId,
    required this.recipeName,
    required this.mealLabel,
    this.tileColor,
    this.tileMotif,
    this.done = false,
  });

  final String recipeId;
  final String recipeName;
  final String mealLabel;
  final TileColor? tileColor;
  final TileMotif? tileMotif;
  final bool done;
}

const _width = 1080;
const _margin = 56.0;
const _headerHeight = 470.0;
const _rowHeight = 230.0;
const _rowGap = 32.0;
const _footerHeight = 190.0;

/// Altura final da imagem pra [meals] refeições.
double dayCardHeight(int meals) =>
    _headerHeight + _margin + meals * (_rowHeight + _rowGap) + _footerHeight;

/// Desenha, fora da árvore de widgets, o cartão do dia pra compartilhar: um
/// cabeçalho roxo com a data, uma faixa por refeição no mesmo desenho do card
/// do dia do app (bloco com a cor e a textura da receita, painel claro por
/// cima com a refeição) e a assinatura do Receyta. Devolve o PNG.
Future<Uint8List?> renderDayCardPng({
  required DateTime day,
  required List<DayCardMeal> meals,
}) async {
  const colors = AppColors.light;
  final height = dayCardHeight(meals.length);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, _width.toDouble(), height);

  canvas.drawRect(full, Paint()..color = colors.paper);

  _drawHeader(canvas, colors, day, meals.length);

  var y = _headerHeight + _margin;
  for (final meal in meals) {
    _drawMeal(canvas, colors, meal, y);
    y += _rowHeight + _rowGap;
  }

  _drawFooter(canvas, colors, y + 20);

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

void _drawHeader(Canvas canvas, AppColors colors, DateTime day, int count) {
  final tile = resolveTileAppearance(
    colors,
    color: TileColor.violet,
    motif: TileMotif.meiaLua,
  );
  final rect = Rect.fromLTWH(0, 0, _width.toDouble(), _headerHeight);
  final rrect = RRect.fromRectAndCorners(
    rect,
    bottomLeft: const Radius.circular(72),
    bottomRight: const Radius.circular(72),
  );
  canvas.save();
  canvas.clipRRect(rrect, doAntiAlias: true);
  canvas.drawRect(rect, _tilePaint(tile));
  canvas.restore();

  final eyebrow = _text(
    weekdayLong(day).toUpperCase(),
    TextStyle(
      color: tile.onColor,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 6,
    ),
  );
  eyebrow.paint(canvas, const Offset(_margin, 110));

  final date = _text(
    '${day.day} de ${monthLong(day).toLowerCase()}',
    AppTextStyles.display(150).copyWith(color: tile.onColor),
    maxWidth: _width - _margin * 2,
  );
  date.paint(canvas, const Offset(_margin, 175));

  final summary = _text(
    count == 1 ? '1 refeição' : '$count refeições',
    TextStyle(
      color: tile.onColor.withValues(alpha: 0.9),
      fontSize: 44,
      fontWeight: FontWeight.w500,
    ),
  );
  summary.paint(canvas, const Offset(_margin, 375));
}

void _drawMeal(Canvas canvas, AppColors colors, DayCardMeal meal, double y) {
  final tile = resolveTileAppearance(
    colors,
    color: meal.tileColor,
    motif: meal.tileMotif,
    seedId: meal.recipeId,
  );

  const blockWidth = 710.0;
  final block = RRect.fromRectAndRadius(
    Rect.fromLTWH(_margin, y, blockWidth, _rowHeight),
    const Radius.circular(54),
  );
  canvas.save();
  canvas.clipRRect(block, doAntiAlias: true);
  canvas.drawRect(block.outerRect, _tilePaint(tile, size: 96));
  canvas.restore();

  const nameInset = 44.0;
  const panelWidth = 330.0;
  final panelLeft = _width - _margin - panelWidth;
  final nameWidth = panelLeft - _margin - nameInset - 28;
  TextPainter? name;
  for (final size in const [68.0, 58.0, 50.0, 44.0]) {
    final candidate = _text(
      meal.recipeName,
      AppTextStyles.display(size).copyWith(color: tile.onColor, height: 1.0),
      maxWidth: nameWidth,
      maxLines: 3,
    );
    name = candidate;
    if (!candidate.didExceedMaxLines) break;
  }
  name!.paint(
    canvas,
    Offset(_margin + nameInset, y + (_rowHeight - name.height) / 2),
  );

  final panel = RRect.fromRectAndRadius(
    Rect.fromLTWH(panelLeft, y, panelWidth, _rowHeight),
    const Radius.circular(54),
  );
  canvas.drawRRect(
    panel.shift(const Offset(-6, 8)),
    Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
  );
  canvas.drawRRect(panel, Paint()..color = colors.paperSoft);

  final label = _text(
    'REFEIÇÃO',
    TextStyle(
      color: colors.textMuted,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: 4,
    ),
  );
  final mealName = _text(
    meal.mealLabel,
    AppTextStyles.display(52).copyWith(color: colors.ink),
    maxWidth: panelWidth - 64,
    maxLines: 2,
  );
  final doneLabel = meal.done
      ? _text(
          'FEITA',
          TextStyle(
            color: colors.ink,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        )
      : null;

  final stack = label.height +
      10 +
      mealName.height +
      (doneLabel == null ? 0 : 14 + doneLabel.height);
  var top = y + (_rowHeight - stack) / 2;
  label.paint(canvas, Offset(panelLeft + 32, top));
  top += label.height + 10;
  mealName.paint(canvas, Offset(panelLeft + 32, top));
  if (doneLabel != null) {
    top += mealName.height + 14;
    doneLabel.paint(canvas, Offset(panelLeft + 32, top));
  }
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
        color: colors.textMuted, fontSize: 36, fontWeight: FontWeight.w500),
    maxWidth: _width.toDouble(),
    align: TextAlign.center,
  );
  tagline.paint(canvas, Offset((_width - tagline.width) / 2, y + 92));
}

/// Um dia da semana no cartão da semana: a data e as refeições dele (vazio =
/// "Nada planejado").
class WeekCardDay {
  const WeekCardDay({required this.day, required this.meals});

  final DateTime day;
  final List<DayCardMeal> meals;
}

const _weekHeaderHeight = 400.0;
const _stripHeight = 96.0;
const _stripGap = 14.0;
const _dayMinHeight = 124.0;
const _dayGap = 26.0;

double _weekDayHeight(WeekCardDay d) => d.meals.isEmpty
    ? _dayMinHeight
    : d.meals.length * (_stripHeight + _stripGap) - _stripGap;

/// Altura final da imagem da semana pra esses [days].
double weekCardHeight(List<WeekCardDay> days) {
  var h = _weekHeaderHeight + _margin;
  for (final d in days) {
    h += _weekDayHeight(d) + _dayGap;
  }
  return h + _footerHeight - 40;
}

/// Desenha o cartão da semana pra compartilhar: cabeçalho roxo com o intervalo
/// de datas, uma linha por dia (data grande à esquerda, uma faixa fina por
/// refeição no azulejo da receita) e a assinatura do Receyta.
Future<Uint8List?> renderWeekCardPng({
  required DateTime monday,
  required List<WeekCardDay> days,
}) async {
  const colors = AppColors.light;
  final height = weekCardHeight(days);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, _width.toDouble(), height),
    Paint()..color = colors.paper,
  );

  final total = days.fold<int>(0, (n, d) => n + d.meals.length);
  _drawWeekHeader(canvas, colors, monday, total);

  var y = _weekHeaderHeight + _margin;
  for (final d in days) {
    _drawWeekDay(canvas, colors, d, y);
    y += _weekDayHeight(d) + _dayGap;
  }

  _drawFooter(canvas, colors, y - 6);

  final image = await recorder.endRecording().toImage(_width, height.ceil());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

void _drawWeekHeader(Canvas canvas, AppColors colors, DateTime monday, int n) {
  final tile = resolveTileAppearance(
    colors,
    color: TileColor.violet,
    motif: TileMotif.meiaLua,
  );
  final rect = Rect.fromLTWH(0, 0, _width.toDouble(), _weekHeaderHeight);
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

  _text(
    'SEMANA',
    TextStyle(
      color: tile.onColor,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: 6,
    ),
  ).paint(canvas, const Offset(_margin, 100));

  _text(
    weekRangeLabel(monday),
    AppTextStyles.display(124).copyWith(color: tile.onColor),
    maxWidth: _width - _margin * 2,
  ).paint(canvas, const Offset(_margin, 160));

  _text(
    n == 0 ? 'Nada planejado' : (n == 1 ? '1 refeição' : '$n refeições'),
    TextStyle(
      color: tile.onColor.withValues(alpha: 0.9),
      fontSize: 42,
      fontWeight: FontWeight.w500,
    ),
  ).paint(canvas, const Offset(_margin, 310));
}

void _drawWeekDay(Canvas canvas, AppColors colors, WeekCardDay d, double y) {
  const dateWidth = 190.0;
  final weekday = weekdayLong(d.day).substring(0, 3).toUpperCase();
  _text(
    weekday,
    TextStyle(
      color: colors.textMuted,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: 4,
    ),
  ).paint(canvas, Offset(_margin, y + 2));
  _text(
    '${d.day.day}',
    AppTextStyles.display(88).copyWith(color: colors.ink),
  ).paint(canvas, Offset(_margin, y + 38));

  const left = _margin + dateWidth;
  const stripWidth = _width - _margin - left;

  if (d.meals.isEmpty) {
    final empty = _text(
      'Nada planejado',
      TextStyle(
        color: colors.textMuted,
        fontSize: 34,
        fontWeight: FontWeight.w500,
      ),
    );
    empty.paint(canvas, Offset(left, y + (_dayMinHeight - empty.height) / 2));
    return;
  }

  var top = y;
  for (final meal in d.meals) {
    final tile = resolveTileAppearance(
      colors,
      color: meal.tileColor,
      motif: meal.tileMotif,
      seedId: meal.recipeId,
    );
    final strip = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, stripWidth, _stripHeight),
      const Radius.circular(34),
    );
    canvas.save();
    canvas.clipRRect(strip, doAntiAlias: true);
    canvas.drawRect(strip.outerRect, _tilePaint(tile, size: 72));
    canvas.restore();

    final label = _text(
      meal.mealLabel.toUpperCase(),
      TextStyle(
        color: tile.onColor,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
      ),
      maxWidth: 220,
    );
    label.paint(
      canvas,
      Offset(
        left + stripWidth - 28 - label.width,
        top + (_stripHeight - label.height) / 2,
      ),
    );

    final name = _text(
      meal.recipeName,
      AppTextStyles.display(42).copyWith(color: tile.onColor, height: 1.0),
      maxWidth: stripWidth - 56 - label.width - 24,
    );
    name.paint(
      canvas,
      Offset(left + 28, top + (_stripHeight - name.height) / 2),
    );
    top += _stripHeight + _stripGap;
  }
}
