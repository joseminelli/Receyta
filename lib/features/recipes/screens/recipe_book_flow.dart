import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/subscription/controllers/cloud_access_controller.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// O livro de receitas em PDF é do Receyta Plus: sem ele, explica e leva à
/// página do plano. Devolve `true` se pode seguir.
Future<bool> _ensurePlus(BuildContext context, WidgetRef ref) async {
  if (ref.read(hasCloudAccessProvider)) return true;
  final go = await AppDialog.confirm(
    context,
    icon: Icons.menu_book_outlined,
    accent: context.colors.onPaper,
    title: 'Livro de receitas é do Plus',
    message: 'Junte as receitas de uma pasta ou tag num PDF bonito, com capa, '
        'sumário e as fotos. Vem com o Receyta Plus.',
    confirmLabel: 'Ver o Plus',
  );
  if (go && context.mounted) context.push('/plus');
  return false;
}

Future<void> _generate(
  WidgetRef ref, {
  required String title,
  required List<String> recipeIds,
}) async {
  if (recipeIds.isEmpty) {
    showAppSnackBar(
      title: 'Livro vazio',
      message: 'Escolha uma pasta ou tag que tenha receitas.',
      variant: AppSnackBarVariant.info,
    );
    return;
  }
  final toast = showAppLoading('Montando o livro');
  final result = await ref
      .read(recipeExportServiceProvider)
      .shareBookPdf(title: title, recipeIds: recipeIds);
  final count = recipeIds.length;
  result.when(
    ok: (_) => toast?.success(
      'Livro pronto',
      description: 'PDF com $count ${count == 1 ? 'receita' : 'receitas'}, '
          'pronto para compartilhar.',
    ),
    err: (f) =>
        toast?.error('Não consegui montar o livro', description: f.message),
  );
}

/// Livro com as receitas de [folder] e de todas as subpastas dela.
Future<void> exportFolderBook(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  if (!await _ensurePlus(context, ref)) return;
  final folders = await ref.read(folderRepositoryProvider).watchAll().first;
  final ids = {folder.id};
  var grew = true;
  while (grew) {
    grew = false;
    for (final f in folders) {
      if (f.parentId != null && ids.contains(f.parentId) && ids.add(f.id)) {
        grew = true;
      }
    }
  }
  final recipes = await ref.read(recipeRepositoryProvider).watchAll().first;
  await _generate(
    ref,
    title: folder.name,
    recipeIds: [
      for (final r in recipes)
        if (ids.contains(r.folderId)) r.id,
    ],
  );
}

/// Livro com as receitas que têm a tag [tagId].
Future<void> exportTagBook(
  BuildContext context,
  WidgetRef ref, {
  required String tagId,
  required String tagName,
}) async {
  if (!await _ensurePlus(context, ref)) return;
  final recipes = await ref
      .read(recipeRepositoryProvider)
      .watchAll(anyOfTagIds: {tagId}).first;
  await _generate(
    ref,
    title: tagName,
    recipeIds: [for (final r in recipes) r.id],
  );
}
