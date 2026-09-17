import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/receyta_import_service.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Escolhe um `.receyta` no seletor do sistema e importa direto — sem
/// revisão prévia (D3): ao contrário do link (C7) e da foto (C8), aqui já
/// veio estruturado de outro Receyta, então não tem o que revisar antes de
/// salvar. `null` do serviço é o usuário cancelando a escolha do arquivo,
/// não erro.
Future<void> importReceytaFileFlow(BuildContext context, WidgetRef ref) async {
  final result =
      await ref.read(receytaImportServiceProvider).importFromPickedFile();
  if (result == null) return;
  _reportResult(result);
}

/// Mesmo caminho, mas pro `.receyta` que chegou pronto de outro app (D5) —
/// `receive_sharing_intent` já resolveu o `content://` pra um arquivo de
/// verdade antes de chamar isto. Sem `BuildContext`: dispara do `initState`
/// do `HomeShell`, a tela pode ainda nem existir.
Future<void> importSharedReceytaFileFlow(WidgetRef ref, String path) async {
  final result =
      await ref.read(receytaImportServiceProvider).importFromFilePath(path);
  _reportResult(result);
}

void _reportResult(Result<ImportSummary> result) {
  result.when(
    ok: (summary) => showAppSnackBar(
      message: summary.recipes == 1
          ? '1 receita importada'
          : '${summary.recipes} receitas importadas',
    ),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}
