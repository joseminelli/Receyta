import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_image_service.dart';
import 'package:receyta/data/services/recipe_image_sync.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Resultado de [choosePhoto]: o nome do arquivo guardado, ou `null` pra
/// "tirar a foto". Um retorno `null` de [choosePhoto] = nada mudou.
typedef PhotoChange = ({String? imagePath});

enum _PhotoChoice { camera, gallery, remove }

/// Pergunta de onde vem a foto, guarda o arquivo (comprimido) e devolve a
/// mudança — quem chama decide quando gravar no banco (o detalhe grava na
/// hora; o formulário espera o "Salvar"). Cancelar ou falhar devolve `null`;
/// a falha aparece num snackbar.
Future<PhotoChange?> choosePhoto(
  BuildContext context,
  WidgetRef ref, {
  required String recipeId,
  required bool hasPhoto,
}) async {
  final choice = await _showSheet(context, hasPhoto: hasPhoto);
  if (choice == null) return null;
  if (choice == _PhotoChoice.remove) return (imagePath: null);

  final result = await ref.read(recipeImageServiceProvider).pick(
        choice == _PhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        recipeId: recipeId,
      );
  return result.when(
    ok: (name) => name == null ? null : (imagePath: name),
    err: (f) {
      showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);
      return null;
    },
  );
}

/// Troca ou tira a foto de uma receita já salva (menu ⋯ do detalhe): grava
/// no banco e apaga o arquivo antigo.
Future<void> changeRecipePhoto(
  BuildContext context,
  WidgetRef ref,
  Recipe recipe,
) async {
  final change = await choosePhoto(
    context,
    ref,
    recipeId: recipe.id,
    hasPhoto: recipe.imagePath != null,
  );
  if (change == null) return;

  final saved = await ref
      .read(recipeRepositoryProvider)
      .setImage(recipe.id, change.imagePath);
  saved.when(
    ok: (_) {
      ref.read(recipeImageServiceProvider).delete(recipe.imagePath);
      unawaited(ref.read(recipeImageSyncProvider).syncPending());
    },
    err: (f) {
      ref.read(recipeImageServiceProvider).delete(change.imagePath);
      showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);
    },
  );
}

Future<_PhotoChoice?> _showSheet(
  BuildContext context, {
  required bool hasPhoto,
}) {
  return showModalBottomSheet<_PhotoChoice>(
    context: context,
    builder: (sheet) => AppSheetFrame(
      title: hasPhoto ? 'Trocar a foto' : 'Foto da receita',
      subtitle: 'Fica comprimida e guardada só no seu aparelho'
          ' (e na sua conta, se estiver conectado).',
      child: AppSheetOptions(
        children: [
          AppSheetOption(
            icon: Icons.photo_camera_outlined,
            title: 'Tirar foto',
            subtitle: 'Abre a câmera agora',
            onTap: () => Navigator.of(sheet).pop(_PhotoChoice.camera),
          ),
          AppSheetOption(
            icon: Icons.photo_library_outlined,
            title: 'Escolher da galeria',
            subtitle: 'Uma foto que você já tem',
            onTap: () => Navigator.of(sheet).pop(_PhotoChoice.gallery),
          ),
          if (hasPhoto)
            AppSheetOption(
              icon: Icons.hide_image_outlined,
              title: 'Remover foto',
              subtitle: 'Volta a mostrar só o azulejo',
              danger: true,
              onTap: () => Navigator.of(sheet).pop(_PhotoChoice.remove),
            ),
        ],
      ),
    ),
  );
}
