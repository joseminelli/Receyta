import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/recipe_card.dart';

/// Home da seção Receitas (§9.2). B3 liga a lista no `recipeRepositoryProvider`
/// e cria receita só com nome. Pastas (B10) e filtros (B9/B10) voltam com dados
/// reais nos seus blocos.
class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesStreamProvider);

    return recipes.when(
      loading: () => _Scaffold(
        count: null,
        onCreate: () => _createRecipe(context, ref),
        body: const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => _Scaffold(
        count: null,
        onCreate: () => _createRecipe(context, ref),
        body: SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'Não deu para carregar as receitas',
              style: context.texts.bodyMedium,
            ),
          ),
        ),
      ),
      data: (list) => _Scaffold(
        count: list.length,
        onCreate: () => _createRecipe(context, ref),
        body: list.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreate: () => _createRecipe(context, ref)),
              )
            : _RecipeList(recipes: list),
      ),
    );
  }

  Future<void> _createRecipe(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewRecipeDialog(),
    );
    if (name == null) return;

    final result = await ref.read(recipesViewModelProvider).createByName(name);
    if (!context.mounted) return;
    result.when(
      ok: (_) {},
      err: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.count,
    required this.onCreate,
    required this.body,
  });

  final int? count;
  final VoidCallback onCreate;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Header(count: count, onCreate: onCreate)),
        body,
      ],
    );
  }
}

class _RecipeList extends StatelessWidget {
  const _RecipeList({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context) {
    final featured = recipes.first;
    final rest = recipes.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(title: 'Recentes'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: FeaturedRecipeCard(recipe: featured, onTap: () {}),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            96,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => RecipeCard(recipe: rest[i], onTap: () {}),
              childCount: rest.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onCreate});

  final int? count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.lg),
      ),
      child: Container(
        color: colors.ink,
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: SizedBox(
                width: 260,
                height: 260,
                child: TilePattern(
                  motif: TileMotif.arco,
                  background: colors.ink,
                  patternColor: colors.inkPattern,
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.xs,
                  AppSpacing.screen,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            count == null
                                ? ''
                                : '$count ${count == 1 ? 'RECEITA' : 'RECEITAS'}',
                            style: context.texts.labelSmall
                                ?.copyWith(color: colors.lime),
                          ),
                        ),
                        _CircleButton(
                          icon: Icons.add,
                          filled: true,
                          onTap: onCreate,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          style: AppTextStyles.display(64)
                              .copyWith(color: colors.onSaturated),
                          children: [
                            const TextSpan(text: 'Rece'),
                            TextSpan(
                              text: 'i',
                              style: TextStyle(color: colors.coral),
                            ),
                            const TextSpan(text: 'tas'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: filled ? colors.lime : colors.inkSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 22,
            color: filled ? colors.ink : colors.onSaturated,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Nenhuma receita ainda',
            style: context.texts.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Comece pelo nome — o resto entra depois.',
            style: context.texts.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: 'Nova receita',
            icon: Icons.add,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// Diálogo mínimo do B3: só o nome. O formulário completo é o B4.
class _NewRecipeDialog extends StatefulWidget {
  const _NewRecipeDialog();

  @override
  State<_NewRecipeDialog> createState() => _NewRecipeDialogState();
}

class _NewRecipeDialogState extends State<_NewRecipeDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid => _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      title: Text('Nova receita', style: context.texts.displaySmall),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Nome da receita'),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        PillButton(
          label: 'Cancelar',
          variant: PillButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        PillButton(
          label: 'Criar',
          onPressed: _valid ? _submit : null,
        ),
      ],
    );
  }
}
