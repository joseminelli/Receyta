import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/core/breakpoints.dart';
import 'package:receyta/domain/engine/pantry_match.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/cost_view_model.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/features/recipes/screens/smart_collection_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/recipe_cover.dart';
import 'package:receyta/widgets/tile_appearance.dart';

/// As receitas de uma coleção inteligente, em grade. A lista se atualiza
/// sozinha: favoritar, cozinhar ou editar muda o que cai aqui.
class SmartCollectionPage extends ConsumerWidget {
  const SmartCollectionPage({super.key, required this.collection});

  final SmartCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes =
        ref.watch(smartCollectionsProvider)[collection] ?? const <Recipe>[];
    final count = recipes.length;

    return HeaderScaffold(
      title: collection.title,
      subtitle: '$count ${count == 1 ? 'receita' : 'receitas'}'
          ' · ${collection.description}',
      color: collection.color,
      body: CustomScrollView(
        slivers: [
          if (recipes.isEmpty)
            _buildEmpty(context)
          else if (collection == SmartCollection.canCook)
            _PantryList(recipes: recipes)
          else
            _buildGrid(context, recipes),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedMascot(
              kind: MascotKind.cloche,
              mood: MascotMood.sad,
              width: 120,
              semanticLabel: 'Cloche, triste',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nada aqui por enquanto',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
            if (collection == SmartCollection.canCook) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Marque o que você sempre tem na tela Ingredientes.',
                style: context.texts.bodyMedium
                    ?.copyWith(color: context.colors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Recipe> recipes) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: kGridTileMaxExtent,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, i) => RecipeCard(
            recipe: recipes[i],
            onTap: () =>
                context.push('/recipe/${recipes[i].id}', extra: recipes[i]),
          ),
          childCount: recipes.length,
        ),
      ),
    );
  }
}

/// "Dá pra fazer": uma linha por receita, com o que falta (ou "Tem tudo").
class _PantryList extends ConsumerWidget {
  const _PantryList({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(pantryMatchesProvider).valueOrNull ?? const {};
    final catalog = ref.watch(ingredientCatalogProvider);
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.screen),
      sliver: SliverList.separated(
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, i) {
          final recipe = recipes[i];
          final match = matches[recipe.id];
          return _PantryRow(
            recipe: recipe,
            caption: match == null ? '' : _caption(match, catalog),
            hasEverything: match?.hasEverything ?? false,
          );
        },
      ),
    );
  }

  static String _caption(PantryMatch m, Map<String, Ingredient> catalog) {
    if (m.hasEverything) return 'Tem tudo';
    final names = [
      for (final id in m.missingIds) catalog[id]?.displayName ?? 'ingrediente',
    ];
    return 'Falta ${names.join(' e ')}';
  }
}

class _PantryRow extends StatelessWidget {
  const _PantryRow({
    required this.recipe,
    required this.caption,
    required this.hasEverything,
  });

  final Recipe recipe;
  final String caption;
  final bool hasEverything;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/recipe/${recipe.id}', extra: recipe),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: RecipeCover(recipe: recipe, tile: tile, cacheWidth: 200),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
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
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyMedium?.copyWith(
                      color: hasEverything ? colors.onPaper : colors.textMuted,
                      fontWeight:
                          hasEverything ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
