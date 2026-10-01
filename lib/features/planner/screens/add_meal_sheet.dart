import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/day.dart';
import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/meal_plan_repository.dart';
import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/meal_plan_entry.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Agenda uma receita em [day]: escolhe a refeição, busca na lista e toca na
/// receita (RF-04.2). Fecha ao agendar.
Future<void> showAddMealSheet(
  BuildContext context, {
  required DateTime day,
  required MealType initialMeal,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _AddMealSheet(day: day, initialMeal: initialMeal),
  );
}

class _AddMealSheet extends ConsumerStatefulWidget {
  const _AddMealSheet({required this.day, required this.initialMeal});

  final DateTime day;
  final MealType initialMeal;

  @override
  ConsumerState<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends ConsumerState<_AddMealSheet> {
  late MealType _meal = widget.initialMeal;
  String _query = '';

  Future<void> _add(Recipe recipe) async {
    final result = await ref
        .read(mealPlanRepositoryProvider)
        .add(recipe.id, widget.day, _meal);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (result is Err<String>) {
      showAppSnackBar(
        message: result.failure.message,
        variant: AppSnackBarVariant.error,
      );
    }
  }

  List<Recipe> _filtered(List<Recipe> all) {
    final q = stripAccents(_query.trim().toLowerCase());
    if (q.isEmpty) return all;
    return [
      for (final r in all)
        if (stripAccents(r.name.toLowerCase()).contains(q)) r,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filtered(
      ref.watch(allRecipesProvider).valueOrNull ?? const <Recipe>[],
    );
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Text(
                  'Agendar em ${weekdayShort(widget.day)} ${widget.day.day} '
                  '${monthShort(widget.day)}',
                  style: context.texts.titleLarge,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final m in MealType.values)
                      ChoicePill(
                        label: m.label,
                        selected: m == _meal,
                        onTap: () => setState(() => _meal = m),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Buscar receita',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Flexible(
                child: recipes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Você ainda não tem receitas.'
                                : 'Nenhuma receita com esse nome.',
                            style: context.texts.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: recipes.length,
                        itemBuilder: (context, i) => ListTile(
                          title: Text(
                            recipes[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: _timeLabel(recipes[i]) == null
                              ? null
                              : Text(_timeLabel(recipes[i])!),
                          onTap: () => _add(recipes[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _timeLabel(Recipe r) {
    final total = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
    return total == 0 ? null : '$total min';
  }
}
