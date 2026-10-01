import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Configurações (RF-08.1), aberta pela engrenagem da aba "Conta". Quatro
/// blocos: aparência e acessibilidade (tamanho do texto, alto contraste),
/// timers, dados (backup, atalhos, introdução) e a zona de risco.
///
/// A própria tela já reflete o tamanho do texto e o contraste escolhidos, então
/// quem muda vê o resultado na hora, sem tela de "pré-visualização".
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final result =
        await ref.read(recipeExportServiceProvider).shareFullBackup();
    result.when(
      ok: (_) => ref.read(appSettingsProvider.notifier).markBackedUp(
            DateTime.now(),
          ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final neverBackedUp = ref.read(appSettingsProvider).lastBackupAt == null;
    final firstOk = await AppDialog.confirm(
      context,
      icon: Icons.warning_amber_rounded,
      accent: colors.danger,
      title: 'Limpar todos os dados?',
      message: neverBackedUp
          ? 'Você ainda não fez um backup. Apaga receitas, pastas, tags e '
              'ingredientes deste aparelho — volte e use "Backup" antes, se '
              'quiser guardar uma cópia.'
          : 'Apaga receitas, pastas, tags e ingredientes salvos neste '
              'aparelho. Seu último backup fica com você, fora do app.',
      cancelLabel: 'Voltar',
      confirmLabel: neverBackedUp ? 'Continuar assim mesmo' : 'Continuar',
    );
    if (!firstOk || !context.mounted) return;

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

  static String _backupSubtitle(DateTime? at) {
    if (at == null) return 'Você ainda não fez backup';
    final l = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Último: ${two(l.day)}/${two(l.month)}/${l.year} às '
        '${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(appSettingsProvider);
    final alerts = ref.watch(cookingAlertSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final alertsNotifier = ref.read(cookingAlertSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: colors.paper,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemBars.onDark,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.lg,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: 'Aparência',
                    children: [
                      _TextSizeRow(
                        current: settings.textSize,
                        onSelected: settingsNotifier.setTextSize,
                      ),
                      _SwitchRow(
                        icon: Icons.contrast,
                        title: 'Alto contraste',
                        subtitle: 'Cores mais fortes e texto mais escuro',
                        value: settings.highContrast,
                        onChanged: settingsNotifier.setHighContrast,
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Timers do modo cozinha',
                    children: [
                      _SwitchRow(
                        icon: Icons.vibration,
                        title: 'Vibrar ao acabar',
                        subtitle: 'Funciona também com o app minimizado',
                        value: alerts.vibrate,
                        onChanged: alertsNotifier.setVibrate,
                      ),
                      _SwitchRow(
                        icon: Icons.volume_up_outlined,
                        title: 'Tocar som ao acabar',
                        subtitle: 'No volume de alarme do aparelho',
                        value: alerts.sound,
                        onChanged: alertsNotifier.setSound,
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Seus dados',
                    children: [
                      _NavRow(
                        icon: Icons.backup_outlined,
                        title: 'Backup',
                        subtitle: _backupSubtitle(settings.lastBackupAt),
                        warn: settings.lastBackupAt == null,
                        onTap: () => _backup(context, ref),
                      ),
                      _NavRow(
                        icon: Icons.sell_outlined,
                        title: 'Tags',
                        subtitle: 'Renomear, apagar, ver o uso',
                        onTap: () => context.push('/tags'),
                      ),
                      _NavRow(
                        icon: Icons.egg_alt_outlined,
                        title: 'Ingredientes',
                        subtitle: 'Mesclar duplicados e apagar sem uso',
                        onTap: () => context.push('/ingredients'),
                      ),
                      _NavRow(
                        icon: Icons.delete_outline,
                        title: 'Lixeira',
                        subtitle: 'Receitas apagadas, por tempo limitado',
                        onTap: () => context.push('/trash'),
                      ),
                      _NavRow(
                        icon: Icons.school_outlined,
                        title: 'Ver a introdução de novo',
                        subtitle: 'Revê as boas-vindas e o tour do app',
                        onTap: () => context.go('/welcome'),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Zona de risco',
                    children: [
                      _NavRow(
                        icon: Icons.delete_forever_outlined,
                        title: 'Limpar dados',
                        subtitle: 'Apaga tudo o que está salvo neste aparelho',
                        danger: true,
                        onTap: () => _wipe(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Receyta · seus dados ficam só neste aparelho',
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      child: Container(
        color: colors.ink,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: SizedBox(
                width: 240,
                height: 240,
                child: TilePattern(
                  motif: TileMotif.meiaLua,
                  background: colors.ink,
                  patternColor: colors.inkPattern,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Voltar',
                      background: colors.inkSoft,
                      onTap: onBack,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'AJUSTES',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.lime),
                    ),
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      'Configurações',
                      style: AppTextStyles.display(38)
                          .copyWith(color: colors.onSaturated),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: context.texts.labelSmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ),
          ),
          Material(
            color: colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: colors.paper,
                      thickness: 1.5,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: danger ? colors.danger : colors.ink,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: danger ? colors.onSaturated : colors.lime,
      ),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({
    required this.title,
    required this.subtitle,
    this.warn = false,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final bool warn;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: context.texts.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: danger ? colors.danger : colors.ink,
          ),
        ),
        Text(
          subtitle,
          style: context.texts.bodyMedium?.copyWith(
            color: warn ? colors.danger : colors.textMuted,
            fontWeight: warn ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.warn = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool warn;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _Medallion(icon: icon, danger: danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RowText(
                  title: title,
                  subtitle: subtitle,
                  warn: warn,
                  danger: danger,
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _Medallion(icon: icon),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _RowText(title: title, subtitle: subtitle)),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: colors.ink,
                  inactiveTrackColor: colors.paper,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? colors.lime
                        : colors.textMuted,
                  ),
                  trackOutlineColor: WidgetStatePropertyAll(colors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextSizeRow extends StatelessWidget {
  const _TextSizeRow({required this.current, required this.onSelected});

  final TextSizeStep current;
  final ValueChanged<TextSizeStep> onSelected;

  static const _glyphSizes = [15.0, 19.0, 23.0, 28.0];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _Medallion(icon: Icons.text_fields_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RowText(
                  title: 'Tamanho do texto',
                  subtitle: current.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (final (i, step) in TextSizeStep.values.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: step == current,
                    label: 'Texto ${step.label}',
                    excludeSemantics: true,
                    child: Material(
                      color: step == current ? colors.ink : colors.paper,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        onTap: () => onSelected(step),
                        child: SizedBox(
                          height: 60,
                          child: Center(
                            child: Text(
                              'A',
                              textScaler: TextScaler.noScaling,
                              style: AppTextStyles.display(_glyphSizes[i])
                                  .copyWith(
                                color: step == current
                                    ? colors.lime
                                    : colors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
