import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/engine/text_normalize.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/category_icon.dart';
import 'package:receyta/widgets/circle_icon_button.dart';

/// Abre o seletor "Mesclar com" (C6): busca + lista do catálogo inteiro,
/// sem [excludeId] — o próprio ingrediente não pode virar alvo dele mesmo.
Future<Ingredient?> pickIngredient(
  BuildContext context,
  WidgetRef ref, {
  required String excludeId,
}) {
  return showModalBottomSheet<Ingredient>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _IngredientPickerSheet(excludeId: excludeId),
  );
}

class _IngredientPickerSheet extends ConsumerStatefulWidget {
  const _IngredientPickerSheet({required this.excludeId});

  final String excludeId;

  @override
  ConsumerState<_IngredientPickerSheet> createState() =>
      _IngredientPickerSheetState();
}

class _IngredientPickerSheetState
    extends ConsumerState<_IngredientPickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  String _fold(String s) => stripAccents(s.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final all =
        ref.watch(allIngredientsProvider).valueOrNull ?? const <Ingredient>[];
    final q = _fold(_query.text);
    final options = all
        .where((i) => i.id != widget.excludeId)
        .where((i) => q.isEmpty || _fold(i.displayName).contains(q))
        .toList();
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Voltar',
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Mesclar com', style: AppTextStyles.display(30)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildSearchField(context),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: height * 0.5,
              child: _buildList(context, options),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _query,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar ingrediente',
        prefixIcon: Icon(Icons.search, color: colors.textMuted),
        suffixIcon: _query.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _query.clear();
                  setState(() {});
                },
              ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Ingredient> options) {
    final colors = context.colors;
    if (options.isEmpty) {
      return Center(
        child: Text(
          _query.text.trim().isEmpty
              ? 'Nenhum outro ingrediente ainda.'
              : 'Nada encontrado pra "${_query.text.trim()}".',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: options.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.paper),
        itemBuilder: (context, i) {
          final ing = options[i];
          return _PickerRow(
            ingredient: ing,
            onTap: () => Navigator.of(context).pop<Ingredient>(ing),
          );
        },
      ),
    );
  }
}

/// Linha de opção: bolinha com o ícone do tipo, o nome e uma seta.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.ingredient, required this.onTap});

  final Ingredient ingredient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IngredientIconBadge(
                ingredient: ingredient,
                size: 36,
                ink: colors.ink,
                accent: colors.lime,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ingredient.displayName,
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
