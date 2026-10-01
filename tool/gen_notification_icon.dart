// Gera o ícone pequeno das notificações do Android (silhueta branca sobre
// fundo transparente) a partir do logo da marca, em todas as densidades.
//
//   dart run tool/gen_notification_icon.dart
//
// Gera também a imagem grande das notificações (`ic_notification_large.png`):
// o cloche em branco sobre o laranja da marca com a textura de arcos.
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

const _coral = [0xFF, 0x5A, 0x38]; // AppColors.coral
const _coralPattern = [0xFF, 0x7A, 0x5E]; // AppColors.coralPattern

/// Imagem grande da notificação: azulejo `arco` do app (quartos de círculo
/// ancorados no canto de cada módulo) em coral, cloche branco no meio, cantos
/// arredondados.
void _generateLargeIcon(img.Image logo, bool hasAlpha) {
  const size = 256;
  const tile = 64; // módulo do padrão
  const corner = 44; // raio dos cantos
  final canvas = img.Image(width: size, height: size, numChannels: 4);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // Cantos arredondados: fora do retângulo arredondado fica transparente.
      final dx = x < corner
          ? corner - x
          : (x >= size - corner ? x - (size - corner - 1) : 0);
      final dy = y < corner
          ? corner - y
          : (y >= size - corner ? y - (size - corner - 1) : 0);
      if (dx * dx + dy * dy > corner * corner) continue;

      final tx = x % tile;
      final ty = y % tile;
      final inArc = tx * tx + ty * ty <= tile * tile;
      final c = inArc ? _coralPattern : _coral;
      canvas.setPixelRgba(x, y, c[0], c[1], c[2], 255);
    }
  }

  // Cloche em branco, ~58% da largura, centrado (um pouco acima do meio).
  final w = (size * 0.58).round();
  final h = (logo.height * w / logo.width).round();
  final cloche = img.copyResize(
    logo,
    width: w,
    height: h,
    interpolation: img.Interpolation.average,
  );
  final ox = (size - w) ~/ 2;
  final oy = (size - h) ~/ 2;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = cloche.getPixel(x, y);
      final a = hasAlpha
          ? p.a.toInt()
          : (255 - (p.r.toInt() + p.g.toInt() + p.b.toInt()) ~/ 3);
      if (a <= 0) continue;
      final under = canvas.getPixel(ox + x, oy + y);
      final t = a / 255;
      canvas.setPixelRgba(
        ox + x,
        oy + y,
        (under.r * (1 - t) + 255 * t).round(),
        (under.g * (1 - t) + 255 * t).round(),
        (under.b * (1 - t) + 255 * t).round(),
        255,
      );
    }
  }

  final dir = Directory('android/app/src/main/res/drawable-nodpi')
    ..createSync(recursive: true);
  File('${dir.path}/ic_notification_large.png')
      .writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('  drawable-nodpi/ic_notification_large.png  ${size}x$size');
}

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
    final scale =
        art / (source.width > source.height ? source.width : source.height);
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
    stdout.writeln(
        '  drawable-${entry.key}/$_name  ${side}x$side (arte ${w}x$h)');
  }

  _generateLargeIcon(source, hasAlpha);
}
