import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/metric_stat.dart';
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

    return Scaffold(
      backgroundColor: context.colors.paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Hero(recipe: recipe)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -AppSpacing.screen),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.paper,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.lg),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.lg,
                  AppSpacing.screen,
                  AppSpacing.xxl,
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
                      _Label('Ingredientes'),
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
                    if (detail.steps.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      _Label('Passos'),
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
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.recipe});

  final Recipe recipe;

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
              color: colors.onSaturated,
              corner: Alignment.bottomRight,
              size: 120,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        color: colors.onSaturated,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () =>
                            context.push('/recipe/${recipe.id}/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        color: colors.onSaturated,
                        tooltip: 'Editar',
                      ),
                    ],
                  ),
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
    final stats = <Widget>[
      if (recipe.prepMinutes != null)
        MetricStat(
          value: '${recipe.prepMinutes}',
          unit: ' min',
          label: 'Preparo',
        ),
      if (recipe.cookMinutes != null)
        MetricStat(
          value: '${recipe.cookMinutes}',
          unit: ' min',
          label: 'Cozimento',
        ),
      if (recipe.servings != null)
        MetricStat(value: '${recipe.servings}', label: 'Porções'),
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.md, children: stats);
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$index',
              style: AppTextStyles.display(30)
                  .copyWith(color: context.colors.coral),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
              child: Text(text, style: context.texts.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
