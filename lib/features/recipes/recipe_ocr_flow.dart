import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:receyta/data/services/recipe_ocr_service.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Tira/escolhe uma foto, roda OCR on-device e abre o formulário já
/// preenchido pra revisão (C8). Nunca salva sozinho, igual ao C7 — e nunca
/// guarda a foto: ela só existe em memória durante o reconhecimento.
Future<void> importRecipeFromPhotoFlow(BuildContext context, WidgetRef ref) async {
  final source = await _pickImageSource(context);
  if (source == null) return;
  if (!context.mounted) return;

  showAppSnackBar(message: 'Lendo o texto da foto...');

  final result = await ref.read(recipeOcrServiceProvider).importFromPhoto(source);
  if (!context.mounted) return;

  result.when(
    ok: (recipe) => context.push('/recipe/new', extra: recipe),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}

Future<ImageSource?> _pickImageSource(BuildContext context) {
  final colors = context.colors;
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: colors.paper,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: colors.textMuted),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.of(sheet).pop(ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: colors.textMuted),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.of(sheet).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
