import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Configurações (RF-08.1), acessada pela engrenagem no topo da aba "Conta".
/// Hoje só backup e limpar dados; fonte grande/alto contraste (RF-08.2/.3)
/// entram no bloco G.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(recipeExportServiceProvider).shareFullBackup();
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  /// Confirmação dupla (RF-08.4): primeiro um aviso com o lembrete de fazer
  /// backup antes, depois uma confirmação final e seca — só apaga se as
  /// duas passarem.
  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final firstOk = await AppDialog.confirm(
      context,
      icon: Icons.warning_amber_rounded,
      accent: colors.danger,
      title: 'Limpar todos os dados?',
      message: 'Apaga receitas, pastas, tags e ingredientes salvos neste '
          'aparelho. Se ainda não fez um backup, use "Backup" antes de '
          'continuar.',
      confirmLabel: 'Continuar',
    );
    if (!firstOk) return;
    if (!context.mounted) return;

    final finalOk = await AppDialog.confirm(
      context,
      icon: Icons.delete_forever_outlined,
      accent: colors.danger,
      title: 'Tem certeza?',
      message: 'Essa ação não pode ser desfeita — os dados somem de vez.',
      confirmLabel: 'Apagar tudo',
    );
    if (!finalOk) return;

    final result = await ref.read(dataResetServiceProvider).wipeAll();
    result.when(
      ok: (_) => showAppSnackBar(message: 'Dados apagados'),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          _SettingsTile(
            icon: Icons.backup_outlined,
            iconColor: colors.violet,
            title: 'Backup',
            subtitle: 'Exporta tudo como um arquivo .receyta',
            onTap: () => _backup(context, ref),
          ),
          const SizedBox(height: AppSpacing.xs),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            iconColor: colors.danger,
            title: 'Limpar dados',
            subtitle: 'Apaga tudo salvo neste aparelho',
            onTap: () => _wipe(context, ref),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.texts.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(subtitle, style: context.texts.bodyMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
