import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/breakpoints.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/features/recipes/screens/smart_collection_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/state_badge.dart';

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
          else
            _buildGrid(context, recipes),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateBadge(
              icon: collection.icon,
              background: colors.ink,
              foreground: colors.lime,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nada aqui por enquanto',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
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
