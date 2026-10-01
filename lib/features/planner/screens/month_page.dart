import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/shopping/screens/add_to_shopping_list_flow.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

/// Coluna à direita da grade com o carrinho de cada semana.
const _cartColumn = 40.0;

/// Aba "Semana" (§RF-04.1), primeira etapa do planejamento: o mês como um
/// mosaico de azulejos. Dia com refeição ganha o azulejo da receita principal
/// dele (mesma cor e textura do card), dia vazio fica em `paperSoft`. Tocar
/// num dia abre a tela do dia; o carrinho no fim de cada linha gera a lista de
/// compras daquela semana (RF-05.1/F3).
class MonthPage extends ConsumerWidget {
  const MonthPage({super.key});

  void _shiftMonth(WidgetRef ref, int months) {
    HapticFeedback.selectionClick();
    final notifier = ref.read(visibleMonthProvider.notifier);
    notifier.state = addMonths(notifier.state, months);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final month = ref.watch(visibleMonthProvider);
    final entries =
        ref.watch(monthEntriesProvider).valueOrNull ?? const <MealPlanEntry>[];

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v > 500) _shiftMonth(ref, -1);
            if (v < -500) _shiftMonth(ref, 1);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              _navBarClearance,
            ),
            children: [
              _buildHeader(context, ref, month),
              const SizedBox(height: AppSpacing.md),
              _buildWeekdayLabels(context),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildGrid(context, ref, month, entries),
              ),
              if (entries.isEmpty) _buildHint(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, DateTime month) {
    final colors = context.colors;
    final isCurrent = isSameDay(month, firstOfMonth(today()));
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthLong(month), style: context.texts.displaySmall),
              Text(
                '${month.year}',
                style:
                    context.texts.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
        ),
        if (!isCurrent) ...[
          PillButton(
            label: 'Hoje',
            variant: PillButtonVariant.ghost,
            dense: true,
            onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                firstOfMonth(today()),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        CircleIconButton(
          icon: Icons.chevron_left,
          tooltip: 'Mês anterior',
          onTap: () => _shiftMonth(ref, -1),
        ),
        const SizedBox(width: AppSpacing.xs),
        CircleIconButton(
          icon: Icons.chevron_right,
          tooltip: 'Próximo mês',
          onTap: () => _shiftMonth(ref, 1),
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    final colors = context.colors;
    final monday = mondayOf(today());
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                weekdayShort(addDays(monday, i)).substring(0, 3).toUpperCase(),
                style: context.texts.labelSmall
                    ?.copyWith(color: colors.textMuted, letterSpacing: 0.6),
              ),
            ),
          ),
        const SizedBox(width: _cartColumn),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
    List<MealPlanEntry> entries,
  ) {
    final byDay = <String, List<MealPlanEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(dayToParam(e.date), () => []).add(e);
    }
    return Column(
      key: ValueKey(month),
      children: [
        for (final monday in monthWeeks(month))
          _WeekRow(
            monday: monday,
            month: month,
            byDay: byDay,
            onOpenDay: (day) =>
                context.push('/planner/day/${dayToParam(day)}'),
            onShopping: (counts) => addRecipesToShoppingListFlow(
              context,
              ref,
              counts,
              newListName: 'Semana ${weekRangeLabel(monday)}',
            ),
          ),
      ],
    );
  }

  Widget _buildHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Text(
        'Toque num dia pra planejar as refeições.',
        textAlign: TextAlign.center,
        style: context.texts.bodyMedium
            ?.copyWith(color: context.colors.textMuted),
      ),
    );
  }
}

/// Uma linha da grade: 7 dias + o carrinho da semana.
class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.monday,
    required this.month,
    required this.byDay,
    required this.onOpenDay,
    required this.onShopping,
  });

  final DateTime monday;
  final DateTime month;
  final Map<String, List<MealPlanEntry>> byDay;
  final ValueChanged<DateTime> onOpenDay;
  final ValueChanged<Map<String, int>> onShopping;

  @override
  Widget build(BuildContext context) {
    final days = [for (var i = 0; i < 7; i++) addDays(monday, i)];
    final weekEntries = [
      for (final d in days) ...?byDay[dayToParam(d)],
    ];
    final counts = pendingRecipeCounts(weekEntries, today());
    final colors = context.colors;

    return Row(
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _DayCell(
                day: d,
                inMonth: d.month == month.month,
                entries: byDay[dayToParam(d)] ?? const [],
                onTap: () => onOpenDay(d),
              ),
            ),
          ),
        SizedBox(
          width: _cartColumn,
          child: IconButton(
            tooltip: counts.isEmpty
                ? 'Nada pendente nesta semana'
                : 'Lista de compras da semana ${weekRangeLabel(monday)}',
            iconSize: 22,
            color: colors.ink,
            onPressed: counts.isEmpty ? null : () => onShopping(counts),
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
        ),
      ],
    );
  }
}

/// Um dia da grade. Com refeição, vira o azulejo da principal; "hoje" ganha
/// um anel de `ink` com respiro; o número de refeições aparece embaixo à
/// direita quando passa de uma.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.entries,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final List<MealPlanEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isToday = isSameDay(day, today());
    final main = mainEntryOfDay(entries);
    final allDone = entries.isNotEmpty && entries.every((e) => e.done);
    final tile = main == null
        ? null
        : resolveTileAppearance(
            colors,
            color: main.recipe.tileColor,
            motif: main.recipe.tileMotif,
            seedId: main.recipe.id,
          );
    final numberColor = tile?.onColor ?? colors.ink;
    final radius = BorderRadius.circular(AppRadii.sm - 4);

    final cell = AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: tile?.background ?? colors.paperSoft,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (tile != null)
                  TilePattern(
                    motif: tile.motif,
                    background: tile.background,
                    patternColor: tile.patternColor,
                    patternColorAlt: tile.patternColorAlt,
                  ),
                Positioned(
                  top: 4,
                  left: 6,
                  child: Text(
                    '${day.day}',
                    style: context.texts.titleSmall?.copyWith(
                      color: numberColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (entries.length > 1)
                  Positioned(
                    right: 5,
                    bottom: 3,
                    child: Text(
                      '×${entries.length}',
                      style: context.texts.labelSmall?.copyWith(
                        color: numberColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '${weekdayLong(day)}, ${day.day} de ${monthLong(day)}'
          '${entries.isEmpty ? '' : ', ${entries.length} refeições'}',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: !inMonth ? 0.35 : (allDone ? 0.6 : 1),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: isToday ? colors.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: cell,
        ),
      ),
    );
  }
}
