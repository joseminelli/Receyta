import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/data/repositories/tag_repository.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/folders/screens/folder_actions.dart';
import 'package:receyta/features/folders/screens/folders_strip.dart';
import 'package:receyta/features/folders/controllers/folders_view_model.dart';
import 'package:receyta/features/folders/screens/recipe_drag.dart';
import 'package:receyta/features/recipes/screens/ingredients_page.dart';
import 'package:receyta/features/recipes/screens/recipe_import_flow.dart';
import 'package:receyta/features/recipes/screens/recipe_ocr_flow.dart';
import 'package:receyta/features/recipes/screens/receyta_import_flow.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/features/recipes/screens/tags_page.dart';
import 'package:receyta/features/recipes/screens/trash_page.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/featured_recipe_card.dart';
import 'package:receyta/widgets/pull_to_refresh.dart';
import 'package:receyta/widgets/pill_button.dart';
import 'package:receyta/widgets/expanding_create_menu.dart';
import 'package:receyta/widgets/receytas_wordmark.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/state_badge.dart';
import 'package:receyta/widgets/tile_pattern.dart';
import 'package:receyta/widgets/recipe_card.dart';

/// Home da seção Receitas (§9.2): lista lida do Drift, `+` abre o formulário,
/// tocar num card abre o detalhe, lista horizontal de tags filtra (§RF-01.10).
/// Pastas (B10) e busca (B9) voltam com dados reais nos seus blocos.
class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipesStreamProvider);
    final filtering = ref.watch(selectedTagIdsProvider).isNotEmpty ||
        ref.watch(favoritesOnlyProvider);
    // Sem filtro, a prateleira "Recentes" mostra só as 7 últimas (§ "cap de
    // 7"); a contagem do cabeçalho e o estado vazio continuam olhando pra
    // lista completa (`recipes`), que já é a fonte de verdade de hoje.
    final recent = filtering ? null : ref.watch(recentRecipesProvider);
    // Cabeçalho mostra o total geral (todas as receitas, mesmo as em pasta) —
    // não a contagem da lista atual, que quando sem filtro é só a raiz.
    final totalCount = ref.watch(allRecipesProvider).valueOrNull?.length;

    // Ao começar a arrastar um card, sobe até a faixa de pastas pra ela estar
    // visível como alvo de soltar.
    ref.listen(draggingItemProvider, (prev, next) {
      if (prev == null && next != null && _controller.hasClients) {
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    void clearFilter() {
      ref.read(selectedTagIdsProvider.notifier).state = const {};
      ref.read(favoritesOnlyProvider.notifier).state = false;
    }

    void openNew() => context.push('/recipe/new');

    Future<void> refresh() async {
      for (final p in [
        recipesStreamProvider,
        recentRecipesProvider,
        allRecipesProvider,
        hasFavoritesProvider,
        inUseTagsProvider,
        recentFoldersProvider,
      ]) {
        ref.invalidate(p);
      }
      await ref.read(recipesStreamProvider.future);
    }

    return recipes.when(
      loading: () => _Scaffold(
        controller: _controller,
        count: totalCount,
        onCreate: openNew,
        onRefresh: refresh,
        body: const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: BrandLoader()),
        ),
      ),
      error: (_, __) => _Scaffold(
        controller: _controller,
        count: totalCount,
        onCreate: openNew,
        onRefresh: refresh,
        body: const SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(),
        ),
      ),
      data: (list) => _Scaffold(
        controller: _controller,
        count: totalCount,
        onCreate: openNew,
        onRefresh: refresh,
        body: list.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: filtering
                    ? _NoMatch(onClear: clearFilter)
                    : _EmptyState(onCreate: openNew),
              )
            : _RecipeList(
                recipes: filtering ? list : (recent?.valueOrNull ?? list),
                showViewAll: !filtering,
              ),
      ),
    );
  }
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({
    required this.controller,
    required this.count,
    required this.onCreate,
    required this.onRefresh,
    required this.body,
  });

  final ScrollController controller;
  final int? count;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return PullToRefreshControl(
      onRefresh: onRefresh,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverToBoxAdapter(child: _Header(count: count, onCreate: onCreate)),
          body,
        ],
      ),
    );
  }
}

/// Pílula do filtro de tags, desenhada para o header escuro: marcada em `lime`
/// com texto `ink`; solta em `inkSoft` com texto claro apagado. Cor e texto
/// fazem a transição suave, e a pílula dá um pequeno estouro elástico só ao
/// ENTRAR marcada (mesmo idioma do resto do app: nav bar, favoritar) — sair
/// não estoura, só a cor desliza de volta.
class _HeaderChip extends StatefulWidget {
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
  State<_HeaderChip> createState() => _HeaderChipState();
}

class _HeaderChipState extends State<_HeaderChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  @override
  void initState() {
    super.initState();
    // Valor de repouso é 1 (escala normal) nos dois estados — só o próprio
    // `.forward(from: 0)` mergulha até 0.85 de propósito, pro estouro.
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant _HeaderChip old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _pop.forward(from: 0);
    } else if (!widget.active) {
      _pop.value = 1;
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg =
        widget.active ? colors.ink : colors.onSaturated.withValues(alpha: 0.65);
    final scale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _pop, curve: Curves.easeOutBack),
    );
    return ScaleTransition(
      scale: scale,
      child: Material(
        color: widget.active ? colors.lime : colors.inkSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        animationDuration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  // `Icon` não lê `DefaultTextStyle` — a cor precisa de um
                  // tween próprio pra animar (`AnimatedDefaultTextStyle` não
                  // faria nada aqui).
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: fg),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, color, _) =>
                        Icon(widget.icon, size: 16, color: color),
                  ),
                  const SizedBox(width: AppSpacing.xs / 2),
                ],
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ) ??
                      TextStyle(color: fg),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeList extends StatelessWidget {
  const _RecipeList({required this.recipes, required this.showViewAll});

  final List<Recipe> recipes;

  /// Só faz sentido "Ver todas" quando a lista já veio capada em 7 (sem
  /// filtro) — filtrando, a lista mostrada já é a completa.
  final bool showViewAll;

  @override
  Widget build(BuildContext context) {
    final featured = recipes.first;
    final rest = recipes.skip(1).toList();

    return SliverMainAxisGroup(
      slivers: [
        const SliverToBoxAdapter(child: FoldersStrip()),
        _buildSectionHeader(context),
        _buildFeatured(context, featured),
        _buildGrid(context, rest),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 96),
          sliver: SliverToBoxAdapter(child: _HomeFooter()),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      sliver: SliverToBoxAdapter(
        child: SectionHeader(
          title: 'Recentes',
          action: showViewAll
              ? PillButton(
                  label: 'Ver todas',
                  variant: PillButtonVariant.ghost,
                  dense: true,
                  onPressed: () => context.push('/search'),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFeatured(BuildContext context, Recipe featured) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        AppSpacing.md,
      ),
      sliver: SliverToBoxAdapter(
        // Key por id: ao trocar o filtro, se o destaque virar outra receita,
        // o Flutter vê como um elemento novo e o fade de entrada dispara —
        // sem a key, ficaria só trocando o conteúdo do mesmo elemento, sem
        // reanimar (a troca de filtro continuaria cortando seco).
        child: _EntranceFade(
          key: ValueKey(featured.id),
          child: DraggableRecipe(
            recipe: featured,
            child: FeaturedRecipeCard(
              recipe: featured,
              onTap: () =>
                  context.push('/recipe/${featured.id}', extra: featured),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Recipe> rest) {
    return SliverPadding(
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
          (context, i) => _EntranceFade(
            key: ValueKey(rest[i].id),
            child: DraggableRecipe(
              recipe: rest[i],
              child: RecipeCard(
                recipe: rest[i],
                onTap: () =>
                    context.push('/recipe/${rest[i].id}', extra: rest[i]),
              ),
            ),
          ),
          childCount: rest.length,
        ),
      ),
    );
  }
}

/// Fade + leve crescimento na entrada — cobre tanto o primeiro carregamento
/// quanto um card novo aparecendo depois de trocar o filtro de tags (que
/// antes cortava seco). Sem key própria: quem usa passa `key:
/// ValueKey(recipe.id)`, senão o Flutter reaproveita o elemento e nunca
/// reanima ao trocar de receita na mesma posição da grade.
class _EntranceFade extends StatelessWidget {
  const _EntranceFade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
    );
  }
}

/// Rodapé da lista: acessos discretos a gerenciar tags, ingredientes e à
/// lixeira, lado a lado — cada um só aparece quando tem algo lá. Backup
/// mudou pra aba "Conta" (`AccountPage`), junto do resto de configurações.
class _HomeFooter extends StatelessWidget {
  const _HomeFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: TagsLink()),
        Flexible(child: IngredientsLink()),
        Flexible(child: TrashLink()),
      ],
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
    final hasFavorites = ref.watch(hasFavoritesProvider).valueOrNull ?? false;
    final favoritesOnly = ref.watch(favoritesOnlyProvider);
    final showBar = tags.isNotEmpty || hasFavorites;

    return AnnotatedRegion(
      value: SystemBars.onDark,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.lg),
        ),
        child: Container(
          color: colors.ink,
          child: Stack(
            children: [
              _buildPatternBackground(colors),
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
                      _buildTitleRow(context, ref, colors),
                      if (showBar)
                        _buildFilterBar(
                          context,
                          ref,
                          tags,
                          selected,
                          hasFavorites,
                          favoritesOnly,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternBackground(AppColors colors) {
    return Positioned(
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
    );
  }

  Widget _buildTitleRow(BuildContext context, WidgetRef ref, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
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
                  style: context.texts.labelSmall?.copyWith(color: colors.lime),
                ),
              ),
              _CircleButton(
                icon: Icons.search,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(width: AppSpacing.xs),
              ExpandingCreateMenu(
                buttonColor: colors.lime,
                iconColor: colors.ink,
                actions: [
                  CreateMenuAction(
                    icon: Icons.restaurant_menu,
                    label: 'Nova receita',
                    onSelected: onCreate,
                  ),
                  CreateMenuAction(
                    icon: Icons.create_new_folder_outlined,
                    label: 'Nova pasta',
                    onSelected: () => createFolderFlow(context, ref),
                  ),
                  CreateMenuAction(
                    icon: Icons.link,
                    label: 'Importar de link',
                    onSelected: () => importRecipeFromUrlFlow(context, ref),
                  ),
                  CreateMenuAction(
                    icon: Icons.camera_alt_outlined,
                    label: 'Importar de foto',
                    onSelected: () => importRecipeFromPhotoFlow(context, ref),
                  ),
                  CreateMenuAction(
                    icon: Icons.file_open_outlined,
                    label: 'Importar arquivo .receyta',
                    onSelected: () => importReceytaFileFlow(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const ReceytasWordmark(),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    WidgetRef ref,
    List<Tag> tags,
    Set<String> selected,
    bool hasFavorites,
    bool favoritesOnly,
  ) {
    const sidePad = EdgeInsets.symmetric(horizontal: AppSpacing.screen);

    void setSelected(Set<String> next) =>
        ref.read(selectedTagIdsProvider.notifier).state = next;
    void setFavoritesOnly(bool v) =>
        ref.read(favoritesOnlyProvider.notifier).state = v;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: sidePad,
          children: [
            _HeaderChip(
              label: 'Todas',
              active: selected.isEmpty && !favoritesOnly,
              onTap: () {
                setSelected(const {});
                setFavoritesOnly(false);
              },
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
                onLongPress: () =>
                    _confirmDeleteTag(context, ref, tag, selected, setSelected),
              ),
            ],
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
          style:
              context.texts.bodyLarge?.copyWith(color: context.colors.danger),
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
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.inkSoft,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 22, color: colors.onSaturated),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
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
            'Não deu para carregar as receitas',
            style: context.texts.displaySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StateBadge(
            icon: Icons.search_off_rounded,
            background: colors.ink,
            foreground: colors.lime,
          ),
          const SizedBox(height: AppSpacing.lg),
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

class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StateBadge(
            icon: Icons.restaurant_menu_rounded,
            background: colors.coral,
            foreground: colors.onSaturated,
          ),
          const SizedBox(height: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'ou traga uma que você já tem',
            style: context.texts.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            children: [
              PillButton(
                label: 'De um link',
                icon: Icons.link,
                variant: PillButtonVariant.ghost,
                dense: true,
                onPressed: () => importRecipeFromUrlFlow(context, ref),
              ),
              PillButton(
                label: 'De uma foto',
                icon: Icons.photo_camera_outlined,
                variant: PillButtonVariant.ghost,
                dense: true,
                onPressed: () => importRecipeFromPhotoFlow(context, ref),
              ),
              PillButton(
                label: 'De um arquivo',
                icon: Icons.upload_file_outlined,
                variant: PillButtonVariant.ghost,
                dense: true,
                onPressed: () => importReceytaFileFlow(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _HomeFooter(),
        ],
      ),
    );
  }
}
