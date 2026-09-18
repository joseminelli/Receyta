import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/receyta_import_service.dart';
import 'package:receyta/domain/engine/receyta_file_import.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Escolhe um `.receyta` no seletor do sistema e importa — sem revisão de
/// conteúdo prévia (D3): ao contrário do link (C7) e da foto (C8), aqui já
/// veio estruturado de outro Receyta, então não tem o que revisar antes de
/// salvar. `null` do serviço é o usuário cancelando a escolha do arquivo,
/// não erro. Se alguma receita do arquivo já existe aqui (mesmo id de
/// origem), pergunta o que fazer antes de gravar (D4).
Future<void> importReceytaFileFlow(BuildContext context, WidgetRef ref) async {
  final service = ref.read(receytaImportServiceProvider);
  final result = await service.pickAndParseFile();
  if (result == null) return;
  await _resolveAndImport(service, result);
}

/// Mesmo caminho, mas pro `.receyta` que chegou pronto de outro app (D5) —
/// `receive_sharing_intent` já resolveu o `content://` pra um arquivo de
/// verdade antes de chamar isto. Sem `BuildContext` local: dispara do
/// `initState` do `HomeShell`, a tela pode ainda nem existir — por isso a
/// folha de conflito (se precisar) usa `rootNavigatorKey`, igual o
/// `showAppSnackBar`.
Future<void> importSharedReceytaFileFlow(WidgetRef ref, String path) async {
  final service = ref.read(receytaImportServiceProvider);
  final result = await service.parseFileAtPath(path);
  await _resolveAndImport(service, result);
}

Future<void> _resolveAndImport(
  ReceytaImportService service,
  Result<ParsedReceytaFile> parseResult,
) async {
  if (parseResult is Err<ParsedReceytaFile>) {
    _reportResult(Err(parseResult.failure));
    return;
  }
  final file = (parseResult as Ok<ParsedReceytaFile>).value;

  final conflicts = await service.findConflicts(file);
  var resolution = ConflictResolution.duplicate;
  if (conflicts.isNotEmpty) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final chosen = await _showConflictSheet(context, conflicts);
    if (chosen == null) return;
    resolution = chosen;
  }

  final result = await service.importParsedFile(file, resolution: resolution);
  _reportResult(result);
}

Future<ConflictResolution?> _showConflictSheet(
  BuildContext context,
  List<String> names,
) {
  return showModalBottomSheet<ConflictResolution>(
    context: context,
    backgroundColor: context.colors.paper,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _ConflictSheet(names: names),
  );
}

class _ConflictSheet extends StatelessWidget {
  const _ConflictSheet({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    final single = names.length == 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.screen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              single ? '"${names.single}" já existe' : '${names.length} receitas já existem',
              style: texts.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'O que fazer com ${single ? 'ela' : 'elas'}? A escolha vale '
              'pra todo esse arquivo.',
              style: texts.bodyMedium,
            ),
            if (!single) ...[
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final name in names)
                      Text('•  $name', style: texts.bodyMedium),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: 'Substituir',
              onPressed: () =>
                  Navigator.of(context).pop(ConflictResolution.replace),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Duplicar',
              variant: PillButtonVariant.secondary,
              onPressed: () =>
                  Navigator.of(context).pop(ConflictResolution.duplicate),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Pular',
              variant: PillButtonVariant.ghost,
              onPressed: () =>
                  Navigator.of(context).pop(ConflictResolution.skip),
            ),
          ],
        ),
      ),
    );
  }
}

void _reportResult(Result<ImportSummary> result) {
  result.when(
    ok: (summary) {
      if (summary.recipes == 0 && summary.skipped > 0) {
        showAppSnackBar(message: 'Nada importado — tudo pulado');
        return;
      }
      final imported = summary.recipes == 1
          ? '1 receita importada'
          : '${summary.recipes} receitas importadas';
      final skippedSuffix = summary.skipped > 0
          ? ' (${summary.skipped} pulada${summary.skipped == 1 ? '' : 's'})'
          : '';
      showAppSnackBar(message: '$imported$skippedSuffix');
    },
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}
