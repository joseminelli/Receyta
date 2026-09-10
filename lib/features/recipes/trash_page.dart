import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Lixeira de 30 dias (RF-01.6): nada é apagado de verdade antes do prazo. Aqui
/// dá pra restaurar ou antecipar a exclusão definitiva.
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  static const _keep = Duration(days: 30);

  int _daysLeft(Recipe r, DateTime now) {
    final gone = (r.deletedAt ?? now).add(_keep).difference(now).inDays;
    return gone < 0 ? 0 : gone;
  }

  Future<void> _emptyAll(
    BuildContext context,
    WidgetRef ref,
    List<Recipe> items,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esvaziar a lixeira?'),
        content: Text('${items.length} receita(s) somem de vez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Esvaziar',
              style: TextStyle(color: context.colors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(recipeRepositoryProvider);
    for (final r in items) {
      await repo.deleteForever(r.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final repo = ref.read(recipeRepositoryProvider);
    final trashed = ref.watch(trashedRecipesProvider);
    final now = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(
        title: const Text('Lixeira'),
        actions: [
          if (trashed.valueOrNull?.isNotEmpty ?? false)
            TextButton(
              onPressed: () => _emptyAll(context, ref, trashed.value!),
              child: Text(
                'Esvaziar',
                style: TextStyle(color: colors.danger),
              ),
            ),
        ],
      ),
      body: trashed.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => Center(
          child: Text('Não deu para carregar', style: context.texts.bodyMedium),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                'A lixeira está vazia.',
                style: context.texts.bodyLarge,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final left = _daysLeft(r, now);
              return ListTile(
                title: Text(r.name, style: context.texts.bodyLarge),
                subtitle: Text(
                  left == 0
                      ? 'Some na próxima faxina'
                      : 'Apaga em $left dia${left == 1 ? '' : 's'}',
                  style: context.texts.labelMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => repo.restore(r.id),
                      icon: const Icon(Icons.restore_from_trash_outlined),
                      tooltip: 'Restaurar',
                    ),
                    IconButton(
                      onPressed: () => repo.deleteForever(r.id),
                      icon: Icon(Icons.delete_forever_outlined,
                          color: colors.danger),
                      tooltip: 'Excluir de vez',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Botão discreto de acesso à lixeira — só aparece quando há algo lá.
class TrashLink extends ConsumerWidget {
  const TrashLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(trashedRecipesProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/trash'),
        icon: Icon(Icons.delete_outline,
            size: 18, color: context.colors.textMuted),
        label: Text(
          'Lixeira · $count',
          style: context.texts.labelLarge
              ?.copyWith(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
