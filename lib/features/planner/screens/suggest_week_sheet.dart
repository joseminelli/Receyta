import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/data/repositories/week_planner_service.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/engine/week_planner.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// "Sugerir a semana": escolhe a semana, as refeições e (se quiser) tags;
/// mostra a proposta, deixa trocar e agenda tudo de uma vez.
Future<void> showSuggestWeekSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _SuggestWeekSheet(),
  );
}

class _SuggestWeekSheet extends ConsumerStatefulWidget {
  const _SuggestWeekSheet();

  @override
  ConsumerState<_SuggestWeekSheet> createState() => _SuggestWeekSheetState();
}

class _SuggestWeekSheetState extends ConsumerState<_SuggestWeekSheet> {
  int _weekOffset = 0;
  final _meals = <MealType>{MealType.dinner};
  final _tags = <String>{};
  bool _quick = false;
  int _seed = 0;
  List<PlanPick>? _picks;
  bool _busy = false;

  DateTime get _monday => addDays(mondayOf(today()), _weekOffset * 7);

  Future<void> _generate({bool reshuffle = false}) async {
    if (reshuffle) _seed++;
    setState(() => _busy = true);
    final candidates = await ref.read(weekPlannerServiceProvider).candidates();
    final existing = await ref
        .read(mealPlanRepositoryProvider)
        .watchRange(addDays(_monday, -14), addDays(_monday, 21))
        .first;
    final picks = planWeek(
      candidates: candidates,
      existing: existing,
      options: WeekPlanOptions(
        monday: _monday,
        meals: _meals,
        anyOfTags: _tags,
        maxMinutes: _quick ? 30 : null,
        seed: _seed,
      ),
      now: DateTime.now(),
    );
    if (!mounted) return;
    setState(() {
      _picks = picks;
      _busy = false;
    });
  }

  Future<void> _confirm() async {
    final picks = _picks;
    if (picks == null || picks.isEmpty) return;
    final repo = ref.read(mealPlanRepositoryProvider);
    for (final p in picks) {
      await repo.add(p.candidate.id, p.date, p.mealType);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnackBar(
      message: '${picks.length} '
          '${picks.length == 1 ? 'refeição agendada' : 'refeições agendadas'}',
    );
  }

  void _toggle<T>(Set<T> set, T value) {
    setState(() {
      set.contains(value) ? set.remove(value) : set.add(value);
      _picks = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tags = ref.watch(_tagsInUseProvider).valueOrNull ?? const <String>[];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sugerir a semana',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Preenche só os espaços vazios, priorizando receitas que você '
                'faz há tempo ou nunca fez.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final (i, label)
                        in const ['Esta semana', 'Próxima'].indexed)
                      ChoicePill(
                        label: label,
                        selected: _weekOffset == i,
                        onTap: () => setState(() {
                          _weekOffset = i;
                          _picks = null;
                        }),
                      ),
                  ]),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final m in MealType.values)
                      ChoicePill(
                        label: m.label,
                        selected: _meals.contains(m),
                        onTap: () {
                          if (_meals.length == 1 && _meals.contains(m)) return;
                          _toggle(_meals, m);
                        },
                      ),
                  ]),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoicePill(
                      label: 'Até 30 min',
                      selected: _quick,
                      onTap: () => setState(() {
                        _quick = !_quick;
                        _picks = null;
                      }),
                    ),
                    for (final t in tags)
                      ChoicePill(
                        label: t,
                        selected: _tags.contains(stripAccents(t.toLowerCase())),
                        onTap: () =>
                            _toggle(_tags, stripAccents(t.toLowerCase())),
                      ),
                  ]),
              const SizedBox(height: AppSpacing.md),
              if (_picks == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Sugerir'),
                )
              else
                ..._buildProposal(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProposal(BuildContext context) {
    final colors = context.colors;
    final picks = _picks!;
    if (picks.isEmpty) {
      return [
        Text(
          'Nada pra sugerir: os espaços já estão preenchidos ou nenhuma '
          'receita passa nos filtros.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: colors.textMuted),
        ),
      ];
    }
    return [
      for (final p in picks)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(p.candidate.name,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${weekdayLong(p.date)} · ${p.mealType.label}'),
        ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _generate(reshuffle: true),
            icon: const Icon(Icons.shuffle),
            label: const Text('Trocar'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: _confirm,
              child: Text('Agendar ${picks.length}'),
            ),
          ),
        ],
      ),
    ];
  }
}

final _tagsInUseProvider = StreamProvider.autoDispose<List<String>>(
  (ref) => ref
      .watch(tagRepositoryProvider)
      .watchInUse()
      .map((tags) => [for (final t in tags) t.name]),
);
