import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/screens/cost_notes.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/period_strip.dart';
import 'package:receyta/widgets/underline_tabs.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Quanto custam as refeições planejadas na semana ou no mês. Uma leitura só,
/// de cima pra baixo: o total (com o que falta pra ele ficar completo), depois
/// "onde foi o dinheiro" — por receita ou por ingrediente, escolhendo no
/// seletor — e, no fim, um link pro "como é calculado".
class CostsPage extends ConsumerStatefulWidget {
  const CostsPage({super.key, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  ConsumerState<CostsPage> createState() => _CostsPageState();
}

class _CostsPageState extends ConsumerState<CostsPage> {
  late CostPeriod _period = CostPeriod.weekOf(widget._clock());

  /// Um dia dentro do período olhado. Trocar Semana/Mês procura o período do
  /// novo tipo que contém este dia — assim alternar de um pro outro e voltar
  /// cai no mesmo lugar, em vez de ir derivando.
  late DateTime _anchor = widget._clock();
  _Mode _mode = _Mode.planned;

  static const _weeksShown = 26;
  static const _monthsShown = 24;

  void _setKind(CostKind kind) {
    if (kind == _period.kind) return;
    setState(() {
      _period = kind == CostKind.week
          ? CostPeriod.weekOf(_anchor)
          : CostPeriod.monthOf(_anchor);
    });
  }

  /// Escolher um período na faixa: hoje, se ele cai ali; senão o dia âncora
  /// atual, se ele já cai ali; senão o primeiro dia do período.
  void _select(CostPeriod p) {
    final today = widget._clock();
    bool inside(DateTime day) {
      final d = dayOf(day);
      return !d.isBefore(p.start) && d.isBefore(p.end);
    }

    setState(() {
      _period = p;
      if (inside(today)) {
        _anchor = today;
      } else if (!inside(_anchor)) {
        _anchor = p.start;
      }
    });
  }

  /// Os períodos da faixa: do mais antigo ao atual.
  List<CostPeriod> get _periods {
    final current = _period.containing(widget._clock());
    final count = _period.kind == CostKind.week ? _weeksShown : _monthsShown;
    return [for (var i = count - 1; i >= 0; i--) current.shift(-i)];
  }

  PeriodChoice _choiceFor(CostPeriod p) {
    final id = dayToParam(p.start);
    if (p.kind == CostKind.week) {
      final last = addDays(p.start, 6);
      return PeriodChoice(
        id: id,
        label: '${p.start.day}–${last.day}',
        caption: monthShort(last),
      );
    }
    final short = monthShort(p.start);
    return PeriodChoice(
      id: id,
      label: short[0].toUpperCase() + short.substring(1),
      caption: '${p.start.year}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return HeaderScaffold(
      title: 'Custos',
      color: TileColor.lime,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: UnderlineTabs(
              tabs: const [
                UnderlineTab(
                  label: 'Planejado',
                  icon: Icons.calendar_today_outlined,
                ),
                UnderlineTab(
                  label: 'Mais caras',
                  icon: Icons.trending_up_rounded,
                ),
              ],
              selected: _mode.index,
              onChanged: (i) => setState(() => _mode = _Mode.values[i]),
            ),
          ),
          Expanded(
            child:
                _mode == _Mode.planned ? _buildPlanned() : const _LibraryView(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrip() {
    final periods = _periods;
    final selected = periods.indexOf(_period);
    return PeriodStrip(
      kinds: const ['Semana', 'Mês'],
      kindIndex: _period.kind.index,
      onKind: (i) => _setKind(CostKind.values[i]),
      choices: [for (final p in periods) _choiceFor(p)],
      selected: selected < 0 ? periods.length - 1 : selected,
      onSelect: (i) => _select(periods[i]),
    );
  }

  Widget _buildPlanned() {
    final plan = ref.watch(planCostProvider(_period));
    return Column(
      children: [
        _buildStrip(),
        Expanded(
          child: plan.when(
            loading: () => const Center(child: BrandLoader()),
            error: (_, __) => const _Message(
              icon: Icons.priority_high_rounded,
              title: 'Não deu para calcular os custos',
            ),
            data: (p) => _Content(plan: p, key: ValueKey(_period)),
          ),
        ),
      ],
    );
  }
}

enum _Mode { planned, library }

enum _View { recipes, ingredients }

class _Content extends StatefulWidget {
  const _Content({super.key, required this.plan});

  final PlanCost plan;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  _View _view = _View.recipes;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    if (plan.recipes.isEmpty) {
      return const _Message(
        icon: Icons.event_busy_outlined,
        title: 'Nada planejado nesse período',
        body: 'Planeje refeições na Agenda e o custo aparece aqui.',
      );
    }
    if (plan.isEmpty) {
      return _Message(
        icon: Icons.payments_outlined,
        title: 'Falta informar os preços',
        body: 'Defina quanto custa cada ingrediente (tela Ingredientes) e a '
            'conta aparece aqui.',
        action: PillButton(
          label: 'Informar preços',
          onPressed: () => context.push('/ingredients'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        _TotalCard(plan: plan),
        const SizedBox(height: AppSpacing.lg),
        Text('Onde foi o dinheiro', style: context.texts.displaySmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            ChoicePill(
              label: 'Por receita',
              selected: _view == _View.recipes,
              onTap: () => setState(() => _view = _View.recipes),
            ),
            const SizedBox(width: AppSpacing.xs),
            ChoicePill(
              label: 'Por ingrediente',
              selected: _view == _View.ingredients,
              onTap: () => setState(() => _view = _View.ingredients),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_view == _View.recipes)
          _RecipesList(plan: plan)
        else
          _IngredientsList(plan: plan),
        const SizedBox(height: AppSpacing.lg),
        const HowItWorksLink(),
      ],
    );
  }
}

/// O número que importa, grande, e embaixo — se faltar preço — o que fazer
/// pra ele ficar completo.
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.plan});

  final PlanCost plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final meals = plan.recipes.fold<int>(0, (n, r) => n + r.times);
    final missing = plan.missingNames.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missing == 0 ? 'TOTAL ESTIMADO' : 'ESTIMATIVA MÍNIMA',
                  style: context.texts.labelSmall
                      ?.copyWith(color: colors.onSaturated),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(plan.totalCents),
                    style: AppTextStyles.display(60)
                        .copyWith(color: colors.lime, height: 1),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meals == 1
                      ? '1 refeição planejada'
                      : '$meals refeições planejadas',
                  style: context.texts.bodyMedium
                      ?.copyWith(color: colors.onSaturated),
                ),
              ],
            ),
          ),
          if (missing > 0)
            InkWell(
              onTap: () => context.push('/ingredients'),
              child: Container(
                color: colors.inkSoft,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: colors.lime),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        missing == 1
                            ? 'Falta o preço de 1 ingrediente'
                            : 'Faltam os preços de $missing ingredientes',
                        style: context.texts.bodyMedium?.copyWith(
                          color: colors.onSaturated,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Informar',
                      style: context.texts.labelLarge
                          ?.copyWith(color: colors.lime),
                    ),
                    Icon(Icons.chevron_right, color: colors.lime),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ranking das receitas de preço completo (a primeira leva a etiqueta "Mais
/// cara"); as incompletas ficam num grupo à parte, sem valor.
class _RecipesList extends StatelessWidget {
  const _RecipesList({required this.plan});

  final PlanCost plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ranked = plan.rankable.take(8).toList();
    final max = ranked.isEmpty ? 1 : ranked.first.cents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in ranked.indexed)
          _RankRow(
            position: i + 1,
            label: r.times > 1 ? '${r.name} ×${r.times}' : r.name,
            cents: r.cents,
            fraction: max == 0 ? 0 : r.cents / max,
            badge: i == 0 && ranked.length > 1 ? 'MAIS CARA' : null,
            onTap: () => context.push('/recipe/${r.recipeId}'),
          ),
        if (ranked.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'Nenhuma receita planejada tem o preço de todos os ingredientes '
              'ainda.',
              style:
                  context.texts.bodyMedium?.copyWith(color: colors.textMuted),
            ),
          ),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  const _IngredientsList({required this.plan});

  final PlanCost plan;

  @override
  Widget build(BuildContext context) {
    final top = plan.ingredients.take(8).toList();
    final max = top.first.cents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, ing) in top.indexed)
          _RankRow(
            position: i + 1,
            label: ing.name,
            cents: ing.cents,
            fraction: ing.cents / max,
          ),
      ],
    );
  }
}

/// Uma linha do ranking: posição, nome, valor e uma barra proporcional ao
/// primeiro colocado.
class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.position,
    required this.label,
    required this.cents,
    required this.fraction,
    this.badge,
    this.subtitle,
    this.onTap,
  });

  final int position;
  final String label;
  final int cents;
  final double fraction;
  final String? badge;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: colors.ink, shape: BoxShape.circle),
              child: Text(
                '$position',
                style: context.texts.labelLarge?.copyWith(
                  color: colors.lime,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: context.texts.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.paper,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            border: Border.all(color: colors.ink),
                          ),
                          child: Text(
                            badge!,
                            style: context.texts.labelSmall?.copyWith(
                              color: colors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.texts.labelMedium
                          ?.copyWith(color: colors.textMuted),
                    ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: Stack(
                      children: [
                        Container(height: 8, color: colors.paperSoft),
                        FractionallySizedBox(
                          widthFactor: fraction.clamp(0.04, 1.0),
                          child: Container(height: 8, color: colors.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatMoney(cents),
              style: context.texts.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Receitas mais caras": toda a biblioteca, não só o planejado. Só entram as
/// receitas com o preço de todos os ingredientes.
class _LibraryView extends ConsumerWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryCostsProvider);
    return items.when(
      loading: () => const Center(child: BrandLoader()),
      error: (_, __) => const _Message(
        icon: Icons.priority_high_rounded,
        title: 'Não deu para calcular os custos',
      ),
      data: (list) {
        if (list.isEmpty) {
          return _Message(
            icon: Icons.payments_outlined,
            title: 'Nenhuma receita com preço completo',
            body: 'Informe o preço de todos os ingredientes de uma receita e '
                'ela aparece aqui, da mais cara à mais barata.',
            action: PillButton(
              label: 'Informar preços',
              onPressed: () => context.push('/ingredients'),
            ),
          );
        }
        final max = list.first.cents;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          children: [
            Text(
              list.length == 1
                  ? '1 receita com preço completo'
                  : '${list.length} receitas com preço completo',
              style: context.texts.displaySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final (i, item) in list.indexed)
              _RankRow(
                position: i + 1,
                label: item.recipe.name,
                subtitle: item.perServing == null
                    ? null
                    : '${formatMoney(item.perServing!)} por porção',
                cents: item.cents,
                fraction: max == 0 ? 0 : item.cents / max,
                badge: i == 0 && list.length > 1 ? 'MAIS CARA' : null,
                onTap: () => context.push('/recipe/${item.recipe.id}'),
              ),
            const SizedBox(height: AppSpacing.lg),
            const HowItWorksLink(),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(
              icon: icon,
              background: colors.ink,
              foreground: colors.lime,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body!,
                style: context.texts.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
