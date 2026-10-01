import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/add_meal_sheet.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/shopping/screens/add_to_shopping_list_flow.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/swipe_action_background.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/core/result.dart';

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

/// Aba "Semana" (§RF-04): faixa com os 7 dias da semana (segunda a domingo),
/// o dia escolhido detalhado em refeições embaixo. Agendar é pelo "+" de cada
/// refeição; mover é arrastar uma refeição até outro dia da faixa (ou outra
/// refeição do mesmo dia) e também pelo menu ⋯.
class WeekPage extends ConsumerStatefulWidget {
  const WeekPage({super.key});

  @override
  ConsumerState<WeekPage> createState() => _WeekPageState();
}

class _WeekPageState extends ConsumerState<WeekPage> {
  /// Refeições já deslizadas pra fora: somem na hora (o `Dismissible` exige
  /// sair da árvore) enquanto o banco apaga e o stream não reemitiu.
  final _removed = <String>{};

  MealPlanRepository get _repo => ref.read(mealPlanRepositoryProvider);

  void _selectDay(DateTime day) =>
      ref.read(selectedDayProvider.notifier).state = dayOf(day);

  void _shiftWeek(int weeks) =>
      _selectDay(addDays(ref.read(selectedDayProvider), weeks * 7));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = ref.watch(selectedDayProvider);
    final monday = ref.watch(weekStartProvider);
    final entriesAsync = ref.watch(weekEntriesProvider);
    final entries = [
      for (final e in entriesAsync.valueOrNull ?? const <MealPlanEntry>[])
        if (!_removed.contains(e.id)) e,
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, monday, selected, entries),
            _buildDayStrip(context, monday, selected, entries),
            Expanded(
              child: entriesAsync.isLoading && entries.isEmpty
                  ? const Center(child: BrandLoader())
                  : _buildDay(context, selected, entries),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    DateTime monday,
    DateTime selected,
    List<MealPlanEntry> entries,
  ) {
    final colors = context.colors;
    final isCurrentWeek = isSameDay(monday, mondayOf(today()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Semana', style: context.texts.displaySmall),
                Text(
                  weekRangeLabel(monday),
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          if (!isSameDay(selected, today())) ...[
            PillButton(
              label: 'Hoje',
              variant: PillButtonVariant.ghost,
              dense: true,
              onPressed: () => _selectDay(today()),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          CircleIconButton(
            icon: Icons.chevron_left,
            tooltip: 'Semana anterior',
            onTap: () => _shiftWeek(-1),
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.chevron_right,
            tooltip: 'Próxima semana',
            onTap: () => _shiftWeek(1),
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.add_shopping_cart_outlined,
            tooltip: isCurrentWeek
                ? 'Lista de compras desta semana'
                : 'Lista de compras da semana',
            onTap: () => _shoppingFromWeek(monday, entries),
          ),
        ],
      ),
    );
  }

  Widget _buildDayStrip(
    BuildContext context,
    DateTime monday,
    DateTime selected,
    List<MealPlanEntry> entries,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _DayChip(
                day: addDays(monday, i),
                selected: isSameDay(addDays(monday, i), selected),
                count: entries
                    .where((e) => isSameDay(e.date, addDays(monday, i)))
                    .length,
                onTap: () => _selectDay(addDays(monday, i)),
                onDrop: (entry) => _moveTo(entry, addDays(monday, i)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDay(
    BuildContext context,
    DateTime day,
    List<MealPlanEntry> entries,
  ) {
    final colors = context.colors;
    final dayEntries = [
      for (final e in entries)
        if (isSameDay(e.date, day)) e,
    ];
    final isToday = isSameDay(day, today());
    // Duas refeições do mesmo dia com a mesma receita dividiriam a tag do
    // Hero (o Flutter recusa); só a primeira ocorrência do dia voa.
    final heroOwners = <String, String>{};
    for (final meal in MealType.values) {
      for (final e in dayEntries.where((e) => e.mealType == meal)) {
        heroOwners.putIfAbsent(e.recipeId, () => e.id);
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        _navBarClearance,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${weekdayLong(day)}, ${day.day} ${monthShort(day)}',
                style: context.texts.titleLarge,
              ),
            ),
            if (isToday)
              Text(
                'HOJE',
                style: context.texts.labelMedium
                    ?.copyWith(color: colors.violet, letterSpacing: 1.2),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final meal in MealType.values)
          _MealSection(
            meal: meal,
            entries: [
              for (final e in dayEntries)
                if (e.mealType == meal) e,
            ],
            onAdd: () => showAddMealSheet(
              context,
              day: day,
              initialMeal: meal,
            ),
            onDrop: (entry) => _moveTo(entry, day, meal: meal),
            buildTile: (entry) => _EntryTile(
              entry: entry,
              useHero: heroOwners[entry.recipeId] == entry.id,
              onOpen: () => context.push(
                '/recipe/${entry.recipeId}',
                extra: entry.recipe,
              ),
              onToggleDone: () => _repo.setDone(entry.id, !entry.done),
              onRemove: () => _remove(entry),
              onMenu: () => _openMenu(entry),
            ),
          ),
      ],
    );
  }

  Future<void> _moveTo(
    MealPlanEntry entry,
    DateTime day, {
    MealType? meal,
  }) async {
    final target = meal ?? entry.mealType;
    if (isSameDay(entry.date, day) && entry.mealType == target) return;
    HapticFeedback.selectionClick();
    final result = await _repo.move(entry.id, day, target);
    if (result is Err<void>) _reportError(result.failure.message);
  }

  Future<void> _remove(MealPlanEntry entry) async {
    setState(() => _removed.add(entry.id));
    final result = await _repo.remove(entry.id);
    result.when(
      ok: (_) => showAppSnackBar(
        message: 'Removido: ${entry.recipeName}',
        actionLabel: 'Desfazer',
        onAction: () => _repo.restore(entry),
      ),
      err: (f) {
        if (mounted) setState(() => _removed.remove(entry.id));
        _reportError(f.message);
      },
    );
  }

  Future<void> _openMenu(MealPlanEntry entry) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Mover para…'),
              onTap: () {
                Navigator.of(sheet).pop();
                _moveFlow(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Duplicar para…'),
              onTap: () {
                Navigator.of(sheet).pop();
                _duplicateFlow(entry);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.colors.danger),
              title: Text(
                'Remover do plano',
                style: context.texts.bodyLarge
                    ?.copyWith(color: context.colors.danger),
              ),
              onTap: () {
                Navigator.of(sheet).pop();
                _remove(entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moveFlow(MealPlanEntry entry) async {
    final slot = await pickMealSlot(
      context,
      title: 'Mover "${entry.recipeName}"',
      confirmLabel: 'Mover',
      weekStart: ref.read(weekStartProvider),
      initialDay: entry.date,
      initialMeal: entry.mealType,
    );
    if (slot == null) return;
    await _moveTo(entry, slot.day, meal: slot.meal);
  }

  Future<void> _duplicateFlow(MealPlanEntry entry) async {
    final slot = await pickMealSlot(
      context,
      title: 'Duplicar "${entry.recipeName}"',
      confirmLabel: 'Duplicar',
      weekStart: ref.read(weekStartProvider),
      initialDay: addDays(entry.date, 1),
      initialMeal: entry.mealType,
    );
    if (slot == null) return;
    final result = await _repo.duplicate(entry.id, slot.day, slot.meal);
    result.when(
      ok: (_) => showAppSnackBar(
        message: 'Duplicado para ${weekdayShort(slot.day)} ${slot.day.day} '
            '(${slot.meal.label})',
      ),
      err: (f) => _reportError(f.message),
    );
  }

  /// F3: lista de compras do que ainda falta cozinhar na semana mostrada
  /// (de hoje em diante, refeições não marcadas como feitas).
  Future<void> _shoppingFromWeek(
    DateTime monday,
    List<MealPlanEntry> entries,
  ) async {
    final counts = pendingRecipeCounts(entries, today());
    if (counts.isEmpty) {
      showAppSnackBar(
        message: 'Nenhuma refeição pendente nesta semana.',
        variant: AppSnackBarVariant.error,
      );
      return;
    }
    await addRecipesToShoppingListFlow(
      context,
      ref,
      counts,
      newListName: 'Semana ${weekRangeLabel(monday)}',
    );
  }

  void _reportError(String message) => showAppSnackBar(
        message: message,
        variant: AppSnackBarVariant.error,
      );
}

/// Chip de um dia da faixa: dia da semana, número e pontinhos (1 por
/// refeição, até 3). Também é alvo de soltar — arrastar uma refeição até ele
/// move pro dia.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.count,
    required this.onTap,
    required this.onDrop,
  });

  final DateTime day;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final ValueChanged<MealPlanEntry> onDrop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isToday = isSameDay(day, today());
    return DragTarget<MealPlanEntry>(
      onWillAcceptWithDetails: (d) => !isSameDay(d.data.date, day),
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        final fg = selected ? colors.paper : colors.ink;
        return AnimatedScale(
          scale: hovering ? 1.08 : 1,
          duration: const Duration(milliseconds: 150),
          child: Material(
            color: selected ? colors.ink : colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.sm),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hovering
                        ? colors.violet
                        : isToday && !selected
                            ? colors.violet
                            : Colors.transparent,
                    width: hovering ? 2.5 : 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      weekdayShort(day).toUpperCase(),
                      style: context.texts.labelSmall?.copyWith(
                        color: fg.withValues(alpha: selected ? 0.8 : 0.6),
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: context.texts.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < count.clamp(0, 3); i++)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? colors.paper : colors.violet,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Uma refeição do dia: cabeçalho com "+", as receitas agendadas (ou uma
/// dica) e alvo de soltar pra mover outra refeição pra cá.
class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onDrop,
    required this.buildTile,
  });

  final MealType meal;
  final List<MealPlanEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<MealPlanEntry> onDrop;
  final Widget Function(MealPlanEntry) buildTile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DragTarget<MealPlanEntry>(
      onWillAcceptWithDetails: (d) => d.data.mealType != meal,
      onAcceptWithDetails: (d) => onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(top: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hovering ? colors.violet : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      meal.label.toUpperCase(),
                      style: context.texts.labelMedium?.copyWith(
                        color: colors.violet,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Agendar em ${meal.label}',
                    onPressed: onAdd,
                    icon: Icon(Icons.add_circle_outline, color: colors.ink),
                  ),
                ],
              ),
              if (entries.isEmpty)
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      'Nada planejado',
                      style: context.texts.bodyMedium
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ),
                )
              else
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: buildTile(e),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Uma receita agendada. À esquerda o nome sobre o azulejo da receita (cor e
/// textura dela, o mesmo bloco que voa pro detalhe ao abrir); à direita, na
/// faixa `paperSoft`, a bolinha de "feita" e o ⋯. Segurar e arrastar move;
/// deslizar pra direita marca feita, pra esquerda remove (com desfazer).
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.useHero,
    required this.onOpen,
    required this.onToggleDone,
    required this.onRemove,
    required this.onMenu,
  });

  final MealPlanEntry entry;

  /// Só um card por receita na tela leva o `Hero` (tags não podem repetir).
  final bool useHero;
  final VoidCallback onOpen;
  final VoidCallback onToggleDone;
  final VoidCallback onRemove;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadii.md);
    return LongPressDraggable<MealPlanEntry>(
      data: entry,
      hapticFeedbackOnStart: true,
      feedback: _DragGhost(name: entry.recipeName),
      childWhenDragging: Opacity(opacity: 0.35, child: _buildCard(context)),
      child: ClipRRect(
        borderRadius: radius,
        child: Dismissible(
          key: ValueKey('meal-${entry.id}'),
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.3,
            DismissDirection.endToStart: 0.4,
          },
          background: SwipeActionBackground(
            alignment: Alignment.centerLeft,
            icon: entry.done ? Icons.undo : Icons.check,
            label: entry.done ? 'Desfazer' : 'Feita',
            color: colors.violet,
            borderRadius: radius,
          ),
          secondaryBackground: SwipeActionBackground(
            alignment: Alignment.centerRight,
            icon: Icons.delete_outline,
            label: 'Remover',
            color: colors.danger,
            borderRadius: radius,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              HapticFeedback.selectionClick();
              onToggleDone();
              return false;
            }
            return true;
          },
          onDismissed: (_) => onRemove(),
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildNameTile(context)),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// Nome sobre o azulejo. O `ColoredBox` fica fora do `Hero` (mesmo truque
  /// do `RecipeCard`): enquanto o padrão voa, esta cópia parada da cor cobre
  /// o buraco e o nome não fica solto sobre o `paperSoft`.
  Widget _buildNameTile(BuildContext context) {
    final colors = context.colors;
    final recipe = entry.recipe;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );
    final pattern = TilePattern(
      motif: tile.motif,
      background: tile.background,
      patternColor: tile.patternColor,
      patternColorAlt: tile.patternColorAlt,
    );
    return InkWell(
      onTap: onOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: entry.done ? 0.5 : 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: tile.background,
                child: useHero
                    ? Hero(
                        tag: recipeTileHeroTag(recipe.id),
                        flightShuttleBuilder:
                            recipeTileHeroFlightShuttleBuilder,
                        child: pattern,
                      )
                    : pattern,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Center(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    recipe.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.titleMedium?.copyWith(
                      color: tile.onColor,
                      fontWeight: FontWeight.w700,
                      decoration:
                          entry.done ? TextDecoration.lineThrough : null,
                      decorationColor: tile.onColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;
    final done = entry.done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggleDone,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? colors.ink : Colors.transparent,
                border: Border.all(
                  color: done ? colors.ink : colors.textMuted,
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(Icons.check, size: 16, color: colors.paper)
                  : null,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Mais opções',
          onPressed: onMenu,
          icon: Icon(Icons.more_horiz, color: colors.textMuted),
        ),
      ],
    );
  }
}

/// Cartãozinho que acompanha o dedo ao arrastar uma refeição.
class _DragGhost extends StatelessWidget {
  const _DragGhost({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      elevation: 6,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.labelLarge?.copyWith(color: colors.paper),
          ),
        ),
      ),
    );
  }
}
