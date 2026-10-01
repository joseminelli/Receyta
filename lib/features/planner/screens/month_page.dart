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
import 'package:receyta/widgets/metric_stat.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/slide_switcher.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

/// Coluna à direita da grade com o carrinho de cada semana.
const _cartColumn = 40.0;

/// Proporção (largura/altura) de uma célula da grade: mais alta que larga pra
/// caber até três faixas de refeição empilhadas.
const _cellAspect = 0.8;

/// Máximo de faixas (refeições) desenhadas numa célula.
const _maxBands = 3;

void _openDay(BuildContext context, DateTime day) =>
    context.push('/planner/day/${dayToParam(day)}');

/// Aba "Semana" (§RF-04.1), primeira etapa do planejamento. De cima pra
/// baixo: o mês (números do mês, a grade em mosaico de azulejos e o carrinho
/// de cada semana) e "Próximas refeições" — o que vem a seguir, já com atalho
/// pro dia. Cada dia da grade é dividido em faixas, uma por refeição, na cor e
/// textura da receita (mesmo azulejo do card). Tocar num dia abre a tela do
/// dia.
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
              _MonthStats(month: month, entries: entries),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 1,
                color: colors.textMuted.withValues(alpha: 0.25),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildWeekdayLabels(context),
              const SizedBox(height: 4),
              SlideSwitcher(
                index: month.year * 12 + month.month,
                child: _buildGrid(context, ref, month, entries),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _UpcomingSection(),
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
            onOpenDay: (day) => _openDay(context, day),
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
}

/// Três números grandes do mês mostrado: refeições planejadas, receitas
/// diferentes e quantas já foram feitas.
class _MonthStats extends StatelessWidget {
  const _MonthStats({required this.month, required this.entries});

  final DateTime month;
  final List<MealPlanEntry> entries;

  @override
  Widget build(BuildContext context) {
    final inMonth = [
      for (final e in entries)
        if (e.date.year == month.year && e.date.month == month.month) e,
    ];
    final recipes = {for (final e in inMonth) e.recipeId}.length;
    final done = inMonth.where((e) => e.done).length;
    return Row(
      children: [
        Expanded(
          child: MetricStat(
            value: '${inMonth.length}',
            label: inMonth.length == 1 ? 'refeição' : 'refeições',
            valueSize: 34,
          ),
        ),
        Expanded(
          child: MetricStat(
            value: '$recipes',
            label: recipes == 1 ? 'receita' : 'receitas',
            valueSize: 34,
          ),
        ),
        Expanded(
          child: MetricStat(
            value: '$done',
            label: done == 1 ? 'feita' : 'feitas',
            valueSize: 34,
          ),
        ),
      ],
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

/// Um dia da grade, dividido em faixas — uma por refeição (café, almoço,
/// jantar, lanche, nessa ordem), até três, cada uma no azulejo da receita; o
/// que passar disso vira "+N". "Hoje" ganha um anel de `ink` com respiro.
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
    final allDone = entries.isNotEmpty && entries.every((e) => e.done);
    final ordered = [...entries]
      ..sort((a, b) => a.mealType.index.compareTo(b.mealType.index));
    final shown = ordered.take(_maxBands).toList();
    final extra = ordered.length - shown.length;
    final tiles = [
      for (final e in shown)
        resolveTileAppearance(
          colors,
          color: e.recipe.tileColor,
          motif: e.recipe.tileMotif,
          seedId: e.recipe.id,
        ),
    ];
    final numberColor = tiles.isEmpty ? colors.ink : tiles.first.onColor;
    final radius = BorderRadius.circular(AppRadii.sm - 4);

    final cell = AspectRatio(
      aspectRatio: _cellAspect,
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: colors.paperSoft,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (tiles.isNotEmpty)
                  Column(
                    children: [
                      for (final t in tiles)
                        Expanded(
                          child: SizedBox.expand(
                            child: ColoredBox(
                              color: t.background,
                              child: TilePattern(
                                motif: t.motif,
                                background: t.background,
                                patternColor: t.patternColor,
                                patternColorAlt: t.patternColorAlt,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                if (extra > 0)
                  Positioned(
                    right: 5,
                    bottom: 3,
                    child: Text(
                      '+$extra',
                      style: context.texts.labelSmall?.copyWith(
                        color: tiles.last.onColor.withValues(alpha: 0.95),
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

/// "Próximas refeições": até cinco refeições pendentes dos próximos 14 dias,
/// cada uma com o azulejo, o nome e "Hoje · Almoço". Tocar abre o dia. Sem
/// nada agendado, convida a planejar hoje.
class _UpcomingSection extends ConsumerWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingEntriesProvider(today())).valueOrNull ??
        const <MealPlanEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Próximas refeições', eyebrow: 'A seguir'),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          _buildEmpty(context)
        else
          for (final e in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _UpcomingRow(
                entry: e,
                onTap: () => _openDay(context, e.date),
              ),
            ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nada planejado pros próximos dias.',
            style: context.texts.bodyLarge,
          ),
          const SizedBox(height: 2),
          Text(
            'Toque num dia do calendário ou comece por hoje.',
            style:
                context.texts.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          PillButton(
            label: 'Planejar hoje',
            icon: Icons.add,
            dense: true,
            onPressed: () => _openDay(context, today()),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.entry, required this.onTap});

  final MealPlanEntry entry;
  final VoidCallback onTap;

  String get _when {
    final diff = entry.date.difference(today()).inDays;
    final day = diff == 0
        ? 'Hoje'
        : diff == 1
            ? 'Amanhã'
            : '${weekdayShort(entry.date)} ${entry.date.day} '
                '${monthShort(entry.date)}';
    return '$day · ${entry.mealType.label}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: entry.recipe.tileColor,
      motif: entry.recipe.tileMotif,
      seedId: entry.recipe.id,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: colors.paperSoft,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ColoredBox(
                  color: tile.background,
                  child: TilePattern(
                    motif: tile.motif,
                    background: tile.background,
                    patternColor: tile.patternColor,
                    patternColorAlt: tile.patternColorAlt,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.recipeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _when,
                      style: context.texts.bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.textMuted),
              const SizedBox(width: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }
}
