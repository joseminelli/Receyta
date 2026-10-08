import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/data/repositories/ingredient_repository.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/domain/engine/fuzzy_match.dart';
import 'package:receyta/domain/models/ingredient.dart';
import 'package:receyta/features/recipes/screens/ingredient_picker.dart';
import 'package:receyta/features/recipes/screens/ingredient_price_sheet.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/features/recipes/controllers/ingredients_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/action_menu_button.dart';
import 'package:receyta/widgets/app_dialog.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/underline_tabs.dart';

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: UnderlineTabs(
            tabs: [
              const UnderlineTab(
                label: 'Todos',
                icon: Icons.egg_alt_outlined,
              ),
              UnderlineTab(
                label: 'Na despensa ($pantryCount)',
                icon: Icons.kitchen_outlined,
              ),
            ],
            selected: _pantryOnly ? 1 : 0,
            onChanged: (i) => setState(() => _pantryOnly = i == 1),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSearchField(context),
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

/// Cartão de ingrediente, enxuto: uma bolinha com a inicial, o nome e uma
/// linha só com "N receitas · preço". Tudo o que se faz com ele mora no menu
/// "⋯": definir ou editar o preço, "sempre tenho" (despensa), mesclar e apagar.
/// Quem está na despensa leva um ícone de cozinha ao lado do nome, e quem não
/// está em nenhuma receita (e por isso pode ser apagado) leva uma lixeira. Tocar no
/// cartão é um atalho pro preço. A única faixa extra é o aviso de possível
/// duplicata, que só aparece quando existe.
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
  /// é `onDelete: restrict`, então apagar falharia; some a opção em vez de
  /// deixar uma que sempre dá erro.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = ingredient.displayName;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final price = ingredient.price;
    final inPantry = ingredient.inPantry;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEditPrice,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          initial,
                          style: AppTextStyles.display(22)
                              .copyWith(color: colors.lime, height: 1),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: context.texts.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (inPantry) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.kitchen,
                                    size: 16,
                                    color: colors.ink,
                                    semanticLabel: 'Sempre tenho',
                                  ),
                                ],
                                if (onDelete != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: colors.danger,
                                    semanticLabel: 'Pode ser apagado',
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  count == 0
                                      ? 'Não usado'
                                      : '$count receita${count == 1 ? '' : 's'}',
                                  style: context.texts.labelMedium
                                      ?.copyWith(color: colors.textMuted),
                                ),
                                Text(
                                  '  ·  ',
                                  style: context.texts.labelMedium
                                      ?.copyWith(color: colors.textMuted),
                                ),
                                Flexible(
                                  child: Text(
                                    price == null
                                        ? 'Sem preço'
                                        : priceTag(price),
                                    style: context.texts.labelMedium?.copyWith(
                                      color: price == null
                                          ? colors.textMuted
                                          : colors.ink,
                                      fontWeight: price == null
                                          ? null
                                          : FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              ActionMenuButton(
                tooltip: 'Opções do ingrediente',
                items: [
                  ActionMenuItem(
                    icon: price == null
                        ? Icons.add_circle_outline
                        : Icons.edit_outlined,
                    label: price == null ? 'Definir preço' : 'Editar preço',
                    onTap: onEditPrice,
                  ),
                  ActionMenuItem(
                    icon: inPantry ? Icons.kitchen : Icons.kitchen_outlined,
                    label: inPantry
                        ? 'Tirar da despensa'
                        : 'Sempre tenho (despensa)',
                    onTap: onTogglePantry,
                  ),
                  ActionMenuItem(
                    icon: Icons.call_merge,
                    label: 'Mesclar com...',
                    onTap: onPickMerge,
                  ),
                  if (onDelete != null)
                    ActionMenuItem(
                      icon: Icons.delete_outline,
                      label: 'Apagar',
                      onTap: onDelete!,
                    ),
                ],
              ),
            ],
          ),
          if (duplicateOf != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onMergeDuplicate,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: _Pill(
                  label: 'Parece com "${duplicateOf!.displayName}" · mesclar',
                  color: colors.coral,
                ),
              ),
            ),
          ],
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
