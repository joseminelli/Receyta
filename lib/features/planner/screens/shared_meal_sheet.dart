import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/shared_meal_codec.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Abre os ingredientes e o preparo de uma refeição que OUTRA pessoa da casa
/// planejou (a receita não está na biblioteca daqui, só o resumo que viajou
/// com a refeição), com a opção de guardá-la como receita própria.
Future<void> showSharedMealSheet(
  BuildContext context,
  WidgetRef ref,
  MealPlanEntry entry,
) async {
  final recipe =
      await ref.read(mealPlanRepositoryProvider).sharedRecipeOf(entry.id);
  if (!context.mounted) return;
  if (recipe == null) {
    showAppSnackBar(
      message: 'Não foi possível abrir essa receita.',
      variant: AppSnackBarVariant.error,
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _SharedMealSheet(entry: entry, recipe: recipe),
  );
}

class _SharedMealSheet extends ConsumerStatefulWidget {
  const _SharedMealSheet({required this.entry, required this.recipe});

  final MealPlanEntry entry;
  final SharedMealRecipe recipe;

  @override
  ConsumerState<_SharedMealSheet> createState() => _SharedMealSheetState();
}

class _SharedMealSheetState extends ConsumerState<_SharedMealSheet> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final r = widget.recipe;
    final result = await ref.read(recipeRepositoryProvider).saveDetail(
          name: r.name,
          about: r.about,
          prepMinutes: r.prepMinutes,
          cookMinutes: r.cookMinutes,
          servings: r.servings,
          ingredientLines: r.ingredients,
          stepLines: r.steps,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        Navigator.of(context).pop();
        showAppSnackBar(message: 'Receita guardada na sua biblioteca.');
      },
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  String? get _meta {
    final r = widget.recipe;
    final parts = [
      if (r.prepMinutes != null) 'Preparo ${r.prepMinutes} min',
      if (r.cookMinutes != null) 'Cozimento ${r.cookMinutes} min',
      if (r.servings != null) '${r.servings} porções',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final r = widget.recipe;
    final by = widget.entry.sharedBy ?? 'Alguém da casa';
    return AppSheetFrame(
      title: r.name,
      subtitle: 'Planejada por $by · ${widget.entry.mealType.label}',
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_meta != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _meta!,
                style:
                    context.texts.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ),
          if (r.about != null && r.about!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(r.about!, style: context.texts.bodyLarge),
            ),
          if (r.ingredients.isNotEmpty) ...[
            Text('Ingredientes', style: AppTextStyles.display(24)),
            const SizedBox(height: AppSpacing.xs),
            for (final line in r.ingredients)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('•  $line', style: context.texts.bodyLarge),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (r.steps.isNotEmpty) ...[
            Text('Preparo', style: AppTextStyles.display(24)),
            const SizedBox(height: AppSpacing.xs),
            for (var i = 0; i < r.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${i + 1}. ${r.steps[i]}',
                  style: context.texts.bodyLarge,
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Guardar na minha biblioteca',
            icon: Icons.bookmark_add_outlined,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
