import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Gerenciar tags (§RF-01.10): lista tudo, inclusive as que não estão em
/// nenhuma receita, pra poder apagá-las. Apagar tira a tag de todas as receitas
/// e do filtro pra sempre.
class TagsPage extends ConsumerWidget {
  const TagsPage({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    int count,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apagar "${tag.name}"?'),
        content: Text(
          count == 0
              ? 'Não está em nenhuma receita.'
              : 'Sai de $count receita${count == 1 ? '' : 's'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apagar',
                style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tagRepositoryProvider).delete(tag.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tags = ref.watch(tagsWithCountsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('Tags')),
      body: tags.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => Center(
          child: Text('Não deu para carregar', style: context.texts.bodyMedium),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text('Nenhuma tag ainda.', style: context.texts.bodyLarge),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final (:tag, :count) = items[i];
              return ListTile(
                title: Text(tag.name, style: context.texts.bodyLarge),
                subtitle: Text(
                  count == 0
                      ? 'Não usada'
                      : '$count receita${count == 1 ? '' : 's'}',
                  style: context.texts.labelMedium,
                ),
                trailing: IconButton(
                  onPressed: () => _delete(context, ref, tag, count),
                  icon: Icon(Icons.delete_outline, color: colors.danger),
                  tooltip: 'Apagar',
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Link discreto pra tela de tags — só quando existe alguma tag.
class TagsLink extends ConsumerWidget {
  const TagsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tagsWithCountsProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () => context.push('/tags'),
        icon: Icon(Icons.sell_outlined,
            size: 18, color: context.colors.textMuted),
        label: Text(
          'Gerenciar tags',
          style: context.texts.labelLarge
              ?.copyWith(color: context.colors.textMuted),
        ),
      ),
    );
  }
}
