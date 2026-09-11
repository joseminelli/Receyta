import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/folders/folder_actions.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/metric_stat.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/tile_style_picker.dart';

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
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.paper,
                    border: Border(
                      top: BorderSide(color: colors.paperSoft, width: 1.5),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.xl,
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
                          action: _CountPill(
                              detail.ingredients.length, 'item', 'itens'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._grouped(
                          detail.ingredients,
                          (i) => i.groupLabel,
                          (idx, i) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: Text(
                              i.rawText,
                              style: context.texts.bodyLarge,
                            ),
                          ),
                        ),
                      ],
                      if (hasSteps) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _Label('Preparo'),
                        const SizedBox(height: AppSpacing.sm),
                        ..._grouped(
                          detail.steps,
                          (s) => s.groupLabel,
                          (idx, s) => _Step(index: idx + 1, text: s.text),
                        ),
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

class _Hero extends ConsumerWidget {
  const _Hero({required this.recipe, this.tags = const []});

  final Recipe recipe;
  final List<Tag> tags;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(recipeRepositoryProvider);
    await repo.softDelete(recipe.id);
    if (!context.mounted) return;
    context.pop();
    showRootSnackBar(
      SnackBar(
        content: const Text('Receita movida para a lixeira'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => repo.restore(recipe.id),
        ),
      ),
    );
  }

  void _showMore(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Aparência'),
              onTap: () {
                Navigator.of(sheet).pop();
                showAppearanceSheet(
                  context,
                  title: 'Aparência de "${recipe.name}"',
                  color: recipe.tileColor,
                  motif: recipe.tileMotif,
                  fallbackColor: TileColor.coral,
                  seedId: recipe.id,
                  onChanged: (c, m) => ref
                      .read(recipeRepositoryProvider)
                      .setAppearance(recipe.id, color: c, motif: m),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Mover para pasta'),
              onTap: () {
                Navigator.of(sheet).pop();
                moveRecipeFlow(context, ref, recipe.id, recipe.folderId);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.danger),
              title: Text(
                'Mover para a lixeira',
                style: context.texts.bodyLarge?.copyWith(color: colors.danger),
              ),
              subtitle: Text(
                'Some da lista agora; apaga de vez em 30 dias.',
                style: context.texts.bodyMedium,
              ),
              onTap: () {
                Navigator.of(sheet).pop();
                _delete(context, ref);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final minutes = _totalMinutes;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );

    // Cartão de cor: canto arredondado embaixo e sombra, para ler como um bloco
    // por cima do conteúdo. `Material` cuida da sombra + clip sem brigar com o
    // shader do azulejo. `AnnotatedRegion`: hora/bateria em branco enquanto o
    // hero cobre o topo; ao rolar, o sheet claro assume e volta ao escuro.
    return AnnotatedRegion(
      value: SystemBars.onDark,
      child: Material(
        color: tile.background,
        elevation: 8,
        shadowColor: colors.ink,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned.fill(
                child: TilePattern(
                  motif: tile.motif,
                  background: tile.background,
                  patternColor: tile.patternColor,
                  patternColorAlt: tile.patternColorAlt,
                ),
              ),
              if (minutes != null)
                Transform.translate(
                  offset: const Offset(
                      -40, -20), // 40px pra esquerda, 30px pra cima
                  child: HeroNumber(
                    value: '$minutes',
                    unit: 'min',
                    color: tile.onColor.withValues(alpha: 0.5),
                    corner: Alignment.bottomRight,
                    size: 100,
                  ),
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
                            icon: recipe.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            onTap: () => ref
                                .read(recipeRepositoryProvider)
                                .setFavorite(recipe.id, !recipe.isFavorite),
                            tooltip: recipe.isFavorite
                                ? 'Desfavoritar'
                                : 'Favoritar',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _HeroCircleButton(
                            icon: Icons.edit_outlined,
                            onTap: () =>
                                context.push('/recipe/${recipe.id}/edit'),
                            tooltip: 'Editar',
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _HeroCircleButton(
                            icon: Icons.more_horiz,
                            onTap: () => _showMore(context, ref),
                            tooltip: 'Mais',
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
                            .copyWith(color: tile.onColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
}

/// Intercala subtítulos de grupo (§RF-01.4) numa lista de ingredientes ou
/// passos. `index` passado ao builder é a posição só entre os itens de verdade
/// (numeração dos passos não pula por causa dos separadores).
List<Widget> _grouped<T>(
  List<T> items,
  String? Function(T item) groupOf,
  Widget Function(int index, T item) row,
) {
  final out = <Widget>[];
  String? last;
  var i = 0;
  for (final item in items) {
    final g = groupOf(item);
    if (g != last && g != null && g.isNotEmpty) out.add(_GroupLabel(g));
    last = g;
    out.add(row(i, item));
    i++;
  }
  return out;
}

/// Separador de grupo (§RF-01.4): fonte display em `coral` (cor da seção
/// Receitas, §9.2) com um traço curto embaixo, hugando o texto.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.coral, width: 3),
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.display(19).copyWith(color: colors.coral),
          ),
        ),
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
