import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/services/day_export_service.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/planner_suggestion.dart';
import 'package:receyta/features/planner/controllers/planner_view_model.dart';
import 'package:receyta/features/planner/screens/add_meal_sheet.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/planner/screens/shared_meal_sheet.dart';
import 'package:receyta/features/space/controllers/space_controller.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/period_stepper.dart';
import 'package:receyta/widgets/slide_pager.dart';
import 'package:receyta/widgets/swipe_action_background.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Tela do dia (§RF-04.2/04.3), segunda etapa do planejamento: as quatro
/// refeições (café, almoço, jantar, lanche) com as receitas agendadas. Rota
/// empilhada aberta pelo calendário do mês; as setas do topo andam de dia em
/// dia sem voltar. Agendar é pelo "+" de cada refeição; mover entre refeições
/// do dia é arrastar o card, e pro resto (outro dia) o menu ⋯.
class DayPage extends ConsumerStatefulWidget {
  const DayPage({super.key, required this.initialDay});

  final DateTime initialDay;

  @override
  ConsumerState<DayPage> createState() => _DayPageState();
}

class _DayPageState extends ConsumerState<DayPage> {
  late DateTime _day = dayOf(widget.initialDay);

  /// O cabeçalho também arrasta o dia: repassa o gesto pro pager do corpo.
  final _pagerKey = GlobalKey<SlidePagerState>();

  /// Refeições já deslizadas pra fora: somem na hora (o `Dismissible` exige
  /// sair da árvore) enquanto o banco apaga e o stream não reemitiu.
  final _removed = <String>{};

  MealPlanRepository get _repo => ref.read(mealPlanRepositoryProvider);

  void _shiftDay(int days) => setState(() => _day = addDays(_day, days));

  /// Gera a imagem do dia e já abre o menu de compartilhar.
  Future<void> _shareDay() async {
    final entries = ref.read(dayEntriesProvider(_day)).valueOrNull ??
        const <MealPlanEntry>[];
    if (entries.isEmpty) return;
    final result =
        await ref.read(dayExportServiceProvider).shareDay(_day, entries);
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Os dias vizinhos já carregam: o dedo puxa uma página pronta.
    ref.watch(dayEntriesProvider(addDays(_day, -1)));
    ref.watch(dayEntriesProvider(addDays(_day, 1)));

    final count = ref.watch(dayEntriesProvider(_day)).valueOrNull?.length ?? 0;

    // Cabeçalho violeta: hora e bateria em branco, então a barra do sistema
    // é a "sobre fundo escuro" (`onDark`).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemBars.onDark,
      child: Scaffold(
        backgroundColor: colors.paper,
        body: Column(
          children: [
            _buildHeader(context, count),
            Expanded(
              child: SlidePager(
                key: _pagerKey,
                index: dayIndex(_day),
                onChanged: (i) => setState(() => _day = dayFromIndex(i)),
                builder: (i) => _buildDayBody(dayFromIndex(i)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Um dia inteiro (as refeições dele). Cada página observa o próprio dia —
  /// por isso a que está saindo, durante o deslize, não troca de conteúdo.
  Widget _buildDayBody(DateTime day) {
    return Consumer(
      builder: (context, ref, _) {
        final entriesAsync = ref.watch(dayEntriesProvider(day));
        final entries = [
          for (final e in entriesAsync.valueOrNull ?? const <MealPlanEntry>[])
            if (!_removed.contains(e.id)) e,
        ];
        return entriesAsync.isLoading && entries.isEmpty
            ? const Center(child: BrandLoader())
            : _buildMeals(context, day, entries);
      },
    );
  }

  /// Cabeçalho do dia: bloco violeta com a textura meia-lua (mesma linguagem
  /// do cabeçalho de pasta), o dia em letra grande e o controle ‹ Hoje ›.
  Widget _buildHeader(BuildContext context, int count) {
    final tile = resolveTileAppearance(
      context.colors,
      color: TileColor.violet,
      motif: TileMotif.meiaLua,
    );
    final onColor = tile.onColor;
    final isToday = isSameDay(_day, today());
    final eyebrow = isToday
        ? '${weekdayLong(_day).toUpperCase()}  ·  HOJE'
        : weekdayLong(_day).toUpperCase();
    final summary = count == 0
        ? 'Nada planejado ainda'
        : '$count ${count == 1 ? 'refeição' : 'refeições'}';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (d) =>
          _pagerKey.currentState?.handleDragUpdate(d),
      onHorizontalDragEnd: (d) => _pagerKey.currentState?.handleDragEnd(d),
      onHorizontalDragCancel: () => _pagerKey.currentState?.handleDragCancel(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg),
        ),
        child: Container(
          color: tile.background,
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: TilePattern(
                    motif: tile.motif,
                    background: tile.background,
                    patternColor: tile.patternColor,
                    patternColorAlt: tile.patternColorAlt,
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
                      Row(
                        children: [
                          CircleIconButton(
                            icon: Icons.arrow_back,
                            tooltip: 'Voltar',
                            background: context.colors.paper,
                            foreground: context.colors.ink,
                            onTap: () => context.pop(),
                          ),
                          const Spacer(),
                          if (count > 0) ...[
                            CircleIconButton(
                              icon: Icons.ios_share,
                              tooltip: 'Compartilhar o dia como imagem',
                              background: context.colors.paper,
                              foreground: context.colors.ink,
                              onTap: _shareDay,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          PeriodStepper(
                            atToday: isToday,
                            previousTooltip: 'Dia anterior',
                            nextTooltip: 'Próximo dia',
                            onPrevious: () => _shiftDay(-1),
                            onNext: () => _shiftDay(1),
                            onToday: () => setState(() => _day = today()),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        eyebrow,
                        style: context.texts.labelSmall?.copyWith(
                          color: onColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_day.day} de ${monthLong(_day).toLowerCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.display(40).copyWith(color: onColor),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        summary,
                        style: context.texts.bodyMedium
                            ?.copyWith(color: onColor.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeals(
    BuildContext context,
    DateTime day,
    List<MealPlanEntry> entries,
  ) {
    final myName = ref.read(spaceControllerProvider.notifier).displayName();
    // Duas refeições do mesmo dia com a mesma receita dividiriam a tag do
    // Hero (o Flutter recusa); só a primeira ocorrência do dia voa.
    final heroOwners = <String, String>{};
    for (final meal in MealType.values) {
      for (final e in entries.where((e) => e.mealType == meal)) {
        heroOwners.putIfAbsent(e.recipeId, () => e.id);
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        for (final meal in MealType.values)
          _MealSection(
            meal: meal,
            entries: [
              for (final e in entries)
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
              authorLabel: entry.sharedBy ?? myName,
              useHero: heroOwners[entry.recipeId] == entry.id,
              onOpen: () => entry.isFromOther
                  ? showSharedMealSheet(context, ref, entry)
                  : context.push(
                      '/recipe/${entry.recipeId}',
                      extra: entry.recipe,
                    ),
              onToggleDone: () => _repo.setDone(entry.id, !entry.done),
              onRemove: () => _remove(entry),
              onMenu: () => _openMenu(entry),
            ),
          ),
        _SuggestionsSection(day: day, dayEntries: entries),
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
      builder: (sheet) => AppSheetFrame(
        title: entry.recipeName,
        subtitle: entry.sharedBy == null
            ? entry.mealType.label
            : '${entry.mealType.label} · ${entry.sharedBy}',
        child: AppSheetOptions(
          children: [
            AppSheetOption(
              icon: Icons.drive_file_move_outline,
              title: 'Mover para…',
              onTap: () {
                Navigator.of(sheet).pop();
                _moveFlow(entry);
              },
            ),
            if (entry.isFromOther)
              AppSheetOption(
                icon: Icons.menu_book_outlined,
                title: 'Ver a receita',
                subtitle: 'Ingredientes e preparo, e guardar',
                onTap: () {
                  Navigator.of(sheet).pop();
                  showSharedMealSheet(context, ref, entry);
                },
              )
            else
              AppSheetOption(
                icon: Icons.copy_all_outlined,
                title: 'Duplicar para…',
                onTap: () {
                  Navigator.of(sheet).pop();
                  _duplicateFlow(entry);
                },
              ),
            AppSheetOption(
              icon: Icons.delete_outline,
              title: 'Remover do plano',
              danger: true,
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
      weekStart: mondayOf(_day),
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
      weekStart: mondayOf(_day),
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

  void _reportError(String message) => showAppSnackBar(
        message: message,
        variant: AppSnackBarVariant.error,
      );
}

/// "Sugestões" do dia (F5, RF-04.4): até três receitas que dividem
/// ingredientes com o que você já vai comprar na semana, cada uma com o motivo
/// escrito. Tocar abre a receita; o "+" agenda no almoço (ou na primeira
/// refeição vazia) com "Desfazer". Some quando não há o que sugerir — semana
/// sem nada pendente, ou nenhuma receita em comum.
class _SuggestionsSection extends ConsumerWidget {
  const _SuggestionsSection({required this.day, required this.dayEntries});

  final DateTime day;
  final List<MealPlanEntry> dayEntries;

  Future<void> _schedule(
    BuildContext context,
    WidgetRef ref,
    PlannerSuggestion s,
  ) async {
    final repo = ref.read(mealPlanRepositoryProvider);
    final meal = defaultMealFor(dayEntries);
    HapticFeedback.selectionClick();
    final result = await repo.add(s.recipe.id, day, meal);
    result.when(
      ok: (id) => showAppSnackBar(
        message: '${s.recipe.name} agendado em ${meal.label}',
        actionLabel: 'Desfazer',
        onAction: () => repo.remove(id),
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(daySuggestionsProvider(day)).valueOrNull ??
        const <PlannerSuggestion>[];
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SUGESTÕES',
            style: context.texts.labelMedium
                ?.copyWith(color: colors.violet, letterSpacing: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            'Com o que você já vai comprar nesta semana',
            style: context.texts.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final s in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _SuggestionCard(
                suggestion: s,
                onOpen: () => context.push(
                  '/recipe/${s.recipe.id}',
                  extra: s.recipe,
                ),
                onAdd: () => _schedule(context, ref, s),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onOpen,
    required this.onAdd,
  });

  final PlannerSuggestion suggestion;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final recipe = suggestion.recipe;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: colors.paperSoft,
        child: InkWell(
          onTap: onOpen,
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        suggestion.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              CircleIconButton(
                icon: Icons.add,
                tooltip: 'Agendar ${recipe.name}',
                onTap: onAdd,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
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
    required this.authorLabel,
    required this.useHero,
    required this.onOpen,
    required this.onToggleDone,
    required this.onRemove,
    required this.onMenu,
  });

  final MealPlanEntry entry;
  final String authorLabel;

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
      child: Stack(
        children: [
          // O azulejo vai até a borda direita; a faixa de ações fica por cima
          // dele, com os cantos da esquerda arredondados e uma sombra leve —
          // parece uma folha branca sobre o colorido.
          // Sem `IntrinsicHeight`: o próprio azulejo (fundo `Positioned.fill`
          // + o nome) define a altura, e a faixa de ações, `Positioned` com
          // top/bottom, acompanha.
          Padding(
            padding: const EdgeInsets.only(
              right: _actionsWidth - _actionsOverlap,
            ),
            child: _buildNameTile(context),
          ),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: _actionsWidth,
            child: _buildActions(context),
          ),
        ],
      ),
    );
  }

  /// Largura da faixa de ações (bolinha + ⋯) e quanto dela entra sobre o
  /// azulejo.
  static const _actionsWidth = 96.0;
  static const _actionsOverlap = 20.0;

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md + _actionsOverlap,
                AppSpacing.sm,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Center(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
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
                        if (entry.spaceId != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_alt_outlined,
                                  size: 14,
                                  color: tile.onColor.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    authorLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.texts.labelSmall?.copyWith(
                                      color:
                                          tile.onColor.withValues(alpha: 0.85),
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final colors = context.colors;
    final done = entry.done;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppRadii.md),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
      ),
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
