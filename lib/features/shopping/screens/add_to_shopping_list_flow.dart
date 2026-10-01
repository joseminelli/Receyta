import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Escolha do sheet: `listId` nulo = lista nova só com estas receitas.
typedef _ListChoice = ({String? listId});

/// "Adicionar à lista de compras" a partir da receita. Ver
/// [addRecipesToShoppingListFlow].
Future<void> addRecipeToShoppingListFlow(
  BuildContext context,
  WidgetRef ref,
  String recipeId,
) =>
    addRecipesToShoppingListFlow(context, ref, {recipeId: 1});

/// O usuário escolhe uma lista existente (os ingredientes somam com os itens
/// iguais) ou uma nova pras receitas de [counts] (id → quantas vezes). Ao
/// terminar, avisa e oferece abrir a lista. [newListName] nomeia a lista
/// nova; sem ele, vale o nome padrão com a data.
Future<void> addRecipesToShoppingListFlow(
  BuildContext context,
  WidgetRef ref,
  Map<String, int> counts, {
  String? newListName,
}) async {
  final router = GoRouter.of(context);
  final lists =
      ref.read(shoppingListsProvider).valueOrNull ?? const <ShoppingListSummary>[];
  final choice = await showModalBottomSheet<_ListChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _ChooseListSheet(lists: lists),
  );
  if (choice == null) return;

  final repo = ref.read(shoppingListRepositoryProvider);
  final String? listId;
  final String listName;
  final Result<Object?> result;
  if (choice.listId == null) {
    final created = await repo.generateFromRecipes(
      counts.keys.toList(),
      name: newListName,
      counts: counts,
    );
    listId = created is Ok<ShoppingList> ? created.value.id : null;
    listName = created is Ok<ShoppingList> ? created.value.name : '';
    result = created;
  } else {
    listId = choice.listId;
    listName = lists.firstWhere((s) => s.list.id == listId).list.name;
    result = await repo.addRecipesToList(choice.listId!, counts);
  }

  result.when(
    ok: (_) => showAppSnackBar(
      message: choice.listId == null
          ? 'Lista criada: $listName'
          : 'Adicionado a "$listName"',
      actionLabel: 'Ver lista',
      onAction: () => router.push('/shopping/$listId'),
    ),
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}

class _ChooseListSheet extends StatelessWidget {
  const _ChooseListSheet({required this.lists});

  final List<ShoppingListSummary> lists;

  String _subtitle(ShoppingListSummary s) {
    if (s.total == 0) return 'Vazia';
    return '${s.checked} de ${s.total} ${s.total == 1 ? 'item' : 'itens'}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.xs,
              ),
              child: Text(
                'Adicionar à lista de compras',
                style: context.texts.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nova lista'),
              subtitle: const Text('Só com os ingredientes desta receita'),
              onTap: () => Navigator.of(context).pop<_ListChoice>((listId: null)),
            ),
            if (lists.isNotEmpty) const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final s in lists)
                    ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(
                        s.list.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_subtitle(s)),
                      onTap: () => Navigator.of(context)
                          .pop<_ListChoice>((listId: s.list.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
