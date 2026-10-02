import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:receyta/data/services/auto_backup_service.dart';
import 'package:receyta/features/recipes/screens/receyta_import_flow.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// As cópias automáticas guardadas no aparelho: restaurar, enviar pra fora
/// (Drive, WhatsApp…), apagar, ou fazer uma agora.
Future<void> showAutoBackupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.paper,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _AutoBackupSheet(),
  );
}

final _copiesProvider = FutureProvider.autoDispose<List<AutoBackupFile>>((ref) {
  ref.watch(autoBackupProvider);
  return ref.read(autoBackupServiceProvider).list();
});

String formatBackupDate(DateTime at, {DateTime? now}) {
  final l = at.toLocal();
  final n = (now ?? DateTime.now());
  String two(int v) => v.toString().padLeft(2, '0');
  final time = '${two(l.hour)}:${two(l.minute)}';
  final sameDay = l.year == n.year && l.month == n.month && l.day == n.day;
  if (sameDay) return 'Hoje, $time';
  final y = n.subtract(const Duration(days: 1));
  if (l.year == y.year && l.month == y.month && l.day == y.day) {
    return 'Ontem, $time';
  }
  return '${two(l.day)}/${two(l.month)}/${l.year}, $time';
}

String _size(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).ceil()} KB'
    : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';

class _AutoBackupSheet extends ConsumerWidget {
  const _AutoBackupSheet();

  Future<void> _backupNow(WidgetRef ref) async {
    final result = await ref.read(autoBackupProvider.notifier).backupNow();
    result.when(
      ok: (file) => showAppSnackBar(
        message: file == null
            ? 'Nada pra guardar ainda: crie uma receita primeiro'
            : 'Cópia feita',
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    AutoBackupFile file,
  ) async {
    Navigator.of(context).pop();
    await importSharedReceytaFileFlow(ref, file.path);
  }

  Future<void> _send(AutoBackupFile file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: 'Backup do Receyta');
    } catch (_) {
      showAppSnackBar(
        message: 'Não consegui abrir o compartilhamento',
        variant: AppSnackBarVariant.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = Theme.of(context).textTheme;
    final copies = ref.watch(_copiesProvider).valueOrNull ?? const [];

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
            Text('Cópias automáticas', style: texts.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'O app guarda uma cópia por dia, as 7 mais recentes. Restaurar '
              'junta com o que você tem; receitas iguais perguntam o que '
              'fazer.',
              style: texts.bodyMedium?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            if (copies.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Nenhuma cópia ainda.',
                  textAlign: TextAlign.center,
                  style: texts.bodyMedium?.copyWith(color: colors.textMuted),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in copies)
                      _CopyRow(
                        file: c,
                        onRestore: () => _restore(context, ref, c),
                        onSend: () => _send(c),
                        onDelete: () =>
                            ref.read(autoBackupProvider.notifier).delete(c),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            PillButton(
              label: 'Fazer uma cópia agora',
              onPressed: () => _backupNow(ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.file,
    required this.onRestore,
    required this.onSend,
    required this.onDelete,
  });

  final AutoBackupFile file;
  final VoidCallback onRestore;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatBackupDate(file.createdAt),
                  style:
                      texts.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  _size(file.bytes),
                  style: texts.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Enviar essa cópia',
            icon: const Icon(Icons.ios_share),
            onPressed: onSend,
          ),
          IconButton(
            tooltip: 'Apagar essa cópia',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
          FilledButton(onPressed: onRestore, child: const Text('Restaurar')),
        ],
      ),
    );
  }
}
