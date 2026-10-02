import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/cook_log_repository.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/engine/cook_log_format.dart';
import 'package:receyta/domain/models/cook_log.dart';
import 'package:receyta/features/recipes/controllers/cook_log_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Registra agora que a receita foi feita, com aviso e "Desfazer". É o atalho
/// do modo cozinha: um toque, sem formulário. Se a receita está na agenda de
/// hoje e ainda pendente, a refeição também é marcada como feita (e é ela que
/// grava no histórico, pra não contar duas vezes).
Future<void> logCookedNow(WidgetRef ref, String recipeId) async {
  final plan = ref.read(mealPlanRepositoryProvider);
  final marked = await plan.markCookedToday(recipeId);
  if (marked is Ok<String?> && marked.value != null) {
    final entryId = marked.value!;
    showAppSnackBar(
      message: 'Registrado e marcado na agenda de hoje',
      actionLabel: 'Desfazer',
      onAction: () => plan.setDone(entryId, false),
    );
    return;
  }

  final repo = ref.read(cookLogRepositoryProvider);
  final result = await repo.add(recipeId);
  result.when(
    ok: (id) => showAppSnackBar(
      message: 'Registrado: você cozinhou hoje',
      actionLabel: 'Desfazer',
      onAction: () => repo.remove(id),
    ),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}

/// Folha do histórico: registrar uma vez (data e nota) e ver/apagar as
/// anteriores.
Future<void> showCookLogSheet(BuildContext context, String recipeId) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CookLogSheet(recipeId: recipeId),
  );
}

class _CookLogSheet extends ConsumerStatefulWidget {
  const _CookLogSheet({required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<_CookLogSheet> createState() => _CookLogSheetState();
}

class _CookLogSheetState extends ConsumerState<_CookLogSheet> {
  final _note = TextEditingController();
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Quando você cozinhou?',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final isToday = _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
    final cookedAt =
        isToday ? now : DateTime(_date.year, _date.month, _date.day, 12);
    final result = await ref.read(cookLogRepositoryProvider).add(
          widget.recipeId,
          cookedAt: cookedAt,
          note: _note.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _note.clear();
        setState(() {
          _date = DateTime(now.year, now.month, now.day);
        });
      },
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final logs = ref.watch(cookLogsProvider(widget.recipeId));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cozinhei', style: AppTextStyles.display(34)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Registre quando você fez e, se quiser, como ficou.',
                style:
                    context.texts.bodyMedium?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      cookedAgo(_date, now) == 'hoje'
                          ? 'Hoje'
                          : formatCookedDate(_date, now),
                    ),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Nota (opcional): faltou sal, ficou ótimo…',
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: PillButton(
                  label: 'Registrar',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...switch (logs) {
                AsyncData(:final value) when value.isNotEmpty => [
                    Text(
                      'HISTÓRICO',
                      style: context.texts.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    for (final log in value)
                      _LogRow(
                        log: log,
                        now: now,
                        onDelete: () =>
                            ref.read(cookLogRepositoryProvider).remove(log.id),
                      ),
                  ],
                _ => const <Widget>[],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log, required this.now, required this.onDelete});

  final CookLog log;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatCookedDate(log.cookedAt, now),
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (log.hasNote)
                  Text(log.note!, style: context.texts.bodyMedium),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Apagar registro',
            icon: const Icon(Icons.close_rounded),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Cartão do detalhe da receita: quantas vezes foi feita e quando foi a
/// última. Toque abre a folha do histórico.
class CookedCard extends ConsumerWidget {
  const CookedCard({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final logs = ref.watch(cookLogsProvider(recipeId)).valueOrNull ?? const [];
    final now = DateTime.now();
    final last = logs.isEmpty ? null : logs.first.cookedAt;

    return Semantics(
      button: true,
      label: 'Histórico de quando você cozinhou',
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => showCookLogSheet(context, recipeId),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  logs.isEmpty
                      ? Icons.restaurant_outlined
                      : Icons.restaurant_rounded,
                  color: colors.ink,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cookedTimesLabel(logs.length),
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        last == null
                            ? 'Toque pra registrar quando fizer'
                            : 'Última vez: ${cookedAgo(last, now)}',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
