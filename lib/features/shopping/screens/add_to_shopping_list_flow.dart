import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/serving_scale.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/domain/models/shopping_list.dart';
import 'package:receyta/features/shopping/controllers/shopping_view_model.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Escolha do sheet: `listId` nulo = lista nova só com estas receitas.
typedef _ListChoice = ({String? listId, int? servings});

/// "Adicionar à lista de compras" a partir da receita. Ver
/// [addRecipesToShoppingListFlow].
///
/// Com o rendimento da receita conhecido, o sheet pergunta pra quantas porções
/// ([servings] já vem marcado, por exemplo as do modo cozinha) e as
/// quantidades entram escaladas e arredondadas pra cima.
Future<void> addRecipeToShoppingListFlow(
  BuildContext context,
  WidgetRef ref,
  String recipeId, {
  int? servings,
}) async {
  final detail = await ref.read(recipeRepositoryProvider).getDetail(recipeId);
  final base = detail is Ok<RecipeDetail> ? detail.value.recipe.servings : null;
  if (!context.mounted) return;
  await addRecipesToShoppingListFlow(
    context,
    ref,
    {recipeId: 1},
    baseServings: base,
    initialServings: servings,
  );
}

/// O usuário escolhe uma lista existente (os ingredientes somam com os itens
/// iguais) ou uma nova pras receitas de [counts] (id → quantas vezes). Ao
/// terminar, avisa e oferece abrir a lista. [newListName] nomeia a lista
/// nova; sem ele, vale o nome padrão com a data.
Future<void> addRecipesToShoppingListFlow(
  BuildContext context,
  WidgetRef ref,
  Map<String, int> counts, {
  String? newListName,
  Map<String, double>? factors,
  int? baseServings,
  int? initialServings,
  List<ExternalRecipe> external = const [],
}) async {
  final router = GoRouter.of(context);
  final lists = ref.read(shoppingListsProvider).valueOrNull ??
      const <ShoppingListSummary>[];
  final choice = await showModalBottomSheet<_ListChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => _ChooseListSheet(
      lists: lists,
      baseServings: baseServings,
      initialServings: initialServings,
    ),
  );
  if (choice == null) return;

  final chosen = choice.servings;
  final scale = (baseServings != null &&
          chosen != null &&
          chosen != baseServings)
      ? {counts.keys.first: servingFactor(base: baseServings, chosen: chosen)}
      : factors;

  final repo = ref.read(shoppingListRepositoryProvider);
  final String? listId;
  final String listName;
  final Result<Object?> result;
  if (choice.listId == null) {
    final created = await repo.generateFromRecipes(
      counts.keys.toList(),
      name: newListName,
      counts: counts,
      factors: scale,
      external: external,
    );
    listId = created is Ok<ShoppingList> ? created.value.id : null;
    listName = created is Ok<ShoppingList> ? created.value.name : '';
    result = created;
  } else {
    listId = choice.listId;
    listName = lists.firstWhere((s) => s.list.id == listId).list.name;
    result = await repo.addRecipesToList(
      choice.listId!,
      counts,
      factors: scale,
      external: external,
    );
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

class _ChooseListSheet extends StatefulWidget {
  const _ChooseListSheet({
    required this.lists,
    this.baseServings,
    this.initialServings,
  });

  final List<ShoppingListSummary> lists;
  final int? baseServings;
  final int? initialServings;

  @override
  State<_ChooseListSheet> createState() => _ChooseListSheetState();
}

class _ChooseListSheetState extends State<_ChooseListSheet> {
  late int? _servings = widget.baseServings == null
      ? null
      : (widget.initialServings ?? widget.baseServings);

  String _subtitle(ShoppingListSummary s) {
    if (s.total == 0) return 'Vazia';
    return '${s.checked} de ${s.total} ${s.total == 1 ? 'item' : 'itens'}';
  }

  Widget _servingsRow(BuildContext context) {
    final colors = context.colors;
    final servings = _servings!;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para quantas porções?', style: context.texts.bodyLarge),
                Text(
                  servings == widget.baseServings
                      ? 'Como a receita'
                      : 'A receita rende ${widget.baseServings} — '
                          'quantidades arredondadas pra cima',
                  style: context.texts.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Menos uma porção',
            onPressed: servings > kMinServings
                ? () => setState(() => _servings = servings - 1)
                : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$servings', style: context.texts.titleLarge),
          IconButton(
            tooltip: 'Mais uma porção',
            onPressed: servings < kMaxServings
                ? () => setState(() => _servings = servings + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lists = widget.lists;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
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
            if (_servings != null) ...[
              _servingsRow(context),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Nova lista'),
              subtitle: const Text('Só com os ingredientes desta receita'),
              onTap: () => Navigator.of(context)
                  .pop<_ListChoice>((listId: null, servings: _servings)),
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
                      onTap: () => Navigator.of(context).pop<_ListChoice>(
                        (listId: s.list.id, servings: _servings),
                      ),
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
