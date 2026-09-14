import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/ocr_recipe_import.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Tira/escolhe uma foto, roda OCR on-device (C8, RF-06.10) e monta um
/// rascunho pro formulário. A foto (original e a versão pré-processada) só
/// existe em arquivo temporário durante o reconhecimento — apagada assim
/// que termina, nunca fica salva (guardar a foto da receita em si é outro
/// recurso, o H0).
class RecipeOcrService {
  RecipeOcrService({ImagePicker? picker, TextRecognizer? recognizer})
      : _picker = picker ?? ImagePicker(),
        _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _picker;
  final TextRecognizer _recognizer;

  Future<Result<ImportedRecipe>> importFromPhoto(ImageSource source) async {
    XFile? file;
    File? processedFile;
    try {
      // Sem compressão: o pré-processamento abaixo precisa do máximo de
      // detalhe possível pra fazer diferença.
      file = await _picker.pickImage(source: source, imageQuality: 100);
      if (file == null) {
        return const Err(ValidationFailure('Nenhuma foto escolhida.'));
      }

      final originalBytes = await File(file.path).readAsBytes();
      // `compute` roda numa isolate separada — sem isso, a manipulação de
      // pixel (imagem grande, câmera de verdade) travaria a UI e o loader
      // na tela pararia de animar.
      final processedBytes = await compute(_preprocessForOcr, originalBytes);

      String ocrPath = file.path;
      if (processedBytes != null) {
        processedFile = File('${file.path}_ocr.jpg');
        await processedFile.writeAsBytes(processedBytes);
        ocrPath = processedFile.path;
      }

      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(ocrPath));
      final recipe = parseOcrLines(recognized.text.split('\n'));
      if (recipe == null) {
        return const Err(
          ValidationFailure('Não consegui ler texto nessa foto.'),
        );
      }
      return Ok(recipe);
    } catch (e) {
      return Err(ProcessingFailure('Falha ao processar a foto', cause: e));
    } finally {
      for (final f in [file == null ? null : File(file.path), processedFile]) {
        if (f == null) continue;
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {
          // Apagar é best-effort — o SO limpa o cache mais cedo ou mais
          // tarde de qualquer jeito; não vale falhar o import por isso.
        }
      }
    }
  }

  void dispose() => _recognizer.close();
}

/// Escala de cinza + contraste esticado pro máximo (`normalize`) — separa
/// texto de fundo antes do OCR olhar a imagem. Ajuda foto desbotada/mal
/// iluminada; não resolve fonte cursiva (isso é limite do reconhecedor em
/// si, não da imagem de entrada). `null` se a imagem não abrir — nesse caso
/// o serviço usa a foto original sem pré-processar, nunca falha por causa
/// disso.
Uint8List? _preprocessForOcr(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  var processed = img.grayscale(decoded);
  processed = img.normalize(processed, min: 0, max: 255);

  return img.encodeJpg(processed, quality: 100);
}

final recipeOcrServiceProvider = Provider<RecipeOcrService>((ref) {
  final service = RecipeOcrService();
  ref.onDispose(service.dispose);
  return service;
});
