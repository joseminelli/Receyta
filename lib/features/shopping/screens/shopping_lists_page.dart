import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/features/shopping/screens/shopping_recipe_picker.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Folga pra `PillNavBar` flutuante (78 de altura visível) + respiro — a
/// home_shell usa `extendBody`, então a aba desenha por baixo dela.
const _navBarClearance = 96.0;

/// Aba "Compras" (RF-05.9): as suas listas, da mais nova pra mais antiga.
/// Tocar numa abre `ShoppingListPage`; criar uma nova é a partir de receitas
/// (agrega os ingredientes) ou em branco (itens avulsos).
class ShoppingListsPage extends ConsumerWidget {
  const ShoppingListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      backgroundColor: colors.ink,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref),
            Expanded(
              child: listsAsync.when(
                loading: () => const Center(child: BrandLoader()),
                error: (_, __) => _buildMessage(context, 'Não deu para carregar.'),
                data: (lists) => lists.isEmpty
                    ? _buildEmpty(context, ref)
                    : _buildLists(context, ref, lists),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
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
                  ?.copyWith(color: context.colors.onSaturated),
            ),
          ),
          CircleIconButton(
            icon: Icons.add,
            tooltip: 'Nova lista',
            onTap: () => _openCreateSheet(context, ref),
          ),
        ],
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
              label: 'Gerar de receitas',
              icon: Icons.add_shopping_cart_outlined,
              onPressed: () => _createFromRecipes(context, ref),
            ),
            const SizedBox(height: AppSpacing.xs),
            PillButton(
              label: 'Lista em branco',
              variant: PillButtonVariant.ghost,
              onPressed: () => _createEmpty(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLists(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingListSummary> lists,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        _navBarClearance,
      ),
      itemCount: lists.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _ListCard(
        summary: lists[i],
        onOpen: () => context.push('/shopping/${lists[i].list.id}'),
        onMenu: () => _openListMenu(context, ref, lists[i].list),
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_shopping_cart_outlined),
              title: const Text('A partir de receitas'),
              subtitle: const Text('Soma os ingredientes das que você escolher'),
              onTap: () {
                Navigator.of(sheet).pop();
                _createFromRecipes(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Lista em branco'),
              subtitle: const Text('Você adiciona os itens'),
              onTap: () {
                Navigator.of(sheet).pop();
                _createEmpty(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFromRecipes(BuildContext context, WidgetRef ref) async {
    final ids = await pickRecipesForShoppingList(context, ref);
    if (ids == null || ids.isEmpty) return;
    final result =
        await ref.read(shoppingListRepositoryProvider).generateFromRecipes(ids);
    if (!context.mounted) return;
    _openCreated(context, result);
  }

  Future<void> _createEmpty(BuildContext context, WidgetRef ref) async {
    final name = await _promptListName(
      context,
      title: 'Nova lista',
      action: 'Criar',
    );
    if (name == null) return;
    final result =
        await ref.read(shoppingListRepositoryProvider).createEmpty(name: name);
    if (!context.mounted) return;
    _openCreated(context, result);
  }

  void _openCreated(BuildContext context, Result<ShoppingList> result) {
    result.when(
      ok: (list) => context.push('/shopping/${list.id}'),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  Future<void> _openListMenu(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Renomear'),
              onTap: () {
                Navigator.of(sheet).pop();
                _rename(context, ref, list);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.colors.danger),
              title: Text(
                'Excluir lista',
                style: context.texts.bodyLarge
                    ?.copyWith(color: context.colors.danger),
              ),
              onTap: () {
                Navigator.of(sheet).pop();
                _delete(context, ref, list);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final name = await _promptListName(
      context,
      title: 'Renomear lista',
      initial: list.name,
    );
    if (name == null || name == list.name) return;
    final result =
        await ref.read(shoppingListRepositoryProvider).rename(list.id, name);
    _report(result);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ShoppingList list,
  ) async {
    final confirmed = await AppDialog.confirm(
      context,
      icon: Icons.delete_outline,
      accent: context.colors.danger,
      title: 'Excluir "${list.name}"?',
      message: 'A lista e os itens dela saem do app. Isso não dá para '
          'desfazer.',
      confirmLabel: 'Excluir',
    );
    if (!confirmed) return;
    final result =
        await ref.read(shoppingListRepositoryProvider).deleteList(list.id);
    _report(result);
  }

  void _report(Result<void> result) {
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }
}

/// Diálogo de nome de lista — serve pra criar e renomear. Devolve o texto
/// (sem espaços nas pontas; vazio só na criação, que cai no nome padrão), ou
/// nulo se cancelou.
Future<String?> _promptListName(
  BuildContext context, {
  required String title,
  String initial = '',
  String action = 'Salvar',
}) {
  final controller = TextEditingController(text: initial);
  return AppDialog.show<String>(
    context,
    icon: Icons.shopping_bag_outlined,
    accent: context.colors.lime,
    title: title,
    content: TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Nome da lista (opcional)'),
      onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
    ),
    actions: [
      PillButton(
        label: 'Cancelar',
        variant: PillButtonVariant.ghost,
        dense: true,
        onPressed: () => Navigator.of(context).pop(),
      ),
      PillButton(
        label: action,
        dense: true,
        onPressed: () => Navigator.of(context).pop(controller.text.trim()),
      ),
    ],
  );
}

/// Cartão de uma lista: nome, "X de Y itens · dd/mm", barra de progresso e ⋯.
/// Lista toda marcada apaga um pouco e diz "Concluída".
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.summary,
    required this.onOpen,
    required this.onMenu,
  });

  final ShoppingListSummary summary;
  final VoidCallback onOpen;
  final VoidCallback onMenu;

  String get _subtitle {
    final total = summary.total;
    final date = summary.list.createdAt.toLocal();
    final day = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}';
    if (total == 0) return 'Vazia · $day';
    if (_complete) return 'Concluída · $day';
    return '${summary.checked} de $total ${total == 1 ? 'item' : 'itens'} · '
        '$day';
  }

  bool get _complete => summary.total > 0 && summary.checked == summary.total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = summary.total;

    return Material(
      color: colors.inkSoft,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _complete ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.list.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.titleMedium
                            ?.copyWith(color: colors.onSaturated),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: context.texts.bodySmall?.copyWith(
                          color: colors.onSaturated.withValues(alpha: 0.6),
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: LinearProgressIndicator(
                            value: summary.checked / total,
                            minHeight: 6,
                            backgroundColor:
                                colors.onSaturated.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(colors.lime),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Mais opções',
                  onPressed: onMenu,
                  icon: Icon(
                    Icons.more_horiz,
                    color: colors.onSaturated.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
