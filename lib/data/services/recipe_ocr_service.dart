import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/domain/engine/ocr_recipe_import.dart';
import 'package:receyta/domain/engine/recipe_import.dart';

/// Tira/escolhe uma foto, roda OCR on-device (C8, RF-06.10) e monta um
/// rascunho pro formulário. A foto só existe em memória/arquivo temporário
/// durante o reconhecimento — o arquivo é apagado assim que termina, nunca
/// fica salvo (guardar a foto da receita em si é outro recurso, o H0).
class RecipeOcrService {
  RecipeOcrService({ImagePicker? picker, TextRecognizer? recognizer})
      : _picker = picker ?? ImagePicker(),
        _recognizer =
            recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final ImagePicker _picker;
  final TextRecognizer _recognizer;

  Future<Result<ImportedRecipe>> importFromPhoto(ImageSource source) async {
    XFile? file;
    try {
      file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) {
        return const Err(ValidationFailure('Nenhuma foto escolhida.'));
      }

      final recognized =
          await _recognizer.processImage(InputImage.fromFilePath(file.path));
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
      if (file != null) {
        try {
          final f = File(file.path);
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

final recipeOcrServiceProvider = Provider<RecipeOcrService>((ref) {
  final service = RecipeOcrService();
  ref.onDispose(service.dispose);
  return service;
});
