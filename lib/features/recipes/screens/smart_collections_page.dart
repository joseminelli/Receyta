import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/features/recipes/screens/smart_collection_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/recipe_cover.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Todas as coleções inteligentes que têm receita hoje. Cada uma é um azulejo
/// grande na sua cor e textura, com o número de receitas em destaque e as
/// primeiras capas empilhadas — uma espiada no que tem lá dentro. Entram em
/// cascata.
class SmartCollectionsPage extends ConsumerWidget {
  const SmartCollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(smartCollectionsProvider);

    return HeaderScaffold(
      title: 'Coleções',
      subtitle: 'Listas que se montam sozinhas',
      color: TileColor.lime,
      body: collections.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Nada por aqui ainda',
                  style: context.texts.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 520,
                      mainAxisExtent: _cardHeight,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final entry = collections.entries.elementAt(i);
                        return _Entrance(
                          index: i,
                          child: _CollectionCard(
                            collection: entry.key,
                            recipes: entry.value,
                            onTap: () =>
                                context.push('/collection/${entry.key.name}'),
                          ),
                        );
                      },
                      childCount: collections.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl)),
              ],
            ),
    );
  }
}

const _cardHeight = 188.0;

/// Fade + subida leve, cada cartão um pouco depois do anterior.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 24), child: child),
      ),
      child: child,
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.recipes,
    required this.onTap,
  });

  final SmartCollection collection;
  final List<Recipe> recipes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: collection.color,
      motif: collection.motif,
    );
    final onColor = tile.onColor;
    final count = recipes.length;

    return Material(
      color: tile.background,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TilePattern(
              motif: tile.motif,
              background: tile.background,
              patternColor: tile.patternColor,
              patternColorAlt: tile.patternColorAlt,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Medallion(icon: collection.icon),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$count',
                            style: AppTextStyles.display(52)
                                .copyWith(color: onColor, height: 0.9),
                          ),
                          Text(
                            count == 1 ? 'receita' : 'receitas',
                            style: context.texts.labelLarge?.copyWith(
                              color: onColor.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    collection.title,
                    style: AppTextStyles.display(28)
                        .copyWith(color: onColor, height: 1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    collection.description,
                    style: context.texts.bodyMedium?.copyWith(
                      color: onColor.withValues(alpha: 0.88),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _CoverStack(recipes: recipes.take(3).toList()),
                      const Spacer(),
                      _Medallion(icon: Icons.arrow_forward_rounded, size: 36),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bolinha escura com o ícone em lima: o mesmo par dos atalhos do app.
class _Medallion extends StatelessWidget {
  const _Medallion({required this.icon, this.size = 44});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.ink, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: colors.lime),
    );
  }
}

/// Até três capas redondas, uma meio sobre a outra.
class _CoverStack extends StatelessWidget {
  const _CoverStack({required this.recipes});

  final List<Recipe> recipes;

  static const _size = 40.0;
  static const _step = 26.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: _size + _step * (recipes.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (final (i, r) in recipes.indexed)
            Positioned(
              left: i * _step,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.paper, width: 2.5),
                ),
                child: ClipOval(
                  child: RecipeCover(
                    recipe: r,
                    tile: resolveTileAppearance(
                      colors,
                      color: r.tileColor,
                      motif: r.tileMotif,
                      seedId: r.id,
                    ),
                    cacheWidth: 120,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
