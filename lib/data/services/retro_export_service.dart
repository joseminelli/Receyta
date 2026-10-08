import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/retrospective.dart';
import 'package:receyta/widgets/retro_card_image.dart';

/// Compartilha a retrospectiva como imagem: desenha o cartão (ver
/// [renderRetroCardPng]), grava um PNG temporário e abre o menu de
/// compartilhar do celular com ele já anexado.
class RetroExportService {
  /// "receyta-retrospectiva-2026-10.png" ou "receyta-retrospectiva-2026.png".
  static String fileName(RetroPeriod period) {
    final month = period.start.month.toString().padLeft(2, '0');
    return period.kind == RetroKind.month
        ? 'receyta-retrospectiva-${period.start.year}-$month.png'
        : 'receyta-retrospectiva-${period.start.year}.png';
  }

  static String caption(RetroPeriod period) =>
      'Meu ${period.inSentence} na cozinha — Receyta';

  Future<Result<void>> share(Retrospective retro) async {
    if (retro.isEmpty) {
      return const Err(ValidationFailure('Nada cozinhado nesse período.'));
    }
    try {
      final png = await renderRetroCardPng(retro);
      if (png == null) {
        return const Err(ProcessingFailure('Não deu pra gerar a imagem.'));
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${fileName(retro.period)}');
      await file.writeAsBytes(png, flush: true);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: caption(retro.period),
      );
      return const Ok(null);
    } catch (e) {
      return Err(
        ProcessingFailure('Falha ao compartilhar a retrospectiva', cause: e),
      );
    }
  }
}

final retroExportServiceProvider = Provider<RetroExportService>(
  (ref) => RetroExportService(),
);
