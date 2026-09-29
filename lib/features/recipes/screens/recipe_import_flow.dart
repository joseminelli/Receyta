import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/services/recipe_import_service.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Pergunta a URL, busca e abre o formulário já preenchido pra revisão
/// (C7). Nunca salva sozinho — o usuário sempre confere antes de tocar em
/// salvar, igual à digitação manual.
Future<void> importRecipeFromUrlFlow(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController();
  final url = await AppDialog.show<String>(
    context,
    icon: Icons.link,
    accent: context.colors.violet,
    title: 'Importar de um link',
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      decoration: const InputDecoration(hintText: 'https://...'),
      onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
    ),
    actions: [
      PillButton(
        label: 'Cancelar',
        variant: PillButtonVariant.ghost,
        dense: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      PillButton(
        label: 'Importar',
        dense: true,
        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    ],
  );
  if (url == null || url.isEmpty) return;

  showAppSnackBar(message: 'Buscando a receita...');

  final result = await ref.read(recipeImportServiceProvider).importFromUrl(url);
  if (!context.mounted) return;

  result.when(
    ok: (recipe) => context.push('/recipe/new', extra: recipe),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}
