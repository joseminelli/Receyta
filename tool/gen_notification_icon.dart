// Gera o ícone pequeno das notificações do Android (silhueta branca sobre
// fundo transparente) a partir do logo da marca, em todas as densidades.
//
//   dart run tool/gen_notification_icon.dart
//
// O Android pinta o ícone da barra de status só pelo canal de transparência;
// um logo colorido viraria um bloco. Aqui o formato do logo vira o alfa e a cor
// vira branco. Saída: android/app/src/main/res/drawable-*/ic_stat_receyta.png.
import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'assets/brand/logoIcon.png';
const _name = 'ic_stat_receyta.png';

/// Lado do ícone (24 dp) em cada densidade.
const _sizes = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

/// Fração do lado que a arte ocupa (o resto é respiro, como no guia do
/// Android: 24 dp de tela, ~20 dp de desenho).
const _fill = 0.86;

void main() {
  final bytes = File(_source).readAsBytesSync();
  final source = img.decodePng(bytes);
  if (source == null) {
    stderr.writeln('Não consegui ler $_source');
    exit(1);
  }

  var transparent = 0;
  for (final p in source) {
    if (p.a < 255) transparent++;
  }
  final hasAlpha = transparent > source.width * source.height * 0.01;
  stdout.writeln(
    '$_source: ${source.width}x${source.height}, '
    '${hasAlpha ? 'com' : 'SEM'} transparência '
    '(${(100 * transparent / (source.width * source.height)).toStringAsFixed(1)}% transparente)',
  );

  for (final entry in _sizes.entries) {
    final side = entry.value;
    final art = (side * _fill).round();
    final scale = art / (source.width > source.height ? source.width : source.height);
    final w = (source.width * scale).round().clamp(1, side);
    final h = (source.height * scale).round().clamp(1, side);
    final resized = img.copyResize(
      source,
      width: w,
      height: h,
      interpolation: img.Interpolation.average,
    );

    final canvas = img.Image(width: side, height: side, numChannels: 4);
    final ox = (side - w) ~/ 2;
    final oy = (side - h) ~/ 2;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = resized.getPixel(x, y);
        // Com transparência, o alfa do logo manda. Sem ela (fundo branco
        // chapado), o que não é branco vira a silhueta.
        final alpha = hasAlpha
            ? p.a.toInt()
            : (255 - (p.r.toInt() + p.g.toInt() + p.b.toInt()) ~/ 3);
        canvas.setPixelRgba(ox + x, oy + y, 255, 255, 255, alpha.clamp(0, 255));
      }
    }

    final dir = Directory('android/app/src/main/res/drawable-${entry.key}')
      ..createSync(recursive: true);
    File('${dir.path}/$_name').writeAsBytesSync(img.encodePng(canvas));
    stdout.writeln('  drawable-${entry.key}/$_name  ${side}x$side (arte ${w}x$h)');
  }
}
