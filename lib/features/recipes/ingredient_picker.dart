import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/recipe_form_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Abre o seletor "Mesclar com" (C6): busca + lista do catálogo inteiro,
/// sem [excludeId] — o próprio ingrediente não pode virar alvo dele mesmo.
Future<Ingredient?> pickIngredient(
  BuildContext context,
  WidgetRef ref, {
  required String excludeId,
}) {
  return showModalBottomSheet<Ingredient>(
    context: context,
    backgroundColor: context.colors.paper,
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final all =
        ref.watch(allIngredientsProvider).valueOrNull ?? const <Ingredient>[];
    final q = _query.text.trim().toLowerCase();
    final options = all
        .where((i) => i.id != widget.excludeId)
        .where((i) => q.isEmpty || i.displayName.toLowerCase().contains(q))
        .toList();

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
                AppSpacing.md,
              ),
              child: Text('Mesclar com', style: context.texts.displaySmall),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.none,
                style: context.texts.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Buscar ingrediente',
                  prefixIcon: Icon(Icons.search, color: colors.textMuted),
                  filled: true,
                  fillColor: colors.paperSoft,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: options.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Text(
                        q.isEmpty
                            ? 'Nenhum outro ingrediente ainda.'
                            : 'Nada encontrado pra "$q".',
                        style: context.texts.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        0,
                        AppSpacing.screen,
                        AppSpacing.lg,
                      ),
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final ing = options[i];
                        return _PickerRow(
                          label: ing.displayName,
                          onTap: () =>
                              Navigator.of(context).pop<Ingredient>(ing),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de opção: cartão `paperSoft` arredondado, ícone + nome + seta —
/// mesma linguagem visual do resto do app, em vez do `ListTile` cru do
/// Material.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.egg_outlined, size: 20, color: colors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.texts.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
