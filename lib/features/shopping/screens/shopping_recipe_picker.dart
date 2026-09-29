import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Abre o seletor "Gerar lista de compras": checkbox por receita ativa
/// (RF-05.1). Devolve os ids marcados, ou nulo se o usuário fechou sem
/// escolher — mesmo molde do `_RecipeInclusionSheet` do import por foto
/// (C8), mas de seleção livre (não vem tudo pré-marcado).
Future<List<String>?> pickRecipesForShoppingList(
  BuildContext context,
  WidgetRef ref,
) {
  final recipes = ref.read(allRecipesProvider).valueOrNull ?? const <Recipe>[];
  return showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: context.colors.paper,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _RecipePickerSheet(recipes: recipes),
  );
}

class _RecipePickerSheet extends StatefulWidget {
  const _RecipePickerSheet({required this.recipes});

  final List<Recipe> recipes;

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: Text('Gerar lista de compras', style: texts.displaySmall),
            ),
            Flexible(child: _buildList(context)),
            _buildGenerateButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (widget.recipes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Text(
          'Nenhuma receita cadastrada ainda.',
          style: context.texts.bodyMedium
              ?.copyWith(color: context.colors.textMuted),
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      children: [
        for (final recipe in widget.recipes)
          CheckboxListTile(
            value: _selected.contains(recipe.id),
            onChanged: (checked) => setState(() {
              if (checked ?? false) {
                _selected.add(recipe.id);
              } else {
                _selected.remove(recipe.id);
              }
            }),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.colors.lime,
            title: Text(recipe.name, style: context.texts.bodyLarge),
          ),
      ],
    );
  }

  Widget _buildGenerateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      child: PillButton(
        label: _selected.isEmpty
            ? 'Selecione ao menos uma'
            : 'Gerar lista com ${_selected.length} '
                '${_selected.length > 1 ? 'receitas' : 'receita'}',
        onPressed:
            _selected.isEmpty ? null : () => Navigator.of(context).pop(_selected.toList()),
      ),
    );
  }
}
