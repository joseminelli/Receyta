import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/data/repositories/shopping_list_repository.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/widgets/app_snackbar.dart';

/// Marca todos os itens de uma lista como feitos. Avisa com "Desfazer", que
/// desmarca exatamente o que acabou de ser marcado.
Future<void> checkAllShoppingItems(WidgetRef ref, String listId) async {
  HapticFeedback.selectionClick();
  final repo = ref.read(shoppingListRepositoryProvider);
  final result = await repo.checkAll(listId);
  result.when(
    ok: (ids) {
      if (ids.isEmpty) return;
      showAppSnackBar(
        message:
            ids.length == 1 ? '1 item marcado' : '${ids.length} itens marcados',
        actionLabel: 'Desfazer',
        onAction: () => repo.unmark(ids),
      );
    },
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}

/// Desmarca todos os itens de uma lista (pra reaproveitá-la na próxima
/// compra). Sem diálogo: avisa com "Desfazer", que remarca exatamente o que
/// estava marcado — mais leve que confirmar e igualmente seguro.
Future<void> uncheckAllShoppingItems(WidgetRef ref, String listId) async {
  HapticFeedback.selectionClick();
  final repo = ref.read(shoppingListRepositoryProvider);
  final result = await repo.uncheckAll(listId);
  result.when(
    ok: (ids) {
      if (ids.isEmpty) return;
      showAppSnackBar(
        message: ids.length == 1
            ? '1 item desmarcado'
            : '${ids.length} itens desmarcados',
        actionLabel: 'Desfazer',
        onAction: () => repo.recheck(ids),
      );
    },
    err: (f) => showAppSnackBar(
      message: f.message,
      variant: AppSnackBarVariant.error,
    ),
  );
}
