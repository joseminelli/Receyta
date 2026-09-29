import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/unit_label.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/domain/models/shopping_list_item.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/features/shopping/screens/shopping_recipe_picker.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/sweep_strike_text.dart';

/// Tela de compras (E3, RF-05.5): superfície escura, mesma linguagem do modo
/// cozinha (§9.8) — é outra tela "de mão suja"/uso rápido, não de leitura.
/// Mostra sempre a lista mais recente; marcar item risca e afunda pro fim.
class ShoppingListPage extends ConsumerWidget {
  const ShoppingListPage({super.key});

  Future<void> _generate(BuildContext context, WidgetRef ref) async {
    final ids = await pickRecipesForShoppingList(context, ref);
    if (ids == null || ids.isEmpty) return;
    if (!context.mounted) return;
    final result =
        await ref.read(shoppingListRepositoryProvider).generateFromRecipes(ids);
    result.when(
      ok: (_) {},
      err: (f) =>
          showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final listAsync = ref.watch(currentShoppingListProvider);

    return Scaffold(
      backgroundColor: colors.ink,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref),
            Expanded(
              child: listAsync.when(
                loading: () => const Center(child: BrandLoader()),
                error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
                data: (list) => list == null
                    ? _buildEmpty(context, ref)
                    : _buildList(context, ref, list),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Compras',
              style: context.texts.displaySmall
                  ?.copyWith(color: colors.onSaturated),
            ),
          ),
          CircleIconButton(
            icon: Icons.add_shopping_cart_outlined,
            tooltip: 'Gerar lista',
            onTap: () => _generate(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 56, color: colors.lime),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nenhuma lista ainda',
              style: context.texts.displaySmall
                  ?.copyWith(color: colors.onSaturated),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Escolha as receitas da semana e a lista sai pronta, com as '
              'quantidades já somadas.',
              style: context.texts.bodyMedium?.copyWith(
                color: colors.onSaturated.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: 'Gerar lista',
              icon: Icons.add_shopping_cart_outlined,
              onPressed: () => _generate(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String text) {
    return Center(
      child: Text(
        text,
        style: context.texts.bodyLarge
            ?.copyWith(color: context.colors.onSaturated),
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, ShoppingList list) {
    final itemsAsync = ref.watch(shoppingListItemsProvider(list.id));
    return itemsAsync.when(
      loading: () => const Center(child: BrandLoader()),
      error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
      data: (items) {
        if (items.isEmpty) {
          return _buildMessage(context, 'Lista vazia.');
        }
        // Ordem fixa (a mesma de `position`) — marcar não reordena, só risca
        // no lugar.
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, i) => _ItemRow(item: items[i]),
        );
      },
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final ShoppingListItem item;

  String get _label {
    final qty = item.quantity;
    final unit = unitLabel(item.unitId, qty ?? 1);
    if (qty == null) return item.displayName;
    final qtyText = qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2).replaceAll('.', ',');
    return unit == null
        ? '$qtyText ${item.displayName}'
        : '$qtyText $unit de ${item.displayName}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final done = item.checked;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: () => ref
            .read(shoppingListRepositoryProvider)
            .setChecked(item.id, !done),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: done ? colors.ink : colors.inkSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? colors.lime : Colors.transparent,
                  border: Border.all(
                    color: done ? colors.lime : colors.onSaturated.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: done
                    ? Icon(Icons.check, size: 16, color: colors.ink)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SweepStrikeText(
                  text: _label,
                  done: done,
                  lineColor: colors.onSaturated.withValues(alpha: 0.5),
                  style: context.texts.bodyLarge?.copyWith(
                    color: done
                        ? colors.onSaturated.withValues(alpha: 0.4)
                        : colors.onSaturated,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
