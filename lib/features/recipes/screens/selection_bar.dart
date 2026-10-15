import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/data/repositories/folder_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/folders/screens/folder_picker.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/recipes/controllers/recipe_selection.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/widgets/app_sheet.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/pill_button.dart';

String _receitas(int n) => n == 1 ? '1 receita' : '$n receitas';

/// Barra de ações do modo de seleção da home: favoritar, mover pra pasta, pôr
/// tags e mandar pra lixeira, tudo nas receitas marcadas. Fica no lugar da
/// barra de abas (o shell esconde e trava a barra enquanto ela existe), com o
/// ✕ e a contagem à esquerda pra deixar claro que a tela está em modo de
/// seleção.
class SelectionBar extends ConsumerWidget {
  const SelectionBar({super.key});

  List<Recipe> _chosen(List<Recipe> all, Set<String> ids) => [
        for (final r in all)
          if (ids.contains(r.id)) r
      ];

  void _report(Result<void> result) {
    if (result is Err<void>) {
      showAppSnackBar(
        message: result.failure.message,
        variant: AppSnackBarVariant.error,
      );
    }
  }

  Future<void> _favorite(WidgetRef ref, List<Recipe> chosen) async {
    final repo = ref.read(recipeRepositoryProvider);
    final value = !chosen.every((r) => r.isFavorite);
    for (final r in chosen) {
      _report(await repo.setFavorite(r.id, value));
    }
    ref.read(recipeSelectionProvider.notifier).clear();
    showAppSnackBar(
      message: value
          ? '${_receitas(chosen.length)} favoritada${chosen.length == 1 ? '' : 's'}'
          : 'Favorito tirado de ${_receitas(chosen.length)}',
    );
  }

  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    List<Recipe> chosen,
  ) async {
    final choice = await pickFolder(context, ref);
    if (choice == null) return;
    final repo = ref.read(folderRepositoryProvider);
    for (final r in chosen) {
      _report(await repo.moveRecipe(r.id, choice.id));
    }
    ref.read(recipeSelectionProvider.notifier).clear();
    showAppSnackBar(
      message: '${_receitas(chosen.length)} '
          '${chosen.length == 1 ? 'movida' : 'movidas'}',
    );
  }

  Future<void> _tag(
    BuildContext context,
    WidgetRef ref,
    List<Recipe> chosen,
  ) async {
    final names = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _TagsSheet(count: chosen.length),
    );
    if (names == null || names.isEmpty) return;
    final result = await ref
        .read(recipeRepositoryProvider)
        .addTags([for (final r in chosen) r.id], names);
    _report(result);
    if (result.isOk) {
      ref.read(recipeSelectionProvider.notifier).clear();
      showAppSnackBar(
          message: 'Tags adicionadas a ${_receitas(chosen.length)}');
    }
  }

  Future<void> _trash(WidgetRef ref, List<Recipe> chosen) async {
    final repo = ref.read(recipeRepositoryProvider);
    for (final r in chosen) {
      _report(await repo.softDelete(r.id));
    }
    ref.read(recipeSelectionProvider.notifier).clear();
    showAppSnackBar(
      message: '${_receitas(chosen.length)} na lixeira',
      actionLabel: 'Desfazer',
      onAction: () async {
        for (final r in chosen) {
          await repo.restore(r.id);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ids = ref.watch(recipeSelectionProvider) ?? const <String>{};
    final all = ref.watch(allRecipesProvider).valueOrNull ?? const <Recipe>[];
    final chosen = _chosen(all, ids);
    final enabled = chosen.isNotEmpty;
    final allFavorite = enabled && chosen.every((r) => r.isFavorite);

    return Material(
      color: colors.ink,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            _CloseCount(
              count: chosen.length,
              onTap: ref.read(recipeSelectionProvider.notifier).clear,
            ),
            Container(
              width: 1,
              height: 34,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              color: colors.onSaturated.withValues(alpha: 0.18),
            ),
            _BarAction(
              icon: allFavorite ? Icons.favorite : Icons.favorite_border,
              label: 'Favoritar',
              enabled: enabled,
              onTap: () => _favorite(ref, chosen),
            ),
            _BarAction(
              icon: Icons.drive_file_move_outlined,
              label: 'Mover',
              enabled: enabled,
              onTap: () => _move(context, ref, chosen),
            ),
            _BarAction(
              icon: Icons.sell_outlined,
              label: 'Tags',
              enabled: enabled,
              onTap: () => _tag(context, ref, chosen),
            ),
            _BarAction(
              icon: Icons.delete_outline,
              label: 'Lixeira',
              enabled: enabled,
              onTap: () => _trash(ref, chosen),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pílula da esquerda: ✕ pra sair do modo e a contagem grande em display —
/// o que deixa claro, em cima do lugar da barra de abas, que a tela mudou
/// pra seleção.
class _CloseCount extends StatelessWidget {
  const _CloseCount({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Sair da seleção, $count marcadas',
      child: Material(
        color: colors.inkSoft,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close_rounded,
                      size: 20, color: colors.onSaturated),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: AppTextStyles.display(28)
                          .copyWith(color: colors.lime),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: ExcludeSemantics(
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.35,
            duration: const Duration(milliseconds: 160),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: colors.lime, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.labelSmall?.copyWith(
                        color: colors.onSaturated.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Escolhe tags existentes e/ou escreve novas (vírgula separa). Devolve os
/// nomes, ou nulo se cancelou.
class _TagsSheet extends ConsumerStatefulWidget {
  const _TagsSheet({required this.count});

  final int count;

  @override
  ConsumerState<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends ConsumerState<_TagsSheet> {
  final _typed = TextEditingController();
  final _picked = <String>{};

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  List<String> get _names => [
        ..._picked,
        ..._typed.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      ];

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(allTagsProvider).valueOrNull ?? const [];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheetFrame(
        title: 'Adicionar tags',
        subtitle: 'Em ${_receitas(widget.count)}',
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (existing.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final tag in existing)
                    ChoicePill(
                      label: tag.name,
                      selected: _picked.contains(tag.name),
                      onTap: () => setState(() {
                        if (!_picked.remove(tag.name)) _picked.add(tag.name);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: _typed,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Tag nova (vírgula separa)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: PillButton(
                label: 'Adicionar',
                icon: Icons.check_rounded,
                onPressed: _names.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_names),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
