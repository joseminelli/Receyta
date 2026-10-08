import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/planner/screens/meal_slot_picker.dart'
    show ChoicePill;
import 'package:receyta/features/recipes/screens/ingredient_picker.dart';
import 'package:receyta/features/recipes/screens/ingredient_price_sheet.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/features/recipes/controllers/ingredients_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/action_menu_button.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/circle_icon_button.dart';
import 'package:receyta/widgets/state_badge.dart';

/// Gerenciar ingredientes (C6): lista o catálogo com contagem de uso, aponta
/// pares parecidos (fuzzy match do C4) prováveis de serem duplicata, e deixa
/// mesclar ou apagar. Mesclar nunca é automático — sempre passa por
/// confirmação (§8.2: "nunca funde sozinho; sempre pergunta").
class IngredientsPage extends ConsumerStatefulWidget {
  const IngredientsPage({super.key, this.pantryOnly = false});

  /// Abre já filtrando só o que está na despensa.
  final bool pantryOnly;

  @override
  ConsumerState<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends ConsumerState<IngredientsPage> {
  final _query = TextEditingController();
  late bool _pantryOnly = widget.pantryOnly;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _merge(Ingredient source, Ingredient target) async {
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

  Future<void> _pickAndMerge(Ingredient source) async {
    final target = await pickIngredient(context, ref, excludeId: source.id);
    if (target == null) return;
    if (!context.mounted) return;
    await _merge(source, target);
  }

  /// "Sempre tenho" (G11): liga/desliga a despensa e avisa o que isso muda.
  Future<void> _togglePantry(Ingredient ingredient) async {
    final on = !ingredient.inPantry;
    await ref.read(ingredientRepositoryProvider).setInPantry(ingredient.id, on);
    showAppSnackBar(
      message: on
          ? '"${ingredient.displayName}" é "sempre tenho": fica fora das '
              'listas de compras geradas'
          : '"${ingredient.displayName}" voltou pras listas de compras',
    );
  }

  /// Refaz a leitura de todas as receitas com o parser atual e limpa do
  /// catálogo o que sobrar sem uso.
  Future<void> _reanalyze() async {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.auto_fix_high_outlined,
      accent: context.colors.violet,
      title: 'Refazer a leitura dos ingredientes?',
      message: 'O app lê de novo cada linha de ingrediente das suas receitas e '
          'corrige quantidades, medidas e nomes que ficaram errados (como '
          '"(chá) de Açúcar"). O que você digitou não muda, e ingredientes que '
          'ficarem sem uso saem da lista.',
      confirmLabel: 'Refazer',
    );
    if (!ok || !mounted) return;
    final result =
        await ref.read(recipeRepositoryProvider).reanalyzeIngredients();
    result.when(
      ok: (changed) => showAppSnackBar(
        message: changed == 0
            ? 'Tudo já estava certo.'
            : '$changed ${changed == 1 ? 'linha ajustada' : 'linhas ajustadas'}.',
      ),
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  Future<void> _editPrice(Ingredient ingredient) async {
    await showIngredientPriceSheet(context, ingredient);
  }

  Future<void> _delete(Ingredient ingredient) async {
    final ok = await AppDialog.confirm(
      context,
      icon: Icons.delete_outline,
      accent: context.colors.danger,
      title: 'Apagar "${ingredient.displayName}"?',
      message: 'Não está em nenhuma receita. Não dá pra desfazer.',
      confirmLabel: 'Apagar',
    );
    if (ok) {
      await ref.read(ingredientRepositoryProvider).delete(ingredient.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(ingredientsWithCountsProvider);

    final count = items.valueOrNull?.length;
    return HeaderScaffold(
      title: 'Ingredientes',
      subtitle: count == null
          ? null
          : '$count ${count == 1 ? 'ingrediente' : 'ingredientes'}',
      color: TileColor.lime,
      trailing: ActionMenuButton(
        tooltip: 'Mais ações',
        items: [
          ActionMenuItem(
            icon: Icons.auto_fix_high_outlined,
            label: 'Refazer a leitura',
            hint: 'Corrige nomes e medidas',
            onTap: _reanalyze,
          ),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => _buildError(context),
        data: (rows) =>
            rows.isEmpty ? _buildEmpty(context) : _buildContent(context, rows),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colors = context.colors;
    return Center(
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
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
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

  Widget _buildContent(
    BuildContext context,
    List<({Ingredient ingredient, int count})> rows,
  ) {
    final duplicateOf = _detectDuplicates([for (final r in rows) r.ingredient]);
    final query = _query.text.trim().toLowerCase();
    final pantryCount = rows.where((r) => r.ingredient.inPantry).length;
    final filtered = [
      for (final r in rows)
        if ((!_pantryOnly || r.ingredient.inPantry) &&
            (query.isEmpty ||
                r.ingredient.displayName.toLowerCase().contains(query)))
          r,
    ];

    return Column(
      children: [
        _buildSearchField(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              ChoicePill(
                label: 'Todos',
                selected: !_pantryOnly,
                onTap: () => setState(() => _pantryOnly = false),
              ),
              const SizedBox(width: AppSpacing.xs),
              ChoicePill(
                label: 'Na despensa ($pantryCount)',
                selected: _pantryOnly,
                onTap: () => setState(() => _pantryOnly = true),
              ),
            ],
          ),
        ),
        Expanded(
            child: _buildResultsList(context, filtered, duplicateOf, query)),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _query,
        onChanged: (_) => setState(() {}),
        textCapitalization: TextCapitalization.none,
        decoration: InputDecoration(
          hintText: 'Buscar ingrediente',
          prefixIcon: Icon(Icons.search, color: colors.textMuted),
          filled: true,
          fillColor: colors.paperSoft,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    List<({Ingredient ingredient, int count})> filtered,
    Map<String, Ingredient> duplicateOf,
    String query,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            _pantryOnly && query.isEmpty
                ? 'Nada na despensa ainda. Toque em "Sempre tenho" num '
                    'ingrediente (sal, azeite…) e ele fica fora das listas '
                    'de compras.'
                : 'Nada encontrado pra "$query".',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium
                ?.copyWith(color: context.colors.textMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.screen,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, i) {
        final (:ingredient, :count) = filtered[i];
        final dup = duplicateOf[ingredient.id];
        return _IngredientRow(
          ingredient: ingredient,
          count: count,
          duplicateOf: dup,
          onMergeDuplicate: dup == null ? null : () => _merge(ingredient, dup),
          onPickMerge: () => _pickAndMerge(ingredient),
          onTogglePantry: () => _togglePantry(ingredient),
          onEditPrice: () => _editPrice(ingredient),
          onDelete: count == 0 ? () => _delete(ingredient) : null,
        );
      },
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
    required this.onTogglePantry,
    required this.onEditPrice,
    required this.onDelete,
  });

  final Ingredient ingredient;
  final int count;
  final Ingredient? duplicateOf;
  final VoidCallback? onMergeDuplicate;
  final VoidCallback onPickMerge;
  final VoidCallback onTogglePantry;
  final VoidCallback onEditPrice;

  /// Nulo quando o ingrediente está em uso — `RecipeIngredients.ingredientId`
  /// é `onDelete: restrict`, então apagar falharia; some o botão em vez de
  /// deixar um botão que sempre dá erro.
  final VoidCallback? onDelete;

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
                    if (ingredient.inPantry)
                      _Pill(label: 'Sempre tenho', color: colors.ink),
                    InkWell(
                      onTap: onEditPrice,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: ingredient.price == null
                          ? _Pill(
                              label: 'Definir preço',
                              color: colors.textMuted,
                            )
                          : _Pill(
                              label: priceTag(ingredient.price!),
                              color: colors.ink,
                            ),
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
          if (onDelete != null) ...[
            const SizedBox(width: AppSpacing.xs),
            CircleIconButton(
              icon: Icons.delete_outline,
              background: colors.danger,
              onTap: onDelete,
              tooltip: 'Apagar',
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          CircleIconButton(
            icon: ingredient.inPantry ? Icons.kitchen : Icons.kitchen_outlined,
            background: ingredient.inPantry ? colors.ink : colors.paper,
            foreground: ingredient.inPantry ? colors.lime : colors.ink,
            onTap: onTogglePantry,
            tooltip: ingredient.inPantry
                ? 'Tirar da despensa'
                : 'Sempre tenho (despensa)',
          ),
          const SizedBox(width: AppSpacing.xs),
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
