import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/services/app_info.dart';
import 'package:receyta/data/services/auth_service.dart';
import 'package:receyta/data/services/auto_backup_service.dart';
import 'package:receyta/data/services/data_reset_service.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/domain/engine/quiet_hours.dart';
import 'package:receyta/features/account/controllers/auth_controller.dart';
import 'package:receyta/features/recipes/controllers/cooking_alert_settings.dart';
import 'package:receyta/features/settings/controllers/app_settings.dart';
import 'package:receyta/features/settings/controllers/reminder_settings.dart';
import 'package:receyta/features/settings/screens/auto_backup_sheet.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Configurações (RF-08.1), aberta pela engrenagem da aba "Conta". Quatro
/// blocos: aparência e acessibilidade (tamanho do texto, alto contraste),
/// timers, dados (backup, atalhos, introdução) e a zona de risco.
///
/// A própria tela já reflete o tamanho do texto e o contraste escolhidos, então
/// quem muda vê o resultado na hora, sem tela de "pré-visualização".
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(storeLauncherProvider).open();
    if (!ok && context.mounted) {
      showAppSnackBar(
        message: 'Não foi possível abrir a loja.',
        variant: AppSnackBarVariant.error,
      );
    }
  }

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

  /// Sai da conta; as receitas continuam neste aparelho. Sem confirmação —
  /// nada é apagado, e entrar de novo leva um toque.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    AppSnackBar.show(context, message: 'Você saiu da conta.');
  }

  Future<void> _wipe(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final loggedIn = ref.read(authUserProvider).valueOrNull != null;
    final neverBackedUp = ref.read(appSettingsProvider).lastBackupAt == null;
    final firstOk = await AppDialog.confirm(
      context,
      icon: Icons.warning_amber_rounded,
      accent: colors.danger,
      title: loggedIn ? 'Limpar este aparelho?' : 'Limpar todos os dados?',
      message: [
        if (loggedIn)
          'Apaga receitas, pastas, tags, ingredientes e fotos só neste '
              'aparelho. A sua conta continua com uma cópia, e ela volta '
              'quando o app sincronizar. Para apagar também da conta, use '
              '"Apagar tudo, inclusive da conta".'
        else if (neverBackedUp)
          'Você ainda não fez um backup. Apaga receitas, pastas, tags e '
              'ingredientes deste aparelho — volte e use "Backup" antes, se '
              'quiser guardar uma cópia.'
        else
          'Apaga receitas, pastas, tags e ingredientes salvos neste '
              'aparelho. Seu último backup fica com você, fora do app.',
      ].join(' '),
      cancelLabel: 'Voltar',
      confirmLabel:
          (!loggedIn && neverBackedUp) ? 'Continuar assim mesmo' : 'Continuar',
    );
    if (!firstOk || !context.mounted) return;

    final finalOk = await AppDialog.confirm(
      context,
      icon: Icons.delete_forever_outlined,
      accent: colors.danger,
      title: 'Tem certeza?',
      message: loggedIn
          ? 'Os dados somem deste aparelho. Com a conta conectada, eles '
              'voltam na próxima sincronização.'
          : 'Essa ação não pode ser desfeita — os dados somem de vez.',
      confirmLabel: loggedIn ? 'Limpar' : 'Apagar tudo',
    );
    if (!finalOk) return;

    final result = await ref.read(dataResetServiceProvider).wipeAll();
    result.when(
      ok: (_) => showAppSnackBar(
        message: loggedIn ? 'Este aparelho foi limpo' : 'Dados apagados',
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  /// Apaga tudo: aparelho E conta. Três travas — aviso (com lembrete de
  /// backup), confirmação DIGITADA e o aviso de que não há volta — porque é a
  /// única ação do app que não dá pra desfazer de jeito nenhum.
  Future<void> _wipeEverything(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final neverBackedUp = ref.read(appSettingsProvider).lastBackupAt == null;

    final firstOk = await AppDialog.confirm(
      context,
      icon: Icons.warning_amber_rounded,
      accent: colors.danger,
      title: 'Apagar tudo, inclusive da conta?',
      message: 'Apaga receitas, pastas, tags e fotos deste aparelho E da sua '
          'conta na nuvem. Os outros aparelhos conectados também perdem tudo '
          'na próxima sincronização.\n\n'
          '${neverBackedUp ? 'Você ainda não fez um backup — volte e use '
              '"Backup" antes se quiser guardar uma cópia. ' : ''}'
          'Isso não pode ser desfeito.',
      cancelLabel: 'Voltar',
      confirmLabel: 'Continuar',
    );
    if (!firstOk || !context.mounted) return;

    final typed = await _confirmTyped(context);
    if (!typed || !context.mounted) return;

    _showProgress(context, 'Apagando tudo…');
    final result = await ref.read(dataResetServiceProvider).wipeEverything();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    result.when(
      ok: (_) => showAppSnackBar(
        message: 'Tudo foi apagado, deste aparelho e da conta',
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  /// Exclui a CONTA (login + nuvem). O que está neste aparelho continua: a
  /// pessoa segue usando o app sem conta, e pode apagar o aparelho à parte.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final firstOk = await AppDialog.confirm(
      context,
      icon: Icons.warning_amber_rounded,
      accent: colors.danger,
      title: 'Excluir minha conta?',
      message: 'Exclui a sua conta e tudo o que ela guarda na nuvem: receitas, '
          'pastas e fotos. Os outros aparelhos conectados perdem o acesso.\n\n'
          'O que está salvo neste aparelho continua aqui, e você segue '
          'usando o app sem conta. Se entrar de novo depois, será uma conta '
          'nova.\n\nIsso não pode ser desfeito.',
      cancelLabel: 'Voltar',
      confirmLabel: 'Continuar',
    );
    if (!firstOk || !context.mounted) return;

    final typed = await _confirmTyped(
      context,
      word: 'EXCLUIR',
      title: 'Confirme digitando',
      action: 'Excluir conta',
    );
    if (!typed || !context.mounted) return;

    _showProgress(context, 'Excluindo a conta…');
    final result = await ref.read(dataResetServiceProvider).deleteAccount();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    final failure = result.when(ok: (_) => null, err: (f) => f);
    if (failure != null) {
      showAppSnackBar(
        message: failure.message,
        variant: AppSnackBarVariant.error,
      );
      // Servidor apagou mas o aparelho não preparou: a conta já não existe,
      // então sai da sessão do mesmo jeito.
      if (failure is! DatabaseFailure) return;
    }
    await ref.read(authControllerProvider.notifier).signOut();
    if (failure == null) {
      showAppSnackBar(message: 'Conta excluída');
    }
  }

  /// Só libera o botão depois de digitar a palavra exata.
  Future<bool> _confirmTyped(
    BuildContext context, {
    String word = 'APAGAR',
    String title = 'Confirme digitando',
    String action = 'Apagar tudo',
  }) async {
    final colors = context.colors;
    final typed = ValueNotifier<String>('');
    final result = await AppDialog.show<bool>(
      context,
      icon: Icons.delete_forever_outlined,
      accent: colors.danger,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para continuar, digite $word abaixo.',
            style: context.texts.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: word),
            onChanged: (v) => typed.value = v,
          ),
        ],
      ),
      actions: [
        Builder(
          builder: (dialogContext) => PillButton(
            label: 'Cancelar',
            variant: PillButtonVariant.ghost,
            dense: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
        ),
        Builder(
          builder: (dialogContext) => ValueListenableBuilder<String>(
            valueListenable: typed,
            builder: (_, value, __) => PillButton(
              label: action,
              variant: PillButtonVariant.danger,
              dense: true,
              onPressed: value.trim().toUpperCase() == word
                  ? () => Navigator.of(dialogContext).pop(true)
                  : null,
            ),
          ),
        ),
      ],
    );
    typed.dispose();
    return result ?? false;
  }

  void _showProgress(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: context.colors.paper,
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  static const _weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  static String _weekdayName(int weekday) => _weekdays[(weekday - 1) % 7];

  static String _planWeekSubtitle(ReminderSettings r) {
    if (!r.planWeek) return 'Um aviso por semana pra escolher as refeições';
    final when = r.planWeekEffective;
    final base = '${_weekdayName(r.planWeekWeekday)} às '
        '${formatMinutes(r.planWeekMinutes)}';
    if (when.weekday == r.planWeekWeekday &&
        when.minutes == r.planWeekMinutes) {
      return base;
    }
    return 'Chega ${_weekdayName(when.weekday).toLowerCase()} às '
        '${formatMinutes(when.minutes)}, fora do horário silencioso';
  }

  Future<void> _pickPlanWeekWhen(
    BuildContext context,
    ReminderSettings current,
    ReminderSettingsNotifier notifier,
  ) async {
    final weekday = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => AppSheetFrame(
        title: 'Dia do lembrete',
        scrollable: true,
        child: AppSheetOptions(
          children: [
            for (var d = 1; d <= 7; d++)
              AppSheetOption(
                icon: Icons.event_outlined,
                title: _weekdayName(d),
                selected: d == current.planWeekWeekday,
                onTap: () => Navigator.of(sheet).pop(d),
              ),
          ],
        ),
      ),
    );
    if (weekday == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.planWeekMinutes ~/ 60,
        minute: current.planWeekMinutes % 60,
      ),
      helpText: 'Que horas avisar?',
    );
    await notifier.setPlanWeekWhen(
      weekday: weekday,
      minutes: time == null ? null : time.hour * 60 + time.minute,
    );
  }

  Future<void> _pickQuietRange(
    BuildContext context,
    ReminderSettings current,
    ReminderSettingsNotifier notifier,
  ) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.quiet.startMinutes ~/ 60,
        minute: current.quiet.startMinutes % 60,
      ),
      helpText: 'Começa o silêncio às',
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current.quiet.endMinutes ~/ 60,
        minute: current.quiet.endMinutes % 60,
      ),
      helpText: 'Termina às',
    );
    if (end == null) return;
    await notifier.setQuiet(
      current.quiet.copyWith(
        startMinutes: start.hour * 60 + start.minute,
        endMinutes: end.hour * 60 + end.minute,
      ),
    );
  }

  static String _copiesSubtitle(AutoBackupState a) {
    if (a.count == 0) return 'Nenhuma cópia ainda';
    final n = '${a.count} guardada${a.count == 1 ? '' : 's'}';
    final last = a.lastAt;
    return last == null ? n : '$n · última: ${formatBackupDate(last)}';
  }

  /// Uma linha que resume o painel "Timers e lembretes" fechado.
  static String _alertsSummary(
    CookingAlertSettings alerts,
    ReminderSettings reminders,
  ) {
    final timers = alerts.vibrate && alerts.sound
        ? 'vibram e tocam'
        : alerts.vibrate
            ? 'só vibram'
            : alerts.sound
                ? 'só tocam'
                : 'mudos';
    final week = reminders.planWeek
        ? '${_weekdayName(reminders.planWeekWeekday)} '
            '${formatMinutes(reminders.planWeekMinutes)}'
        : 'sem lembrete semanal';
    return 'Timers $timers · $week';
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
    final auto =
        ref.watch(autoBackupProvider).valueOrNull ?? const AutoBackupState();
    final alerts = ref.watch(cookingAlertSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final alertsNotifier = ref.read(cookingAlertSettingsProvider.notifier);
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';
    final reminders = ref.watch(reminderSettingsProvider);
    final remindersNotifier = ref.read(reminderSettingsProvider.notifier);
    final user = ref.watch(authUserProvider).valueOrNull;

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
                  if (user != null) ...[
                    _AccountCard(
                      user: user,
                      onSignOut: () => _signOut(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _Accordion(
                    items: [
                      _AccordionItem(
                        id: 'aparencia',
                        icon: Icons.palette_outlined,
                        title: 'Aparência',
                        summary:
                            'Texto ${settings.textSize.label.toLowerCase()}'
                            ' · ${settings.highContrast ? 'alto contraste' : 'contraste padrão'}',
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
                          _SwitchRow(
                            icon: Icons.straighten,
                            title: 'Equivalências de medidas',
                            subtitle: 'Mostra g ↔ xícara e °C ↔ °F ao lado',
                            value: settings.showEquivalents,
                            onChanged: settingsNotifier.setShowEquivalents,
                          ),
                        ],
                      ),
                      _AccordionItem(
                        id: 'lembretes',
                        icon: Icons.notifications_none_rounded,
                        title: 'Timers e lembretes',
                        summary: _alertsSummary(alerts, reminders),
                        children: [
                          _SwitchRow(
                            icon: Icons.vibration,
                            title: 'Vibrar ao acabar',
                            subtitle:
                                'Timers do modo cozinha, mesmo minimizado',
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
                          _SwitchRow(
                            icon: Icons.event_available_outlined,
                            title: 'Planejar a semana',
                            subtitle: _planWeekSubtitle(reminders),
                            value: reminders.planWeek,
                            onChanged: (on) async {
                              final ok =
                                  await remindersNotifier.setPlanWeek(on);
                              if (!ok && context.mounted) {
                                showAppSnackBar(
                                  message:
                                      'Sem permissão de notificação. Ative '
                                      'nas configurações do aparelho.',
                                  variant: AppSnackBarVariant.error,
                                );
                              }
                            },
                          ),
                          if (reminders.planWeek)
                            _NavRow(
                              icon: Icons.schedule,
                              title: 'Dia e hora',
                              subtitle:
                                  '${_weekdayName(reminders.planWeekWeekday)} às '
                                  '${formatMinutes(reminders.planWeekMinutes)}',
                              onTap: () => _pickPlanWeekWhen(
                                context,
                                reminders,
                                remindersNotifier,
                              ),
                            ),
                          _SwitchRow(
                            icon: Icons.bedtime_outlined,
                            title: 'Horário silencioso',
                            subtitle: reminders.quiet.enabled
                                ? 'Sem lembretes das '
                                    '${formatMinutes(reminders.quiet.startMinutes)} '
                                    'às ${formatMinutes(reminders.quiet.endMinutes)}'
                                : 'Os lembretes chegam a qualquer hora',
                            value: reminders.quiet.enabled,
                            onChanged: (on) => remindersNotifier.setQuiet(
                              reminders.quiet.copyWith(enabled: on),
                            ),
                          ),
                          if (reminders.quiet.enabled)
                            _NavRow(
                              icon: Icons.nights_stay_outlined,
                              title: 'Começo e fim',
                              subtitle:
                                  '${formatMinutes(reminders.quiet.startMinutes)} às '
                                  '${formatMinutes(reminders.quiet.endMinutes)}',
                              onTap: () => _pickQuietRange(
                                context,
                                reminders,
                                remindersNotifier,
                              ),
                            ),
                        ],
                      ),
                      _AccordionItem(
                        id: 'dados',
                        icon: Icons.backup_outlined,
                        title: 'Seus dados',
                        summary: _backupSubtitle(settings.lastBackupAt),
                        warn: settings.lastBackupAt == null,
                        children: [
                          _NavRow(
                            icon: Icons.backup_outlined,
                            title: 'Backup',
                            subtitle: _backupSubtitle(settings.lastBackupAt),
                            warn: settings.lastBackupAt == null,
                            onTap: () => _backup(context, ref),
                          ),
                          _SwitchRow(
                            icon: Icons.history_toggle_off,
                            title: 'Backup automático',
                            subtitle: auto.enabled
                                ? 'Uma cópia por dia, guardada no aparelho'
                                : 'Desligado',
                            value: auto.enabled,
                            onChanged: ref
                                .read(autoBackupProvider.notifier)
                                .setEnabled,
                          ),
                          _NavRow(
                            icon: Icons.settings_backup_restore,
                            title: 'Cópias automáticas',
                            subtitle: _copiesSubtitle(auto),
                            onTap: () => showAutoBackupSheet(context),
                          ),
                          _NavRow(
                            icon: Icons.school_outlined,
                            title: 'Ver a introdução de novo',
                            subtitle: 'Revê as boas-vindas e o tour do app',
                            onTap: () => context.go('/welcome'),
                          ),
                        ],
                      ),
                      _AccordionItem(
                        id: 'sobre',
                        icon: Icons.info_outline,
                        title: 'Sobre',
                        summary:
                            version.isEmpty ? 'Receyta' : 'Versão $version',
                        children: [
                          _InfoRow(
                            icon: Icons.info_outline,
                            title: 'Versão do app',
                            value: version.isEmpty ? '—' : version,
                          ),
                          _NavRow(
                            icon: Icons.auto_stories_outlined,
                            title: 'Sobre o Receyta',
                            subtitle:
                                'O app, perguntas frequentes e privacidade',
                            onTap: () => context.push('/about'),
                          ),
                          _NavRow(
                            icon: Icons.star_outline_rounded,
                            title: 'Avaliar na loja',
                            subtitle: 'Deixe sua opinião na Play Store',
                            onTap: () => _openStore(context, ref),
                          ),
                        ],
                      ),
                      _AccordionItem(
                        id: 'risco',
                        icon: Icons.warning_amber_rounded,
                        title: 'Zona de risco',
                        summary: user == null
                            ? 'Limpar os dados deste aparelho'
                            : 'Limpar o aparelho, a conta ou excluir a conta',
                        danger: true,
                        children: [
                          _NavRow(
                            icon: Icons.delete_outline,
                            title: user == null
                                ? 'Limpar dados'
                                : 'Limpar este aparelho',
                            subtitle: user == null
                                ? 'Apaga tudo o que está salvo neste aparelho'
                                : 'A conta guarda uma cópia, que volta ao sincronizar',
                            danger: true,
                            onTap: () => _wipe(context, ref),
                          ),
                          if (user != null)
                            _NavRow(
                              icon: Icons.delete_forever_outlined,
                              title: 'Apagar tudo, inclusive da conta',
                              subtitle: 'Receitas, pastas e fotos, aqui e na '
                                  'nuvem. Não dá para desfazer',
                              danger: true,
                              onTap: () => _wipeEverything(context, ref),
                            ),
                          if (user != null)
                            _NavRow(
                              icon: Icons.person_remove_outlined,
                              title: 'Excluir minha conta',
                              subtitle:
                                  'Remove a conta e os dados dela da nuvem. '
                                  'O que está aqui continua',
                              danger: true,
                              onTap: () => _deleteAccount(context, ref),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    user == null
                        ? 'Receyta · seus dados ficam só neste aparelho'
                        : 'Receyta · conta conectada, fotos guardadas na nuvem',
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

/// Cartão da conta no topo: quem está conectado e o "Sair" à mostra (antes era
/// uma linha perdida no meio da lista).
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.onSignOut});

  final AppUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = (user.name ?? '').trim();
    final label = name.isEmpty ? (user.email ?? 'Conta conectada') : name;
    final initial = label.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration:
                BoxDecoration(color: colors.ink, shape: BoxShape.circle),
            child: user.avatarUrl == null
                ? Text(
                    initial,
                    style:
                        AppTextStyles.display(26).copyWith(color: colors.lime),
                  )
                : Image.network(
                    user.avatarUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(
                      initial,
                      style: AppTextStyles.display(26)
                          .copyWith(color: colors.lime),
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (user.email != null && name.isNotEmpty)
                  Text(
                    user.email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                Text(
                  'Conectado com o Google',
                  style: context.texts.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          PillButton(
            label: 'Sair',
            icon: Icons.logout_rounded,
            variant: PillButtonVariant.secondary,
            dense: true,
            onPressed: onSignOut,
          ),
        ],
      ),
    );
  }
}

/// Um painel da tela: título, uma linha de resumo (visível fechado) e as
/// linhas de ajuste (visíveis aberto).
class _AccordionItem {
  const _AccordionItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.children,
    this.warn = false,
    this.danger = false,
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final List<Widget> children;

  /// Resumo em destaque (algo que merece atenção, como "sem backup").
  final bool warn;

  /// Painel de ações perigosas: ícone e título em vermelho, e uma distância
  /// maior dos outros.
  final bool danger;
}

/// Painéis que abrem e fecham, UM aberto por vez: abrir um fecha o outro. Tudo
/// começa fechado — o resumo de cada painel já diz como está o ajuste.
class _Accordion extends StatefulWidget {
  const _Accordion({required this.items});

  final List<_AccordionItem> items;

  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion> {
  String? _open;

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in widget.items)
          Padding(
            padding: EdgeInsets.only(
              bottom: AppSpacing.sm,
              top: item.danger ? AppSpacing.md : 0,
            ),
            child: _AccordionCard(
              item: item,
              open: _open == item.id,
              onToggle: () => _toggle(item.id),
            ),
          ),
      ],
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.item,
    required this.open,
    required this.onToggle,
  });

  final _AccordionItem item;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = item.danger ? colors.danger : colors.ink;

    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: '${item.title}. ${item.summary}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      _PanelBadge(icon: item.icon, danger: item.danger),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.display(22)
                                  .copyWith(color: accent),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.texts.bodySmall?.copyWith(
                                color: item.warn
                                    ? colors.danger
                                    : colors.textMuted,
                                fontWeight: item.warn ? FontWeight.w700 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Column(
                    children: [
                      Divider(height: 1, thickness: 1.5, color: colors.paper),
                      for (var i = 0; i < item.children.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 72,
                            color: colors.paper,
                            thickness: 1.5,
                          ),
                        item.children[i],
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Ícone do cabeçalho de um painel: quadrado arredondado só com borda, para
/// se distinguir dos medalhões redondos e cheios das linhas que dão ação.
class _PanelBadge extends StatelessWidget {
  const _PanelBadge({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = danger ? colors.danger : colors.ink;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: accent, width: 2),
      ),
      child: Icon(icon, size: 22, color: accent),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ConstrainedBox(
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
            Expanded(
              child: Text(
                title,
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
            ),
            Text(
              value,
              style:
                  context.texts.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ],
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
                                color:
                                    step == current ? colors.lime : colors.ink,
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
