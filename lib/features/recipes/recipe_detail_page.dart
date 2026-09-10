import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/metric_stat.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Tela de detalhe da receita (B6): "dá para cozinhar lendo pelo app". Hero
/// `coral` com azulejo (§9.2), sheet de conteúdo subindo 18px sobre ele
/// (§9.8). Ingredientes e passos em fundo chapado — o padrão nunca entra atrás
/// de texto que se lê linha a linha (§9.4).
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(recipeDetailProvider(recipeId)).when(
          loading: () => const Scaffold(body: SizedBox.shrink()),
          error: (_, __) => _Missing(),
          data: (detail) =>
              detail == null ? _Missing() : _Detail(detail: detail),
        );
  }
}

class _Missing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Text('Receita não encontrada', style: context.texts.bodyMedium),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context) {
    final recipe = detail.recipe;

    final colors = context.colors;
    final hasSteps = detail.steps.isNotEmpty;

    return Scaffold(
      backgroundColor: colors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Hero(recipe: recipe, tags: detail.tags),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -AppSpacing.screen),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.paper,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadii.lg),
                      ),
                      border: Border.all(color: colors.paperSoft, width: 1.5),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.lg,
                      AppSpacing.screen,
                      hasSteps ? 120 : AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Metrics(recipe: recipe),
                        if ((recipe.about ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(recipe.about!, style: context.texts.bodyLarge),
                        ],
                        if (detail.ingredients.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          SectionHeader(
                            title: 'Ingredientes',
                            action: _CountPill(detail.ingredients.length, 'item',
                                'itens'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (final i in detail.ingredients)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Text(
                                i.rawText,
                                style: context.texts.bodyLarge,
                              ),
                            ),
                        ],
                        if (hasSteps) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _Label('Preparo'),
                          const SizedBox(height: AppSpacing.sm),
                          for (var s = 0; s < detail.steps.length; s++)
                            _Step(index: s + 1, text: detail.steps[s].text),
                        ],
                        if ((recipe.notes ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          _Label('Notas'),
                          const SizedBox(height: AppSpacing.sm),
                          Text(recipe.notes!, style: context.texts.bodyLarge),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasSteps)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CookBar(recipeId: recipe.id),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.recipe, this.tags = const []});

  final Recipe recipe;
  final List<Tag> tags;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final minutes = _totalMinutes;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: TilePattern(
              motif: TileMotif.arco,
              background: colors.coral,
              patternColor: colors.coralPattern,
            ),
          ),
          if (minutes != null)
            HeroNumber(
              value: '$minutes',
              color: colors.onSaturated.withValues(alpha: 0.16),
              corner: Alignment.topRight,
              size: 150,
            ),
          SafeArea(
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
                      _HeroCircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => context.pop(),
                        tooltip: 'Voltar',
                      ),
                      const Spacer(),
                      _HeroCircleButton(
                        icon: Icons.edit_outlined,
                        onTap: () =>
                            context.push('/recipe/${recipe.id}/edit'),
                        tooltip: 'Editar',
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [for (final t in tags) _TagPill(t.name)],
                    ),
                  ],
                  const Spacer(),
                  Text(
                    recipe.name,
                    style: AppTextStyles.display(44)
                        .copyWith(color: colors.onSaturated),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final stats = <Widget>[
      if (recipe.prepMinutes != null)
        MetricStat(
          value: '${recipe.prepMinutes}',
          unit: 'm',
          label: 'Preparo',
          valueSize: size,
        ),
      if (recipe.cookMinutes != null)
        MetricStat(
          value: '${recipe.cookMinutes}',
          unit: 'm',
          label: 'Fogão',
          valueSize: size,
        ),
      if (recipe.servings != null)
        MetricStat(
          value: '${recipe.servings}',
          label: 'Porções',
          valueSize: size,
        ),
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: stats,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: context.colors.paperSoft),
      ],
    );
  }
}

/// Tag sobre o hero `coral`: pílula `lime` com texto `ink` (§9.2 — lime só
/// aparece sobre bloco escuro ou saturado, nunca sobre `paper`).
class _TagPill extends StatelessWidget {
  const _TagPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.lime,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: context.texts.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.ink,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.texts.displaySmall);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$index'.padLeft(2, '0'),
              style: AppTextStyles.display(34)
                  .copyWith(color: context.colors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(text, style: context.texts.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão circular preenchido sobre o hero — voltar e editar (screenshot B6).
class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, size: 22, color: colors.onSaturated),
          ),
        ),
      ),
    );
  }
}

/// Contagem discreta ao lado de um título de seção ("6 itens").
class _CountPill extends StatelessWidget {
  const _CountPill(this.count, this.singular, this.plural);

  final int count;
  final String singular;
  final String plural;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '$count ${count == 1 ? singular : plural}',
        style: context.texts.labelLarge?.copyWith(color: colors.textBody),
      ),
    );
  }
}

/// Barra fixa no rodapé: abre o modo cozinha (§RF-01.11).
class _CookBar extends StatelessWidget {
  const _CookBar({required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.paper,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Material(
            color: colors.ink,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: InkWell(
              onTap: () => context.push('/recipe/$recipeId/cook'),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Container(
                height: AppSpacing.minTapTarget + 6,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 20, color: colors.lime),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Modo cozinha',
                      style: context.texts.labelLarge
                          ?.copyWith(color: colors.lime),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
