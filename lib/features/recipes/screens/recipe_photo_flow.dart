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
  required bool hasPhoto,
}) async {
  final choice = await _showSheet(context, hasPhoto: hasPhoto);
  if (choice == null) return null;
  if (choice == _PhotoChoice.remove) return (imagePath: null);

  final result = await ref.read(recipeImageServiceProvider).pick(
        choice == _PhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
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
    hasPhoto: recipe.imagePath != null,
  );
  if (change == null) return;

  final saved = await ref
      .read(recipeRepositoryProvider)
      .setImage(recipe.id, change.imagePath);
  saved.when(
    ok: (_) {
      _releaseLocal(ref, recipe.imagePath, exceptRecipeId: recipe.id);
      unawaited(ref.read(recipeImageSyncProvider).syncPending());
    },
    err: (f) {
      _releaseLocal(ref, change.imagePath, exceptRecipeId: recipe.id);
      showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error);
    },
  );
}

/// Apaga o arquivo local de [name] se nenhuma outra receita o usa (fotos
/// iguais são o mesmo arquivo).
void _releaseLocal(WidgetRef ref, String? name, {String? exceptRecipeId}) {
  if (name == null) return;
  final repo = ref.read(recipeRepositoryProvider);
  unawaited(ref.read(recipeImageServiceProvider).deleteIfUnused(
        name,
        (n) => repo.isImageInUse(n, exceptRecipeId: exceptRecipeId),
      ));
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
