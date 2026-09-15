import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:receyta/data/services/recipe_ocr_service.dart';
import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';

/// Tira/escolhe uma foto, roda OCR on-device e abre o formulário já
/// preenchido pra revisão (C8). Nunca salva sozinho, igual ao C7 — e nunca
/// guarda a foto: ela só existe em memória durante o reconhecimento. O OCR
/// pode demorar alguns segundos numa foto grande — por isso um loader
/// bloqueante em vez de só um aviso discreto, pra não parecer travado.
Future<void> importRecipeFromPhotoFlow(BuildContext context, WidgetRef ref) async {
  final source = await _pickImageSource(context);
  if (source == null) return;
  if (!context.mounted) return;

  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _OcrLoadingDialog(),
  );

  final result = await ref.read(recipeOcrServiceProvider).importFromPhoto(source);

  if (context.mounted) navigator.pop();
  if (!context.mounted) return;

  result.when(
    ok: (recipes) => _reviewRecipesOneByOne(context, recipes),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}

/// Abre o formulário de revisão receita por receita — uma foto só vira mais
/// de uma quando é página de livro/caderno numerado (C8). Com uma única
/// receita, pula a folha de escolha e abre direto, igual sempre foi. Com
/// várias, mostra o nome de cada uma pra escolher a próxima; a folha some
/// de vez quando não sobrar nenhuma ou se o usuário fechar sem escolher.
Future<void> _reviewRecipesOneByOne(
  BuildContext context,
  List<ImportedRecipe> recipes,
) async {
  final remaining = [...recipes];
  while (remaining.isNotEmpty) {
    if (!context.mounted) return;
    final chosen = remaining.length == 1
        ? remaining.first
        : await _pickRecipeToReview(context, remaining);
    if (chosen == null) return;
    remaining.remove(chosen);
    if (!context.mounted) return;
    await context.push('/recipe/new', extra: chosen);
  }
}

Future<ImportedRecipe?> _pickRecipeToReview(
  BuildContext context,
  List<ImportedRecipe> recipes,
) {
  final colors = context.colors;
  return showModalBottomSheet<ImportedRecipe>(
    context: context,
    backgroundColor: colors.paper,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              0,
              AppSpacing.screen,
              AppSpacing.sm,
            ),
            child: Text(
              'Achamos ${recipes.length} receitas nessa foto',
              style: sheet.texts.displaySmall,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final recipe in recipes)
                  ListTile(
                    leading: Icon(
                      Icons.restaurant_menu_outlined,
                      color: colors.textMuted,
                    ),
                    title: Text(recipe.name, style: sheet.texts.bodyLarge),
                    onTap: () =>
                        Navigator.of(sheet).pop<ImportedRecipe>(recipe),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OcrLoadingDialog extends StatelessWidget {
  const _OcrLoadingDialog();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Sem cartão `paper` por baixo — só o loader flutuando sobre o véu
    // escuro do próprio `showDialog`, por isso o texto vira branco.
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandLoader(size: 96),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Lendo o texto da foto...',
              style: context.texts.displaySmall?.copyWith(color: colors.onSaturated),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
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
