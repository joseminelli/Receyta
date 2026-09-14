import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/ingredient_picker.dart';
import 'package:receyta/features/recipes/ingredients_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Gerenciar ingredientes (C6): lista o catálogo com contagem de uso, aponta
/// pares parecidos (fuzzy match do C4) prováveis de serem duplicata, e deixa
/// mesclar. Mesclar nunca é automático — sempre passa por confirmação
/// (§8.2: "nunca funde sozinho; sempre pergunta").
class IngredientsPage extends ConsumerWidget {
  const IngredientsPage({super.key});

  Future<void> _merge(
    BuildContext context,
    WidgetRef ref,
    Ingredient source,
    Ingredient target,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.call_merge,
      accent: context.colors.violet,
      title: 'Juntar "${source.displayName}" em "${target.displayName}"?',
      message: 'As receitas que usam "${source.displayName}" passam a usar '
          '"${target.displayName}". Não dá pra desfazer.',
      confirmLabel: 'Mesclar',
    );
    if (ok) {
      await ref.read(ingredientRepositoryProvider).merge(source.id, target.id);
    }
  }

  Future<void> _pickAndMerge(
    BuildContext context,
    WidgetRef ref,
    Ingredient source,
  ) async {
    final target = await pickIngredient(context, ref, excludeId: source.id);
    if (target == null) return;
    if (!context.mounted) return;
    await _merge(context, ref, source, target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final items = ref.watch(ingredientsWithCountsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      appBar: AppBar(title: const Text('Ingredientes')),
      body: items.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.ink),
        ),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StateBadge(
                  icon: Icons.priority_high_rounded,
                  background: colors.danger,
                  foreground: colors.onSaturated,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Não deu para carregar os ingredientes',
                  style: context.texts.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StateBadge(
                      icon: Icons.egg_outlined,
                      background: colors.violet,
                      foreground: colors.onSaturated,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Nenhum ingrediente ainda',
                      style: context.texts.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final duplicateOf =
              _detectDuplicates([for (final r in rows) r.ingredient]);

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screen),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final (:ingredient, :count) = rows[i];
              final dup = duplicateOf[ingredient.id];
              return _IngredientRow(
                ingredient: ingredient,
                count: count,
                duplicateOf: dup,
                onMergeDuplicate:
                    dup == null ? null : () => _merge(context, ref, ingredient, dup),
                onPickMerge: () => _pickAndMerge(context, ref, ingredient),
              );
            },
          );
        },
      ),
    );
  }
}

/// Pra cada ingrediente, o candidato mais parecido no catálogo (C4), se
/// houver um acima do limiar. O(n²) — catálogo pessoal é pequeno o
/// suficiente pra isso não pesar.
Map<String, Ingredient> _detectDuplicates(List<Ingredient> all) {
  final out = <String, Ingredient>{};
  for (final a in all) {
    for (final b in all) {
      if (a.id == b.id) continue;
      if (isCloseMatch(a.normalizedKey, b.normalizedKey)) {
        out[a.id] = b;
        break;
      }
    }
  }
  return out;
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.count,
    required this.duplicateOf,
    required this.onMergeDuplicate,
    required this.onPickMerge,
  });

  final Ingredient ingredient;
  final int count;
  final Ingredient? duplicateOf;
  final VoidCallback? onMergeDuplicate;
  final VoidCallback onPickMerge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ingredient.displayName,
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs / 2,
                  children: [
                    _Pill(
                      label: count == 0
                          ? 'Não usado'
                          : '$count receita${count == 1 ? '' : 's'}',
                      color: colors.violet,
                    ),
                    if (duplicateOf != null)
                      InkWell(
                        onTap: onMergeDuplicate,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: _Pill(
                          label:
                              'Parece com "${duplicateOf!.displayName}" · mesclar',
                          color: colors.coral,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleIconButton(
            icon: Icons.call_merge,
            background: colors.violet,
            onTap: onPickMerge,
            tooltip: 'Mesclar com...',
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.paper,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: context.texts.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

/// Link discreto pra tela de ingredientes — só quando existe algum.
class IngredientsLink extends ConsumerWidget {
  const IngredientsLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(ingredientsWithCountsProvider).valueOrNull?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => context.push('/ingredients'),
      icon: Icon(Icons.egg_outlined, size: 18, color: context.colors.textMuted),
      label: Text(
        'Ingredientes',
        style:
            context.texts.labelLarge?.copyWith(color: context.colors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
