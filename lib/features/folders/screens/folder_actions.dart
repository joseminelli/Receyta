import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/domain/models/folder.dart';
import 'package:receyta/features/folders/screens/folder_picker.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_style_picker.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Diálogo de nome de pasta — serve pra criar ("Nova pasta") e renomear.
/// Devolve o texto confirmado, ou nulo se cancelou.
Future<String?> promptFolderName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Salvar',
}) {
  final controller = TextEditingController(text: initial);
  return AppDialog.show<String>(
    context,
    icon: Icons.folder_outlined,
    accent: context.colors.violet,
    title: title,
    content: TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Nome da pasta'),
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
        label: action,
        dense: true,
        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    ],
  );
}

/// Cria uma pasta (opcionalmente dentro de [parentId]) perguntando o nome.
Future<void> createFolderFlow(
  BuildContext context,
  WidgetRef ref, {
  String? parentId,
}) async {
  final name = await promptFolderName(
    context,
    title: parentId == null ? 'Nova pasta' : 'Nova subpasta',
    action: 'Criar',
  );
  if (name == null || name.isEmpty) return;
  final result = await ref
      .read(folderRepositoryProvider)
      .create(name: name, parentId: parentId);
  _reportError(result);
}

/// Renomeia [folder] perguntando o novo nome.
Future<void> renameFolderFlow(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final name = await promptFolderName(
    context,
    title: 'Renomear pasta',
    initial: folder.name,
  );
  if (name == null || name.isEmpty || name == folder.name) return;
  final result =
      await ref.read(folderRepositoryProvider).rename(folder.id, name);
  _reportError(result);
}

/// Confirma a exclusão de [folder]. O conteúdo (subpastas e receitas) sobe pro
/// nível de cima — nada é apagado. Devolve `true` se excluiu.
Future<bool> deleteFolderFlow(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final confirmed = await AppDialog.confirm(
    context,
    icon: Icons.delete_outline,
    accent: context.colors.danger,
    title: 'Excluir "${folder.name}"?',
    message: 'As receitas e subpastas dela sobem um nível — nada é apagado.',
    confirmLabel: 'Excluir',
  );
  if (!confirmed) return false;
  final result = await ref.read(folderRepositoryProvider).delete(folder.id);
  _reportError(result);
  return result.isOk;
}

/// Move [folder] pra outra pasta (ou raiz) via o seletor de pastas.
Future<void> moveFolderFlow(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) async {
  final choice = await pickFolder(
    context,
    ref,
    currentId: folder.parentId,
    excludeSubtreeOf: folder.id,
  );
  if (choice == null || choice.id == folder.parentId) return;
  final result =
      await ref.read(folderRepositoryProvider).move(folder.id, choice.id);
  _reportError(result);
}

/// Move uma receita pra uma pasta (ou raiz) via o seletor de pastas.
Future<void> moveRecipeFlow(
  BuildContext context,
  WidgetRef ref,
  String recipeId,
  String? currentFolderId,
) async {
  final choice = await pickFolder(context, ref, currentId: currentFolderId);
  if (choice == null || choice.id == currentFolderId) return;
  final result =
      await ref.read(folderRepositoryProvider).moveRecipe(recipeId, choice.id);
  _reportError(result);
  if (result.isOk) {
    showAppSnackBar(message: 'Receita movida');
  }
}

/// Sheet de aparência da pasta (§9.4) — aplica cada toque na hora, com prévia.
Future<void> folderAppearanceFlow(
  BuildContext context,
  WidgetRef ref,
  Folder folder,
) {
  return showAppearanceSheet(
    context,
    title: 'Aparência de "${folder.name}"',
    color: folder.tileColor,
    motif: folder.tileMotif,
    fallbackColor: TileColor.violet,
    onChanged: (c, m) => ref
        .read(folderRepositoryProvider)
        .setAppearance(folder.id, color: c, motif: m),
  );
}

/// Menu ⋯ da tela da pasta: renomear, aparência, mover, nova subpasta, excluir.
Future<void> showFolderMenu(
  BuildContext context,
  WidgetRef ref,
  Folder folder, {
  required VoidCallback onDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => AppSheetFrame(
      title: folder.name,
      child: AppSheetOptions(
        children: [
          AppSheetOption(
            icon: Icons.drive_file_rename_outline,
            title: 'Renomear',
            onTap: () {
              Navigator.of(sheet).pop();
              renameFolderFlow(context, ref, folder);
            },
          ),
          AppSheetOption(
            icon: Icons.palette_outlined,
            title: 'Aparência',
            onTap: () {
              Navigator.of(sheet).pop();
              folderAppearanceFlow(context, ref, folder);
            },
          ),
          AppSheetOption(
            icon: Icons.drive_file_move_outline,
            title: 'Mover pasta',
            onTap: () {
              Navigator.of(sheet).pop();
              moveFolderFlow(context, ref, folder);
            },
          ),
          AppSheetOption(
            icon: Icons.create_new_folder_outlined,
            title: 'Nova subpasta',
            onTap: () {
              Navigator.of(sheet).pop();
              createFolderFlow(context, ref, parentId: folder.id);
            },
          ),
          AppSheetOption(
            icon: Icons.delete_outline,
            title: 'Excluir pasta',
            danger: true,
            onTap: () async {
              Navigator.of(sheet).pop();
              final deleted = await deleteFolderFlow(context, ref, folder);
              if (deleted) onDeleted();
            },
          ),
        ],
      ),
    ),
  );
}

void _reportError(Result<Object?> result) {
  result.when(
    ok: (_) {},
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}
