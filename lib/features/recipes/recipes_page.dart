import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/features/recipes/sample_recipes.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/section_header.dart';

/// Grade x lista. Em memória por ora — persistir fica para as configurações.
final recipesLayoutProvider = StateProvider<RecipeCardLayout>(
  (ref) => RecipeCardLayout.grid,
);

/// Lista da seção Receitas. B2 usa `kSampleRecipes`; o B3 troca pelo repositório.
class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(recipesLayoutProvider);
    final recipes = kSampleRecipes;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Receitas',
                  action: PillButton(
                    label: 'Nova',
                    icon: Icons.add,
                    dense: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: _LayoutToggle(
                    value: layout,
                    onChanged: (v) =>
                        ref.read(recipesLayoutProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            96,
          ),
          sliver: layout == RecipeCardLayout.grid
              ? SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => RecipeCard(recipe: recipes[i]),
                    childCount: recipes.length,
                  ),
                )
              : SliverList.separated(
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => RecipeCard(
                    recipe: recipes[i],
                    layout: RecipeCardLayout.list,
                  ),
                ),
        ),
      ],
    );
  }
}

class _LayoutToggle extends StatelessWidget {
  const _LayoutToggle({required this.value, required this.onChanged});

  final RecipeCardLayout value;
  final ValueChanged<RecipeCardLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget segment(RecipeCardLayout layout, IconData icon, String label) {
      final selected = layout == value;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: () => onChanged(layout),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: selected ? colors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Icon(
              icon,
              size: 18,
              color: selected ? colors.paper : colors.textMuted,
            ),
          ),
        ),
      );
    }

    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment(RecipeCardLayout.grid, Icons.grid_view_rounded, 'Grade'),
            segment(RecipeCardLayout.list, Icons.view_agenda_rounded, 'Lista'),
          ],
        ),
      ),
    );
  }
}
