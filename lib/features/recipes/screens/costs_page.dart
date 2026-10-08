import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/recipe_cost.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Quanto custam as refeições planejadas na semana ou no mês, e o que mais
/// pesou: a receita mais cara e os ingredientes que mais consumiram dinheiro.
/// Só conta o que tem preço informado — o que ficou de fora é apontado.
class CostsPage extends ConsumerStatefulWidget {
  const CostsPage({super.key, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  ConsumerState<CostsPage> createState() => _CostsPageState();
}

class _CostsPageState extends ConsumerState<CostsPage> {
  late CostPeriod _period = CostPeriod.weekOf(widget._clock());

  void _setKind(CostKind kind) {
    if (kind == _period.kind) return;
    setState(() {
      final today = widget._clock();
      _period = kind == CostKind.week
          ? CostPeriod.weekOf(_period.start)
          : (_period.start.month == today.month &&
                  _period.start.year == today.year
              ? CostPeriod.monthOf(today)
              : CostPeriod.monthOf(_period.start));
    });
  }

  String get _label {
    if (_period.kind == CostKind.week) return weekRangeLabel(_period.start);
    return '${monthLong(_period.start)} ${_period.start.year}';
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planCostProvider(_period));

    return HeaderScaffold(
      title: 'Custos',
      subtitle: _label,
      color: TileColor.lime,
      body: Column(
        children: [
          _PeriodBar(
            kind: _period.kind,
            onKind: _setKind,
            onPrev: () => setState(() => _period = _period.shift(-1)),
            onNext: () => setState(() => _period = _period.shift(1)),
          ),
          Expanded(
            child: plan.when(
              loading: () => const Center(child: BrandLoader()),
              error: (_, __) => const _Message(
                icon: Icons.priority_high_rounded,
                title: 'Não deu para calcular os custos',
              ),
              data: (p) => _Content(plan: p, period: _period),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.kind,
    required this.onKind,
    required this.onPrev,
    required this.onNext,
  });

  final CostKind kind;
  final ValueChanged<CostKind> onKind;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          for (final k in CostKind.values) ...[
            PillButton(
              label: k == CostKind.week ? 'Semana' : 'Mês',
              variant: k == kind
                  ? PillButtonVariant.primary
                  : PillButtonVariant.secondary,
              dense: true,
              onPressed: () => onKind(k),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Spacer(),
          IconButton(
            tooltip: 'Período anterior',
            onPressed: onPrev,
            icon: Icon(Icons.chevron_left_rounded, color: colors.ink),
          ),
          IconButton(
            tooltip: 'Próximo período',
            onPressed: onNext,
            icon: Icon(Icons.chevron_right_rounded, color: colors.ink),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.plan, required this.period});

  final PlanCost plan;
  final CostPeriod period;

  @override
  Widget build(BuildContext context) {
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

    final colors = context.colors;
    final topRecipes = plan.recipes.take(5).toList();
    final topIngredients = plan.ingredients.take(5).toList();
    final maxIngredient = topIngredients.first.cents;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.ink,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.missingNames.isEmpty ? 'TOTAL PLANEJADO' : 'PELO MENOS',
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
                '${plan.recipes.fold<int>(0, (n, r) => n + r.times)} '
                'refeições com receita',
                style: context.texts.bodyMedium
                    ?.copyWith(color: colors.onSaturated),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle('Receita mais cara'),
        _Highlight(spend: plan.recipes.first),
        const SizedBox(height: AppSpacing.md),
        _SectionTitle('Ingredientes que mais pesaram'),
        for (final i in topIngredients)
          _BarRow(
            label: i.name,
            cents: i.cents,
            fraction: i.cents / maxIngredient,
          ),
        if (topRecipes.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionTitle('Por receita'),
          for (final r in topRecipes)
            _ListRow(
              label: r.times > 1 ? '${r.name} ×${r.times}' : r.name,
              value: formatMoney(r.cents),
              onTap: () => context.push('/recipe/${r.recipeId}'),
            ),
        ],
        if (plan.missingNames.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _MissingNote(names: plan.missingNames),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: context.texts.displaySmall),
    );
  }
}

/// A receita mais cara, no azulejo coral do app.
class _Highlight extends StatelessWidget {
  const _Highlight({required this.spend});

  final RecipeSpend spend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.coral,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recipe/${spend.recipeId}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spend.name,
                      style: AppTextStyles.display(28)
                          .copyWith(color: colors.onSaturated, height: 1.05),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (spend.times > 1)
                      Text(
                        'planejada ${spend.times} vezes',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.onSaturated),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatMoney(spend.cents),
                style: AppTextStyles.display(30)
                    .copyWith(color: colors.onSaturated),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma linha com barra proporcional ao maior valor da lista.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.cents,
    required this.fraction,
  });

  final String label;
  final int cents;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatMoney(cents),
                style: context.texts.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: context.texts.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: context.texts.bodyLarge?.copyWith(color: colors.textMuted),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MissingNote extends StatelessWidget {
  const _MissingNote({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = names.take(4).join(', ');
    final extra = names.length > 4 ? ' e mais ${names.length - 4}' : '';
    return InkWell(
      onTap: () => context.push('/ingredients'),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.paperSoft,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ficaram fora da conta, sem preço ou sem como converter: '
                '$shown$extra.',
                style: context.texts.bodyMedium,
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted),
          ],
        ),
      ),
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
