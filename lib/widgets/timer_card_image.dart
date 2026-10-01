import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tamanho (px) do card da notificação: 2:1, que é a proporção que o Android
/// reserva pra imagem grande de uma notificação expandida.
const timerCardWidth = 1024;
const timerCardHeight = 512;

/// Desenha, fora da árvore de widgets, o card que a notificação de timer
/// mostra expandida — a mesma linguagem do card da receita no plano: bloco com
/// a cor e a textura da receita, o nome grande por cima e, à direita, a
/// pílula clara com sombra (aqui com o rótulo do timer). Devolve o PNG, com
/// cantos transparentes.
///
/// Desenhar em código (e não montar um layout nativo) é o que garante a
/// Bricolage, a textura de arcos/luas e as mesmas cores do app. O relógio ao
/// vivo continua sendo do Android (cronômetro regressivo da notificação).
Future<Uint8List?> renderTimerCardPng({
  required String recipeId,
  required String name,
  required String label,
  TileColor? tileColor,
  TileMotif? tileMotif,
}) async {
  const w = timerCardWidth;
  const h = timerCardHeight;
  const colors = AppColors.light;
  const radius = 64.0;

  final tile = resolveTileAppearance(
    colors,
    color: tileColor,
    motif: tileMotif,
    seedId: recipeId,
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  canvas.clipRRect(
    RRect.fromRectAndRadius(full, const Radius.circular(radius)),
    doAntiAlias: true,
  );

  // Bloco com a textura da receita (módulo grande: a imagem é reduzida na tela).
  canvas.drawRect(
    full,
    Paint()
      ..shader = tileShader(
        motif: tile.motif,
        background: tile.background,
        patternColor: tile.patternColor,
        patternColorAlt: tile.patternColorAlt,
        tile: 128,
        devicePixelRatio: 1,
      ),
  );

  // Pílula clara à direita, por cima do bloco, com sombra.
  const panelLeft = w * 0.64;
  final panel = RRect.fromRectAndCorners(
    Rect.fromLTRB(panelLeft, 0, w.toDouble(), h.toDouble()),
    topLeft: const Radius.circular(radius),
    bottomLeft: const Radius.circular(radius),
  );
  canvas.drawRRect(
    panel.shift(const Offset(-8, 0)),
    Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
  );
  canvas.drawRRect(panel, Paint()..color = colors.paperSoft);

  // Nome da receita no bloco: o maior tamanho que cabe em até 4 linhas.
  const nameLeft = 64.0;
  final nameWidth = panelLeft - nameLeft - 56;
  TextPainter? namePainter;
  for (final size in const [92.0, 80.0, 68.0, 58.0, 50.0, 44.0]) {
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: AppTextStyles.display(size).copyWith(
          color: tile.onColor,
          height: 1.02,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    )..layout(maxWidth: nameWidth);
    namePainter = painter;
    if (!painter.didExceedMaxLines) break;
  }
  namePainter!.paint(
    canvas,
    Offset(nameLeft, (h - namePainter.height) / 2),
  );

  // Conteúdo da pílula: ícone, "TIMER" e o rótulo (Passo 2, Cozimento...).
  final panelCenterX = panelLeft + (w - panelLeft) / 2;
  final panelInner = w - panelLeft - 72;

  final icon = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.timer_outlined.codePoint),
      style: TextStyle(
        fontFamily: Icons.timer_outlined.fontFamily,
        package: Icons.timer_outlined.fontPackage,
        fontSize: 132,
        color: colors.ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final caption = TextPainter(
    text: TextSpan(
      text: 'TIMER',
      style: AppTextStyles.display(30).copyWith(
        color: colors.textMuted,
        letterSpacing: 6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  TextPainter? labelPainter;
  for (final size in const [56.0, 48.0, 40.0, 34.0]) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: AppTextStyles.display(size).copyWith(color: colors.ink),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: panelInner);
    labelPainter = painter;
    if (!painter.didExceedMaxLines) break;
  }

  final stackHeight =
      icon.height + 8 + caption.height + 16 + labelPainter!.height;
  var y = (h - stackHeight) / 2;
  icon.paint(canvas, Offset(panelCenterX - icon.width / 2, y));
  y += icon.height + 8;
  caption.paint(canvas, Offset(panelCenterX - caption.width / 2, y));
  y += caption.height + 16;
  labelPainter.paint(
    canvas,
    Offset(panelCenterX - labelPainter.width / 2, y),
  );

  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List();
}
