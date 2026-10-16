import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/controllers/ingredients_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/brand_loader.dart';

/// Lista as receitas que usam o [ingredient]; tocar numa abre a receita. As da
/// lixeira aparecem apagadas, sem toque.
Future<void> showIngredientRecipesSheet(
  BuildContext context,
  Ingredient ingredient,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _RecipesSheet(ingredient: ingredient),
  );
}

class _RecipesSheet extends ConsumerWidget {
  const _RecipesSheet({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesUsingIngredientProvider(ingredient.id));
    return AppSheetFrame(
      title: ingredient.displayName,
      subtitle: 'Receitas que usam este ingrediente',
      scrollable: true,
      child: recipes.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: BrandLoader()),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Não deu para carregar as receitas',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.textMuted),
          ),
        ),
        data: (rows) => AppSheetOptions(
          children: [
            for (final r in rows)
              AppSheetOption(
                icon: Icons.menu_book_outlined,
                title: r.name,
                subtitle: r.inTrash ? 'Na lixeira' : null,
                enabled: !r.inTrash,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/recipe/${r.id}');
                },
              ),
          ],
        ),
      ),
    );
  }
}
