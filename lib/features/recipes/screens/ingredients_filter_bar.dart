import 'package:flutter/material.dart';

import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Como a lista de ingredientes é ordenada.
enum IngredientSort {
  nameAsc('A a Z', 'Ordem alfabética', Icons.sort_by_alpha_outlined),
  nameDesc('Z a A', 'Alfabética invertida', Icons.sort_by_alpha_outlined),
  mostUsed('Mais usados', 'Em mais receitas primeiro', Icons.trending_up),
  leastUsed('Menos usados', 'Em menos receitas primeiro', Icons.trending_down);

  const IngredientSort(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

/// Uma categoria presente no catálogo e quantos ingredientes tem.
typedef IngredientCategoryCount = ({String slug, String label, int count});

/// Faixa de filtros da tela de ingredientes: o botão de ordenar e, ao lado, as
/// categorias em pílulas que rolam de lado ("Todas" limpa o filtro).
class IngredientsFilterBar extends StatelessWidget {
  const IngredientsFilterBar({
    super.key,
    required this.sort,
    required this.onSort,
    required this.categories,
    required this.category,
    required this.onCategory,
  });

  final IngredientSort sort;
  final ValueChanged<IngredientSort> onSort;
  final List<IngredientCategoryCount> categories;
  final String? category;
  final ValueChanged<String?> onCategory;

  Future<void> _pickSort(BuildContext context) async {
    final picked = await showModalBottomSheet<IngredientSort>(
      context: context,
      showDragHandle: true,
      builder: (_) => AppSheetFrame(
        title: 'Ordenar',
        child: AppSheetOptions(
          children: [
            for (final s in IngredientSort.values)
              AppSheetOption(
                icon: s.icon,
                title: s.label,
                subtitle: s.description,
                selected: s == sort,
                onTap: () => Navigator.of(context).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onSort(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: [
          Semantics(
            button: true,
            label: 'Ordenar: ${sort.label}',
            child: Material(
              color: colors.ink,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => _pickSort(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs + 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert_rounded,
                          size: 18, color: colors.lime),
                      const SizedBox(width: 4),
                      Text(
                        sort.label,
                        style: context.texts.labelLarge
                            ?.copyWith(color: colors.onInk),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoicePill(
            label: 'Todas',
            selected: category == null,
            onTap: () => onCategory(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: AppSpacing.xs),
            ChoicePill(
              label: '${c.label} (${c.count})',
              selected: category == c.slug,
              onTap: () => onCategory(category == c.slug ? null : c.slug),
            ),
          ],
        ],
      ),
    );
  }
}
