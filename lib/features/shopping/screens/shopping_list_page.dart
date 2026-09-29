import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:share_plus/share_plus.dart';

import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/engine/shopping_text.dart';
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
          if (ref.watch(currentShoppingListProvider).valueOrNull != null) ...[
            CircleIconButton(
              icon: Icons.ios_share,
              tooltip: 'Compartilhar como texto',
              onTap: () => _share(context, ref),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          CircleIconButton(
            icon: Icons.add_shopping_cart_outlined,
            tooltip: 'Gerar lista',
            onTap: () => _generate(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final list = ref.read(currentShoppingListProvider).valueOrNull;
    if (list == null) return;
    final items = await ref.read(shoppingListRepositoryProvider).itemsOf(list.id);
    if (items.isEmpty) return;
    await Share.share(buildShoppingListText(list.name, items), subject: list.name);
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
        return Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? _buildMessage(context, 'Lista vazia.')
                  : _buildGroups(context, items),
            ),
            _AddItemBar(listId: list.id),
          ],
        );
      },
    );
  }

  Widget _buildGroups(BuildContext context, List<ShoppingListItem> items) {
    final colors = context.colors;
    final children = <Widget>[];
    for (final group in groupShoppingItems(items)) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            group.label.toUpperCase(),
            style: context.texts.labelMedium?.copyWith(
              color: colors.lime,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
      for (final item in group.items) {
        children
          ..add(_ItemRow(item: item))
          ..add(const SizedBox(height: AppSpacing.xs));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      children: children,
    );
  }
}

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

class _AddItemBar extends ConsumerStatefulWidget {
  const _AddItemBar({required this.listId});

  final String listId;

  @override
  ConsumerState<_AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends ConsumerState<_AddItemBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final result = await ref
        .read(shoppingListRepositoryProvider)
        .addManualItem(widget.listId, text);
    result.when(
      ok: (_) => _controller.clear(),
      err: (f) =>
          showAppSnackBar(message: f.message, variant: AppSnackBarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        _navBarClearance,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _submit(),
              style: context.texts.bodyLarge?.copyWith(color: colors.onSaturated),
              cursorColor: colors.lime,
              decoration: InputDecoration(
                hintText: 'Adicionar item (ex.: 2 caixas de leite)',
                hintStyle: context.texts.bodyMedium?.copyWith(
                  color: colors.onSaturated.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: colors.inkSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: Icons.add,
            tooltip: 'Adicionar item',
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final done = item.checked;
    final origin = shoppingItemOrigin(item);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SweepStrikeText(
                      text: shoppingItemLabel(item),
                      done: done,
                      lineColor: colors.onSaturated.withValues(alpha: 0.5),
                      style: context.texts.bodyLarge?.copyWith(
                        color: done
                            ? colors.onSaturated.withValues(alpha: 0.4)
                            : colors.onSaturated,
                      ),
                    ),
                    if (origin.isNotEmpty)
                      Text(
                        origin,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          color: colors.onSaturated
                              .withValues(alpha: done ? 0.3 : 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
