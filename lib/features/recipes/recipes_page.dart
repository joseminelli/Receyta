import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/features/recipes/tags_page.dart';
import 'package:receyta/features/recipes/trash_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/recipe_card.dart';

/// Home da seção Receitas (§9.2): lista lida do Drift, `+` abre o formulário,
/// tocar num card abre o detalhe, lista horizontal de tags filtra (§RF-01.10).
/// Pastas (B10) e busca (B9) voltam com dados reais nos seus blocos.
class RecipesPage extends ConsumerWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipes = ref.watch(recipesStreamProvider);
    final filtering = ref.watch(selectedTagIdsProvider).isNotEmpty ||
        ref.watch(favoritesOnlyProvider);
    void clearFilter() {
      ref.read(selectedTagIdsProvider.notifier).state = const {};
      ref.read(favoritesOnlyProvider.notifier).state = false;
    }

    void openNew() => context.push('/recipe/new');

    return recipes.when(
      loading: () => _Scaffold(
        count: null,
        onCreate: openNew,
        body: const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
      error: (_, __) => _Scaffold(
        count: null,
        onCreate: openNew,
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
        onCreate: openNew,
        body: list.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: filtering
                    ? _NoMatch(onClear: clearFilter)
                    : _EmptyState(onCreate: openNew),
              )
            : _RecipeList(recipes: list),
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

/// Pílula do filtro de tags, desenhada para o header escuro: marcada em `lime`
/// com texto `ink`; solta em `inkSoft` com texto claro apagado.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = active ? colors.ink : colors.onSaturated.withValues(alpha: 0.65);
    return Material(
      color: active ? colors.lime : colors.inkSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: AppSpacing.xs / 2),
              ],
              Text(
                label,
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
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
    void open(String id) => context.push('/recipe/$id');

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
            child: FeaturedRecipeCard(
              recipe: featured,
              onTap: () => open(featured.id),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            0,
            AppSpacing.screen,
            AppSpacing.lg,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => RecipeCard(
                recipe: rest[i],
                onTap: () => open(rest[i].id),
              ),
              childCount: rest.length,
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 96),
          sliver: SliverToBoxAdapter(child: _HomeFooter()),
        ),
      ],
    );
  }
}

/// Rodapé da lista: acessos discretos a gerenciar tags e à lixeira, cada um
/// só aparece quando tem algo lá.
class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      children: [TagsLink(), TrashLink()],
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.count, required this.onCreate});

  final int? count;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final tags = ref.watch(inUseTagsProvider).valueOrNull ?? const <Tag>[];
    final selected = ref.watch(selectedTagIdsProvider);
    final hasFavorites =
        ref.watch(hasFavoritesProvider).valueOrNull ?? false;
    final favoritesOnly = ref.watch(favoritesOnlyProvider);
    final showBar = tags.isNotEmpty || hasFavorites;

    void setSelected(Set<String> next) =>
        ref.read(selectedTagIdsProvider.notifier).state = next;
    void setFavoritesOnly(bool v) =>
        ref.read(favoritesOnlyProvider.notifier).state = v;
    void clearFilter() {
      setSelected(const {});
      setFavoritesOnly(false);
    }

    const sidePad = EdgeInsets.symmetric(horizontal: AppSpacing.screen);

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
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: sidePad,
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
                                    text: 'y',
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
                    if (showBar) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: sidePad,
                          children: [
                            _HeaderChip(
                              label: 'Todas',
                              active: selected.isEmpty && !favoritesOnly,
                              onTap: clearFilter,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            if (hasFavorites) ...[
                              _HeaderChip(
                                label: 'Favoritos',
                                icon: Icons.favorite,
                                active: favoritesOnly,
                                onTap: () => setFavoritesOnly(!favoritesOnly),
                              ),
                            ],
                            for (final tag in tags) ...[
                              const SizedBox(width: AppSpacing.xs),
                              _HeaderChip(
                                label: tag.name,
                                active: selected.contains(tag.id),
                                onTap: () {
                                  final next = Set<String>.from(selected);
                                  if (!next.remove(tag.id)) next.add(tag.id);
                                  setSelected(next);
                                },
                                onLongPress: () => _confirmDeleteTag(
                                  context,
                                  ref,
                                  tag,
                                  selected,
                                  setSelected,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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

/// Segurar um chip do filtro abre isto: remover a tag de todas as receitas
/// (§RF-01.10) — some da lista de filtro pra sempre.
Future<void> _confirmDeleteTag(
  BuildContext context,
  WidgetRef ref,
  Tag tag,
  Set<String> selected,
  void Function(Set<String>) setSelected,
) async {
  final repo = ref.read(tagRepositoryProvider);
  final uses = await repo.usageCount(tag.id);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListTile(
        leading: Icon(Icons.label_off_outlined, color: context.colors.danger),
        title: Text(
          'Remover "${tag.name}"',
          style: context.texts.bodyLarge
              ?.copyWith(color: context.colors.danger),
        ),
        subtitle: Text(
          uses == 0
              ? 'Não está em nenhuma receita.'
              : 'Sai de $uses receita${uses == 1 ? '' : 's'}.',
          style: context.texts.bodyMedium,
        ),
        onTap: () async {
          Navigator.of(sheet).pop();
          await repo.delete(tag.id);
          if (selected.contains(tag.id)) {
            setSelected(Set<String>.from(selected)..remove(tag.id));
          }
        },
      ),
    ),
  );
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

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nada nesse filtro',
            style: context.texts.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: 'Limpar filtro',
            variant: PillButtonVariant.secondary,
            onPressed: onClear,
          ),
        ],
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
          const SizedBox(height: AppSpacing.md),
          const _HomeFooter(),
        ],
      ),
    );
  }
}
