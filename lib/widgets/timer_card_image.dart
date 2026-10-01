import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Desenha, fora da árvore de widgets, o bloco colorido do card da notificação
/// de timer: a cor e a textura que a receita tem no app, com o nome por cima
/// em Bricolage — o mesmo bloco do card do dia. O painel claro, o relógio e os
/// botões são do layout nativo (`receyta_timer_card`), que é quem anda.
///
/// A imagem é esticada pelo Android num espaço de proporção fixa, então
/// [width] e [height] precisam seguir a proporção do espaço no layout (ex.:
/// 130×120 dp → 520×480 px). [fontSizes] vai do maior ao menor: vale o
/// primeiro com o nome cabendo em [maxLines]. [cornerRadius] arredonda só os
/// cantos da esquerda; [rightInset] reserva a faixa da direita, que o painel
/// claro cobre (o nome não pode ir pra baixo dele).
Future<Uint8List?> renderTimerBlockPng({
  required String recipeId,
  required String name,
  required int width,
  required int height,
  required List<double> fontSizes,
  int maxLines = 4,
  double tile = 96,
  double cornerRadius = 0,
  double rightInset = 0,
  TileColor? tileColor,
  TileMotif? tileMotif,
}) async {
  final colors = AppColors.light;
  final appearance = resolveTileAppearance(
    colors,
    color: tileColor,
    motif: tileMotif,
    seedId: recipeId,
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  if (cornerRadius > 0) {
    canvas.clipRRect(
      RRect.fromRectAndCorners(
        full,
        topLeft: Radius.circular(cornerRadius),
        bottomLeft: Radius.circular(cornerRadius),
      ),
      doAntiAlias: true,
    );
  }
  canvas.drawRect(
    full,
    Paint()
      ..shader = tileShader(
        motif: appearance.motif,
        background: appearance.background,
        patternColor: appearance.patternColor,
        patternColorAlt: appearance.patternColorAlt,
        tile: tile,
        devicePixelRatio: 1,
      ),
  );

  final inset = width * 0.07;
  final textWidth = width - inset - rightInset;
  TextPainter? painter;
  for (final size in fontSizes) {
    final candidate = TextPainter(
      text: TextSpan(
        text: name,
        style: AppTextStyles.display(size).copyWith(
          color: appearance.onColor,
          height: 1.02,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: textWidth);
    painter = candidate;
    if (!candidate.didExceedMaxLines) break;
  }
  painter!.paint(canvas, Offset(inset, (height - painter.height) / 2));

  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}

/// Bloco do card recolhido (96×64 dp no layout nativo).
Future<Uint8List?> renderCollapsedTimerBlock({
  required String recipeId,
  required String name,
  TileColor? tileColor,
  TileMotif? tileMotif,
}) =>
    renderTimerBlockPng(
      recipeId: recipeId,
      name: name,
      width: 576,
      height: 384,
      fontSizes: const [78, 66, 56, 48],
      maxLines: 3,
      cornerRadius: 96,
      rightInset: 144,
      tileColor: tileColor,
      tileMotif: tileMotif,
    );

/// Bloco do card expandido (112×132 dp no layout nativo).
Future<Uint8List?> renderExpandedTimerBlock({
  required String recipeId,
  required String name,
  TileColor? tileColor,
  TileMotif? tileMotif,
}) =>
    renderTimerBlockPng(
      recipeId: recipeId,
      name: name,
      width: 448,
      height: 528,
      fontSizes: const [68, 58, 50, 44, 38],
      maxLines: 5,
      cornerRadius: 64,
      rightInset: 104,
      tileColor: tileColor,
      tileMotif: tileMotif,
    );
