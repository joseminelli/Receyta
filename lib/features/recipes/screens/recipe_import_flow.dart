import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_import_service.dart';
import 'package:receyta/data/services/recipe_link_remote.dart';
import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/domain/engine/recipe_link.dart';
import 'package:receyta/features/recipes/screens/duplicate_import_check.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Pergunta a URL, busca e abre o formulário já preenchido pra revisão
/// (C7). Nunca salva sozinho — o usuário sempre confere antes de tocar em
/// salvar, igual à digitação manual.
Future<void> importRecipeFromUrlFlow(
    BuildContext context, WidgetRef ref) async {
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
      decoration: const InputDecoration(
          hintText: 'Link de site ou de receita do Receyta'),
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

  final result = await _recipeFromAppLink(ref, url) ??
      await ref.read(recipeImportServiceProvider).importFromUrl(url);
  if (!context.mounted) return;

  final recipe = result.valueOrNull;
  if (recipe == null) {
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
    return;
  }

  if (!await confirmNotDuplicate(context, ref, recipe)) return;
  if (!context.mounted) return;

  final draft = await _withPhoto(ref, recipe);
  if (!context.mounted) return;
  context.push('/recipe/new', extra: draft);
}

/// A receita de um link de compartilhamento do app (curto ou longo), ou nulo
/// se [text] é de outro site — aí o chamador segue pro import de página.
Future<Result<ImportedRecipe>?> _recipeFromAppLink(
    WidgetRef ref, String text) async {
  final host = Uri.tryParse(text.trim())?.host.toLowerCase();
  if (host != recipeLinkHost) return null;

  final token = recipeTokenFromLink(text);
  if (token == null) {
    final recipe = recipeFromLink(text);
    return recipe == null ? null : Ok(recipe);
  }

  String? fragment;
  try {
    fragment = await ref.read(recipeLinkRemoteProvider).fetch(token);
  } catch (_) {
    return const Err(
        NetworkFailure('Sem conexão. Tente de novo quando a internet voltar.'));
  }
  final recipe = fragment == null ? null : recipeFromFragment(fragment);
  if (recipe == null) {
    return const Err(
        NotFoundFailure('Esse link de receita expirou ou não existe mais.'));
  }
  return Ok(recipe);
}

/// Baixa e guarda a foto da página, se houver. Qualquer falha devolve a
/// receita sem foto — o import não depende dela.
Future<ImportedRecipe> _withPhoto(WidgetRef ref, ImportedRecipe recipe) async {
  final url = recipe.imageUrl;
  if (url == null) return recipe;
  try {
    final bytes =
        await ref.read(recipeImportServiceProvider).downloadImage(url);
    if (bytes == null) return recipe;
    final name = await ref.read(recipeImageServiceProvider).storeBytes(bytes);
    return recipe.copyWith(imagePath: name);
  } catch (_) {
    return recipe;
  }
}
