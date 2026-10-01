import 'package:flutter/material.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Dia + refeição escolhidos.
typedef MealSlot = ({DateTime day, MealType meal});

/// Pílula de escolha (dia ou refeição): selecionada fica em `ink`, as outras
/// só de contorno — nada de fundo tingido.
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.ink : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? colors.ink : colors.textMuted),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Text(
            label,
            style: context.texts.labelLarge
                ?.copyWith(color: selected ? colors.paper : colors.ink),
          ),
        ),
      ),
    );
  }
}

/// Escolhe dia e refeição pra mover/duplicar uma refeição (RF-04.3). Mostra
/// os 7 dias da semana de [weekStart] e "Outra data…" pro resto. Devolve
/// nulo se fechou sem confirmar.
Future<MealSlot?> pickMealSlot(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required DateTime weekStart,
  required DateTime initialDay,
  required MealType initialMeal,
}) {
  return showModalBottomSheet<MealSlot>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _MealSlotSheet(
      title: title,
      confirmLabel: confirmLabel,
      weekStart: weekStart,
      initialDay: initialDay,
      initialMeal: initialMeal,
    ),
  );
}

class _MealSlotSheet extends StatefulWidget {
  const _MealSlotSheet({
    required this.title,
    required this.confirmLabel,
    required this.weekStart,
    required this.initialDay,
    required this.initialMeal,
  });

  final String title;
  final String confirmLabel;
  final DateTime weekStart;
  final DateTime initialDay;
  final MealType initialMeal;

  @override
  State<_MealSlotSheet> createState() => _MealSlotSheetState();
}

class _MealSlotSheetState extends State<_MealSlotSheet> {
  late DateTime _day = dayOf(widget.initialDay);
  late MealType _meal = widget.initialMeal;

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _day = dayOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    final week = [for (var i = 0; i < 7; i++) addDays(widget.weekStart, i)];
    final inWeek = week.any((d) => isSameDay(d, _day));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: context.texts.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Text('DIA', style: context.texts.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final d in week)
                  ChoicePill(
                    label: '${weekdayShort(d)} ${d.day}',
                    selected: isSameDay(d, _day),
                    onTap: () => setState(() => _day = d),
                  ),
                ChoicePill(
                  label: inWeek
                      ? 'Outra data…'
                      : '${weekdayShort(_day)} ${_day.day} ${monthShort(_day)}',
                  selected: !inWeek,
                  onTap: _pickOtherDate,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('REFEIÇÃO', style: context.texts.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final m in MealType.values)
                  ChoicePill(
                    label: m.label,
                    selected: m == _meal,
                    onTap: () => setState(() => _meal = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                label: widget.confirmLabel,
                onPressed: () => Navigator.of(context)
                    .pop<MealSlot>((day: _day, meal: _meal)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
