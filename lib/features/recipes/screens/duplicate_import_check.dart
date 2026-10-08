import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/duplicate_check_service.dart';
import 'package:receyta/domain/engine/duplicate_detector.dart';
import 'package:receyta/domain/engine/recipe_import.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Antes de abrir o formulário de um import, avisa se a pessoa já tem uma
/// receita parecida. `true` = pode seguir com o import (não achou nada, ou
/// ela quis importar mesmo assim); `false` = parou aqui (cancelou, ou foi
/// ver a que já tem).
Future<bool> confirmNotDuplicate(
  BuildContext context,
  WidgetRef ref,
  ImportedRecipe draft,
) async {
  final match = await ref.read(duplicateCheckServiceProvider).check(draft);
  if (match == null || !context.mounted) return true;

  final choice = await AppDialog.show<_Choice>(
    context,
    icon: Icons.content_copy_outlined,
    accent: context.colors.coral,
    title: 'Você já tem uma parecida',
    message: '"${match.name}" ${_why(match.reason)}.',
    actions: [
      PillButton(
        label: 'Importar mesmo assim',
        variant: PillButtonVariant.ghost,
        dense: true,
        onPressed: () => Navigator.of(context).pop(_Choice.import),
      ),
      PillButton(
        label: 'Ver a minha',
        dense: true,
        onPressed: () => Navigator.of(context).pop(_Choice.view),
      ),
    ],
  );

  if (choice == _Choice.import) return true;
  if (choice == _Choice.view && context.mounted) {
    context.push('/recipe/${match.recipeId}');
  }
  return false;
}

enum _Choice { import, view }

String _why(DuplicateReason reason) => switch (reason) {
      DuplicateReason.sameLink => 'veio deste mesmo link',
      DuplicateReason.sameName => 'tem quase o mesmo nome',
      DuplicateReason.sameIngredients => 'tem ingredientes quase iguais',
    };
