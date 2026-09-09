import 'package:flutter/material.dart';

import 'package:receyta/features/recipes/sample_recipes.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/folder_tile.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Home da seção Receitas (§9.2). B2 usa dados falsos; o B3 liga no repositório.
class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            activeFilter: _filter,
            onFilter: (i) => setState(() => _filter = i),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.md,
            AppSpacing.screen,
            0,
          ),
          sliver: const SliverToBoxAdapter(child: _FoldersRow()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recentes',
              action: _SeeAll(onTap: () {}),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: FeaturedRecipeCard(recipe: kSampleFeatured, onTap: () {}),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            96,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => RecipeCard(
                recipe: kSampleRecents[i],
                onTap: () {},
              ),
              childCount: kSampleRecents.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.activeFilter, required this.onFilter});

  final int activeFilter;
  final ValueChanged<int> onFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      child: Container(
        color: colors.ink,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: SizedBox(
                width: 260,
                height: 260,
                child: TilePattern(
                  motif: TileMotif.arco,
                  background: colors.ink,
                  patternColor: colors.inkPattern,
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
                        Expanded(
                          child: Text(
                            '$kSampleRecipeCount RECEITAS',
                            style: context.texts.labelSmall
                                ?.copyWith(color: colors.lime),
                          ),
                        ),
                        _CircleButton(
                          icon: Icons.search,
                          onTap: () {},
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _CircleButton(
                          icon: Icons.add,
                          filled: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.display(64)
                              .copyWith(color: colors.onSaturated),
                          children: [
                            const TextSpan(text: 'Rece'),
                            TextSpan(
                              text: 'i',
                              style: TextStyle(color: colors.coral),
                            ),
                            const TextSpan(text: 'tas'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilterChips(active: activeFilter, onTap: onFilter),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: filled ? colors.lime : colors.inkSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 22,
            color: filled ? colors.ink : colors.onSaturated,
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: kSampleFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, i) {
          final selected = i == active;
          return Semantics(
            button: true,
            selected: selected,
            label: kSampleFilters[i],
            child: Material(
              color: selected ? colors.lime : colors.inkSoft,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Center(
                    child: Text(
                      kSampleFilters[i],
                      style: context.texts.labelLarge?.copyWith(
                        color: selected
                            ? colors.ink
                            : colors.onSaturated.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FoldersRow extends StatelessWidget {
  const _FoldersRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < kSampleFolders.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FolderTile(
              label: kSampleFolders[i].name,
              count: kSampleFolders[i].count,
              motif: kSampleFolders[i].motif,
              onTap: () {},
            ),
          ),
        ],
      ],
    );
  }
}

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ver todas',
              style: context.texts.labelLarge?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(width: AppSpacing.xs / 2),
            Icon(Icons.arrow_forward, size: 16, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
