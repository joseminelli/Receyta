import 'dart:io';
import 'dart:ui' as ui;

import 'package:receyta/features/mascot/painters/mascot_painter.dart';

/// Um mascote posicionado numa composição.
class RenderItem {
  const RenderItem(this.painter, this.size, this.dx, this.dy);

  final MascotPainter painter;
  final ui.Size size;
  final double dx;
  final double dy;
}

/// Desenha os itens num canvas grande (com folga para pulos e confete) e
/// devolve a imagem.
Future<ui.Image> composeItems(List<RenderItem> items) async {
  var width = 0.0, height = 0.0;
  for (final i in items) {
    width = width > i.dx + i.size.width ? width : i.dx + i.size.width;
    height = height > i.dy + i.size.height ? height : i.dy + i.size.height;
  }
  final padSide = width * 0.5 / items.length.clamp(1, 2);
  final padTop = height * 0.38;
  final padBottom = height * 0.08;
  final w = (width + padSide * 2).ceil();
  final h = (height + padTop + padBottom).ceil();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w * 1.0, h * 1.0));
  for (final i in items) {
    canvas.save();
    canvas.translate(padSide + i.dx, padTop + i.dy);
    i.painter.paint(canvas, i.size);
    canvas.restore();
  }
  return recorder.endRecording().toImage(w, h);
}

/// Corta a imagem rente ao desenho, deixando [margin] px de folga.
Future<ui.Image> cropToContent(ui.Image image, double margin) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  var minX = image.width, minY = image.height, maxX = 0, maxY = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (bytes[(y * image.width + x) * 4 + 3] > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final src = ui.Rect.fromLTRB(
    (minX - margin).clamp(0, image.width).toDouble(),
    (minY - margin).clamp(0, image.height).toDouble(),
    (maxX + margin).clamp(0, image.width).toDouble(),
    (maxY + margin).clamp(0, image.height).toDouble(),
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    src,
    ui.Rect.fromLTWH(0, 0, src.width, src.height),
    ui.Paint(),
  );
  return recorder.endRecording().toImage(src.width.ceil(), src.height.ceil());
}

Future<void> savePng(ui.Image image, String path, {double margin = 90}) async {
  final cropped = await cropToContent(image, margin);
  final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.create(recursive: true);
  await file.writeAsBytes(png!.buffer.asUint8List());
}
