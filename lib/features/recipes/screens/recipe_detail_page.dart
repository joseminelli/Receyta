import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/tile_style.dart';
import 'package:receyta/core/unit_label.dart';
import 'package:receyta/data/repositories/recipe_repository.dart';
import 'package:receyta/data/services/recipe_export_service.dart';
import 'package:receyta/domain/engine/ingredient_parser.dart';
import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/recipe_detail.dart';
import 'package:receyta/domain/models/recipe_ingredient.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/folders/screens/folder_actions.dart';
import 'package:receyta/features/recipes/controllers/recipe_form_view_model.dart';
import 'package:receyta/features/recipes/screens/cook_log_sheet.dart';
import 'package:receyta/features/recipes/screens/recipe_status_cards.dart';
import 'package:receyta/features/shopping/screens/add_to_shopping_list_flow.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/features/recipes/screens/recipe_photo_flow.dart';
import 'package:receyta/widgets/app_snackbar.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/expanding_create_menu.dart';
import 'package:receyta/widgets/hero_number.dart';
import 'package:receyta/widgets/metric_stat.dart';
import 'package:receyta/widgets/section_header.dart';
import 'package:receyta/widgets/skeleton_box.dart';
import 'package:receyta/widgets/tile_appearance.dart';
import 'package:receyta/widgets/recipe_cover.dart';
import 'package:receyta/widgets/tile_style_picker.dart';
import 'package:receyta/widgets/app_sheet.dart';

/// Tela de detalhe da receita (B6): "dá para cozinhar lendo pelo app". Hero
/// `coral` com azulejo (§9.2), sheet de conteúdo subindo 18px sobre ele
/// (§9.8). Ingredientes e passos em fundo chapado — o padrão nunca entra atrás
/// de texto que se lê linha a linha (§9.4).
class RecipeDetailPage extends ConsumerStatefulWidget {
  const RecipeDetailPage(
      {super.key, required this.recipeId, this.initialRecipe});

  final String recipeId;

  /// A receita já em mãos de quem navegou pra cá (o card tocado na lista) —
  /// pré-preenche o hero (cor/azulejo/nome/métricas) no primeiro frame, sem
  /// esperar o `recipeDetailProvider` resolver. Sem isso, o Hero de
  /// card→detalhe às vezes não achava a tag de destino a tempo do voo
  /// começar (ficava no skeleton genérico ainda) e não animava, ou animava
  /// com a cor errada. Nulo em entradas sem card de origem (deep link).
  final Recipe? initialRecipe;

  @override
  ConsumerState<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends ConsumerState<RecipeDetailPage> {
  @override
  void initState() {
    super.initState();
    // Sobe pro topo da prateleira "Recentes" da home (§ "recentes") — mas só
    // depois que o voo do Hero (card→hero, 500ms no router — se mudar lá,
    // muda aqui também) termina. Se a lista de origem reordenar ENQUANTO o
    // Hero ainda está voando (o card tocado pode até virar o
    // `FeaturedRecipeCard`, widget diferente), o Flutter recria o Hero de
    // origem no meio do voo e quebra com 'manifest.tag == newManifest.tag'.
    Future.delayed(const Duration(milliseconds: 520), () {
      if (mounted) {
        ref.read(recipeRepositoryProvider).markOpened(widget.recipeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _resolveChild(detailAsync),
    );
  }

  Widget _resolveChild(AsyncValue<RecipeDetail?> detailAsync) {
    if (detailAsync.hasError) {
      return const _Missing(key: ValueKey('missing'));
    }
    final loaded = detailAsync.valueOrNull;
    if (detailAsync is AsyncData<RecipeDetail?> && loaded == null) {
      return const _Missing(key: ValueKey('missing'));
    }
    final recipe = loaded?.recipe ?? widget.initialRecipe;
    if (recipe == null) {
      // Sem receita otimista (deep link) e ainda carregando — não tem cor
      // de verdade pra mostrar ainda, cai pro skeleton genérico.
      return const _DetailSkeleton(key: ValueKey('skeleton'));
    }
    // Mesma key sempre: quando `detail` chega depois do `recipe` otimista,
    // isto não conta como "trocar de filho" pro AnimatedSwitcher — só
    // reconstrói no lugar, sem crossfade nem novo voo de Hero.
    return _Detail(
        key: const ValueKey('detail'), recipe: recipe, detail: loaded);
  }
}

class _Missing extends StatelessWidget {
  const _Missing({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.paper,
      appBar: AppBar(leading: const BackButton()),
      body: Center(
        child: Text('Receita não encontrada', style: context.texts.bodyMedium),
      ),
    );
  }
}

/// Enquanto o `recipeDetailProvider` não emitiu o primeiro valor — silhueta
/// do `_Hero` (bloco coral, botões circulares, título) + da folha de
/// conteúdo (métricas, algumas linhas), em vez da tela em branco.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onHero = colors.onSaturated;

    return Scaffold(
      backgroundColor: colors.paper,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildHeroSkeleton(colors, onHero),
          _buildBodySkeleton(),
        ],
      ),
    );
  }

  Widget _buildHeroSkeleton(AppColors colors, Color onHero) {
    return Container(
      height: 300,
      color: colors.coral,
      child: SafeArea(
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
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: AppRadii.pill,
                    color: onHero,
                  ),
                  const Spacer(),
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: AppRadii.pill,
                    color: onHero,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: AppRadii.pill,
                    color: onHero,
                  ),
                ],
              ),
              const Spacer(),
              SkeletonBox(width: 220, height: 40, color: onHero),
              const SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 140, height: 40, color: onHero),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodySkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xl,
        AppSpacing.screen,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 64, height: 44),
              SkeletonBox(width: 64, height: 44),
              SkeletonBox(width: 64, height: 44),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const SkeletonBox(width: 140, height: 18),
          const SizedBox(height: AppSpacing.sm),
          for (final w in const [double.infinity, 260.0, 200.0, 240.0]) ...[
            SkeletonBox(width: w.isFinite ? w : null, height: 16),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({super.key, required this.recipe, required this.detail});

  final Recipe recipe;

  /// Nulo enquanto o `recipeDetailProvider` ainda não resolveu — o [recipe]
  /// (otimista, de quem navegou pra cá) já basta pro hero e pras métricas;
  /// ingredientes/passos/tags mostram um loader curto até isto chegar.
  final RecipeDetail? detail;

  @override
  Widget build(BuildContext context) {
    final loadedDetail = detail;
    final hasSteps = loadedDetail?.steps.isNotEmpty ?? false;
    final hasIngredients = loadedDetail?.ingredients.isNotEmpty ?? false;

    // Calculado uma vez por carregamento da receita (não a cada rebuild de
    // linha): parsear a mesma string toda hora que a linha reconstrói é
    // trabalho refeito à toa.
    final parsedIngredients = [
      for (final i in loadedDetail?.ingredients ?? const <RecipeIngredient>[])
        i.quantity == null ? null : parseIngredientLine(i.rawText),
    ];

    return Scaffold(
      backgroundColor: context.colors.paper,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child:
                    _Hero(recipe: recipe, tags: loadedDetail?.tags ?? const []),
              ),
              _buildIntroSliver(context, recipe, hasIngredients),
              if (loadedDetail == null)
                _buildBodyLoadingSliver()
              else ...[
                // Ingredientes e passos entram em slivers lazy próprios (em
                // vez de dentro do Column acima): receitas longas deixam de
                // montar todas as linhas de uma vez, só as visíveis (+
                // cache) chegam a ser construídas.
                if (hasIngredients)
                  _buildIngredientsSliver(loadedDetail, parsedIngredients),
                _buildPreparoHeaderSliver(context, hasSteps),
                if (hasSteps) _buildStepsSliver(loadedDetail),
                _buildNotesSliver(context, recipe, hasSteps),
              ],
            ],
          ),
          if (hasSteps)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _CookBar(recipeId: recipe.id),
            ),
        ],
      ),
    );
  }

  Widget _buildIntroSliver(
    BuildContext context,
    Recipe recipe,
    bool hasIngredients,
  ) {
    final colors = context.colors;
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          color: colors.paper,
          border: Border(top: BorderSide(color: colors.paperSoft, width: 1.5)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Metrics(recipe: recipe),
            const SizedBox(height: AppSpacing.md),
            RecipeStatusCards(recipeId: recipe.id),
            const SizedBox(height: AppSpacing.xs),
            CookedCard(recipeId: recipe.id),
            if ((recipe.about ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(recipe.about!, style: context.texts.bodyLarge),
            ],
            if (hasIngredients) ...[
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Ingredientes',
                action: _CountPill(detail!.ingredients.length, 'item', 'itens'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  /// Loader curto pra seção de ingredientes/passos enquanto só o [recipe]
  /// otimista chegou — o hero e as métricas já aparecem, só o corpo espera.
  Widget _buildBodyLoadingSliver() {
    return const SliverPadding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      sliver: SliverToBoxAdapter(
        child: Center(child: BrandLoader()),
      ),
    );
  }

  Widget _buildIngredientsSliver(
    RecipeDetail detail,
    List<ParsedIngredientLine?> parsedIngredients,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _groupedItem(
            detail.ingredients,
            i,
            (x) => x.groupLabel,
            (idx, x) => _IngredientRow(x, parsedIngredients[idx]),
          ),
          childCount: detail.ingredients.length,
        ),
      ),
    );
  }

  Widget _buildPreparoHeaderSliver(BuildContext context, bool hasSteps) {
    return SliverToBoxAdapter(
      child: Container(
        color: context.colors.paper,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: hasSteps
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _Label('Preparo'),
                  const SizedBox(height: AppSpacing.sm),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildStepsSliver(RecipeDetail detail) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _groupedItem(
            detail.steps,
            i,
            (s) => s.groupLabel,
            (idx, s) => _Step(index: idx + 1, text: s.text),
          ),
          childCount: detail.steps.length,
        ),
      ),
    );
  }

  Widget _buildNotesSliver(BuildContext context, Recipe recipe, bool hasSteps) {
    final hasNotes = (recipe.notes ?? '').isNotEmpty;
    return SliverToBoxAdapter(
      child: Container(
        color: context.colors.paper,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          hasSteps ? 120 : AppSpacing.xxl,
        ),
        child: hasNotes
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  _Label('Notas'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(recipe.notes!, style: context.texts.bodyLarge),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.recipe, this.tags = const []});

  final Recipe recipe;
  final List<Tag> tags;

  int? get _totalMinutes {
    final total = (recipe.prepMinutes ?? 0) + (recipe.cookMinutes ?? 0);
    return total == 0 ? null : total;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(recipeRepositoryProvider);
    await repo.softDelete(recipe.id);
    if (!context.mounted) return;
    context.pop();
    showAppSnackBar(
      message: 'Receita movida para a lixeira',
      actionLabel: 'Desfazer',
      onAction: () => repo.restore(recipe.id),
    );
  }

  Future<void> _shareAs(
    BuildContext context,
    WidgetRef ref,
    Future<Result<void>> Function(RecipeExportService) action,
  ) async {
    final result = await action(ref.read(recipeExportServiceProvider));
    result.when(
      ok: (_) {},
      err: (f) => showAppSnackBar(
        message: f.message,
        variant: AppSnackBarVariant.error,
      ),
    );
  }

  void _showShare(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => AppSheetFrame(
        title: 'Compartilhar',
        subtitle: recipe.name,
        child: AppSheetOptions(
          children: [
            AppSheetOption(
              icon: Icons.description_outlined,
              title: 'Arquivo .receyta',
              subtitle: 'Pra importar em outro Receyta',
              onTap: () {
                Navigator.of(sheet).pop();
                _shareAs(context, ref, (s) => s.shareRecipe(recipe.id));
              },
            ),
            AppSheetOption(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF',
              subtitle: 'Pra imprimir ou ler em outro app',
              onTap: () {
                Navigator.of(sheet).pop();
                _shareAs(context, ref, (s) => s.sharePdf(recipe.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Ações do leque que substitui o "⋯" (§ hero): editar/compartilhar, antes
  /// botões próprios, entraram aqui junto do que já vivia no sheet de "Mais".
  List<CreateMenuAction> _menuActions(BuildContext context, WidgetRef ref) {
    return [
      CreateMenuAction(
        icon: Icons.edit_outlined,
        label: 'Editar',
        onSelected: () => context.push('/recipe/${recipe.id}/edit'),
      ),
      CreateMenuAction(
        icon: Icons.ios_share,
        label: 'Compartilhar',
        onSelected: () => _showShare(context, ref),
      ),
      CreateMenuAction(
        icon: Icons.add_a_photo_outlined,
        label: 'Foto',
        onSelected: () => changeRecipePhoto(context, ref, recipe),
      ),
      CreateMenuAction(
        icon: Icons.palette_outlined,
        label: 'Aparência',
        onSelected: () => showAppearanceSheet(
          context,
          title: 'Aparência de "${recipe.name}"',
          color: recipe.tileColor,
          motif: recipe.tileMotif,
          fallbackColor: TileColor.coral,
          seedId: recipe.id,
          onChanged: (c, m) => ref
              .read(recipeRepositoryProvider)
              .setAppearance(recipe.id, color: c, motif: m),
        ),
      ),
      CreateMenuAction(
        icon: Icons.drive_file_move_outline,
        label: 'Mover para pasta',
        onSelected: () =>
            moveRecipeFlow(context, ref, recipe.id, recipe.folderId),
      ),
      CreateMenuAction(
        icon: Icons.delete_outline,
        label: 'Mover para a lixeira',
        onSelected: () => _delete(context, ref),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final minutes = _totalMinutes;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );

    // Cartão de cor: canto arredondado embaixo e sombra, para ler como um bloco
    // por cima do conteúdo. Sombra é um `BoxShadow` estático fora do clip (não
    // `Material.elevation` — mais leve pra rolar por trás de uma lista longa,
    // sem sombra física recalculada). `AnnotatedRegion`: hora/bateria em branco
    // enquanto o hero cobre o topo; ao rolar, o sheet claro assume e volta ao
    // escuro.
    final heroRadius = const BorderRadius.vertical(
      bottom: Radius.circular(AppRadii.lg),
    );
    return AnnotatedRegion(
      value: SystemBars.onDark,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: heroRadius,
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: heroRadius,
          child: ColoredBox(
            color: tile.background,
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: recipeTileHeroTag(recipe.id),
                      flightShuttleBuilder: recipeTileHeroFlightShuttleBuilder,
                      child: RecipeCover(
                        recipe: recipe,
                        tile: tile,
                        scrim: true,
                        cacheWidth: 1200,
                      ),
                    ),
                  ),
                  if (minutes != null)
                    _buildMinutesBadge(context, minutes, tile),
                  _buildTopContent(context, ref, colors, tile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinutesBadge(
    BuildContext context,
    int minutes,
    TileAppearance tile,
  ) {
    return Transform.translate(
      offset: const Offset(-40, -20), // 40px pra esquerda, 30px pra cima
      child: HeroNumber(
        value: '$minutes',
        unit: 'min',
        color:
            RecipeCover.onColor(context, recipe, tile).withValues(alpha: 0.5),
        corner: Alignment.bottomRight,
        size: 100,
      ),
    );
  }

  Widget _buildTopContent(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
    TileAppearance tile,
  ) {
    return SafeArea(
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
                _HeroCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => context.pop(),
                  tooltip: 'Voltar',
                ),
                const Spacer(),
                _FavoriteButton(
                  isFavorite: recipe.isFavorite,
                  onTap: () => ref
                      .read(recipeRepositoryProvider)
                      .setFavorite(recipe.id, !recipe.isFavorite),
                ),
                const SizedBox(width: AppSpacing.xs),
                ExpandingCreateMenu(
                  icon: Icons.more_horiz,
                  tooltip: 'Mais',
                  buttonColor: colors.ink,
                  iconColor: colors.onSaturated,
                  actions: _menuActions(context, ref),
                ),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in tags)
                    _TagPill(t.name, heroColor: tile.background),
                ],
              ),
            ],
            const Spacer(),
            Text(
              recipe.name,
              style: AppTextStyles.display(44)
                  .copyWith(color: RecipeCover.onColor(context, recipe, tile)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de ingrediente como texto corrido, com quantidade e unidade em
/// negrito no meio da frase — sem coluna nem alinhamento forçado, lê como
/// texto normal. Sem quantidade reconhecida (linha que o parser não deu
/// conta), cai pro `rawText` cru — nunca esconde o que o usuário digitou.
class _IngredientRow extends StatelessWidget {
  const _IngredientRow(this.ingredient, this.parsed);

  final RecipeIngredient ingredient;

  /// Calculado uma vez por carregamento da receita (ver `build()` da página),
  /// não a cada rebuild desta linha.
  final ParsedIngredientLine? parsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final qty = ingredient.quantity;

    if (qty == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text(ingredient.rawText, style: context.texts.bodyLarge),
      );
    }

    final parsed = this.parsed!;
    final unit = unitLabel(ingredient.unitId, qty);
    final base = context.texts.bodyLarge?.copyWith(color: colors.ink);
    final quantityStyle = AppTextStyles.metric.copyWith(color: colors.ink);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: RichText(
        text: TextSpan(
          style: base,
          children: [
            ..._quantitySpans(qty, quantityStyle, colors.textMuted),
            if (unit != null) ...[
              TextSpan(
                text: '   $unit',
                style: AppTextStyles.display(15).copyWith(
                  color: colors.textMuted,
                ),
              ),
              const TextSpan(text: ' de'),
            ],
            // Nome do catálogo (já normalizado — ver `IngredientDao
            // .getOrCreate`) tem prioridade sobre o que o parser extraiu do
            // `rawText`: são fontes diferentes e o catálogo é o que
            // realmente fica salvo, então é o que a receita deve mostrar.
            TextSpan(text: ' ${ingredient.ingredientName ?? parsed.name}'),
            if (parsed.qualifier != null)
              TextSpan(
                text: ', ${parsed.qualifier}',
                style: base?.copyWith(color: colors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Frações comuns de cozinha reconhecidas na parte decimal — mostra "2 e ½"
/// com fração de verdade (numerador sobre denominador) em vez de decimal
/// ("2,5", ou pior, "2,3333333333333335" pra 1/3).
final _fractionTable = [
  (0.5, 1, 2),
  (1 / 3, 1, 3),
  (2 / 3, 2, 3),
  (0.25, 1, 4),
  (0.75, 3, 4),
  (0.2, 1, 5),
  (0.4, 2, 5),
  (0.6, 3, 5),
  (0.8, 4, 5),
  (1 / 6, 1, 6),
  (5 / 6, 5, 6),
  (0.125, 1, 8),
  (0.375, 3, 8),
  (0.625, 5, 8),
  (0.875, 7, 8),
];

/// Spans da quantidade: número inteiro, opcionalmente seguido de "e" + a
/// fração empilhada. Sem fração reconhecida, cai num decimal arredondado.
List<InlineSpan> _quantitySpans(double q, TextStyle style, Color eColor) {
  final whole = q.floor();
  final frac = q - whole;
  if (frac < 0.005) {
    return [TextSpan(text: '$whole', style: style)];
  }

  for (final (value, num, den) in _fractionTable) {
    if ((frac - value).abs() < 0.02) {
      return [
        if (whole > 0) ...[
          TextSpan(text: '$whole', style: style),
          TextSpan(
            text: '   e ',
            style: style.copyWith(
              fontSize: (style.fontSize ?? 16) * 0.6,
              color: eColor,
            ),
          ),
        ],
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _StackedFraction(
            numerator: num,
            denominator: den,
            style: style,
          ),
        ),
      ];
    }
  }
  return [TextSpan(text: _trimDecimal(q), style: style)];
}

String _trimDecimal(double q) {
  var s = q.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', ',');
}

/// Fração de verdade: numerador em cima, traço, denominador embaixo — em
/// vez do caractere unicode (½, ⅓...), que a fonte display não tem no
/// conjunto de glyphs e cai pra fonte do sistema no meio do texto.
class _StackedFraction extends StatelessWidget {
  const _StackedFraction({
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  final int numerator;
  final int denominator;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final digitSize = (style.fontSize ?? 16) * 0.68;
    final digitStyle = style.copyWith(fontSize: digitSize, height: 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$numerator', style: digitStyle),
          Container(
            width: digitSize,
            height: 1.4,
            margin: const EdgeInsets.symmetric(vertical: 1),
            color: style.color,
          ),
          Text('$denominator', style: digitStyle),
        ],
      ),
    );
  }
}

/// Item de uma lista de ingredientes ou passos (§RF-01.4), com o subtítulo de
/// grupo embutido acima dele quando o grupo muda em relação ao item anterior.
/// Olha só `items[index]` e `items[index - 1]` — chamado sob demanda por um
/// `SliverChildBuilderDelegate`, então só os itens visíveis (+ cache) chegam
/// a ser construídos, ao contrário de intercalar tudo numa lista eager.
Widget _groupedItem<T>(
  List<T> items,
  int index,
  String? Function(T item) groupOf,
  Widget Function(int index, T item) row,
) {
  final g = groupOf(items[index]);
  final prevGroup = index > 0 ? groupOf(items[index - 1]) : null;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (g != prevGroup && g != null && g.isNotEmpty) _GroupLabel(g),
      row(index, items[index]),
    ],
  );
}

/// Separador de grupo (§RF-01.4): fonte display em `coral` (cor da seção
/// Receitas, §9.2) com um traço curto embaixo, hugando o texto.
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.coral, width: 3),
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.display(19).copyWith(color: colors.coral),
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    final stats = <Widget>[
      if (recipe.prepMinutes != null)
        MetricStat(
          value: '${recipe.prepMinutes}',
          unit: 'm',
          label: 'Preparo',
          valueSize: size,
        ),
      if (recipe.cookMinutes != null)
        MetricStat(
          value: '${recipe.cookMinutes}',
          unit: 'm',
          label: 'Fogão',
          valueSize: size,
        ),
      if (recipe.servings != null)
        MetricStat(
          value: '${recipe.servings}',
          label: 'Porções',
          valueSize: size,
        ),
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: stats,
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: context.colors.paperSoft),
      ],
    );
  }
}

/// Tag sobre o hero: pílula `lime` com texto `ink` por padrão (§9.2). Se o hero
/// for lime (o usuário pode escolher a cor, §9.4), a pílula vira `ink` pra
/// nunca sumir no fundo.
class _TagPill extends StatelessWidget {
  const _TagPill(this.label, {required this.heroColor});

  final String label;
  final Color heroColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onLime = heroColor.computeLuminance() > 0.6;
    final pillColor = onLime ? colors.ink : colors.lime;
    final textColor = onLime ? colors.onSaturated : colors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: pillColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: context.texts.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.texts.displaySmall);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              '$index'.padLeft(2, '0'),
              style: AppTextStyles.display(34)
                  .copyWith(color: context.colors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(text, style: context.texts.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão circular preenchido sobre o hero — voltar e editar (screenshot B6).
class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, size: 22, color: colors.onSaturated),
          ),
        ),
      ),
    );
  }
}

/// Botão de favoritar: ao MARCAR (não ao desmarcar), o coração estoura de
/// tamanho e recua elástico, com um anel se expandindo e sumindo atrás dele —
/// mesmo "burst" do coração do Instagram/Twitter, com o vocabulário de
/// animação que já existe no app (`easeOutBack`/pop do ícone da navbar).
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _FavoriteButton old) {
    super.didUpdateWidget(old);
    if (widget.isFavorite && !old.isFavorite) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_burst);
    final ringScale = Tween<double>(begin: 0.5, end: 1.9).animate(
      CurvedAnimation(parent: _burst, curve: Curves.easeOut),
    );
    final ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _burst, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: _burst,
      builder: (context, child) {
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_burst.value > 0)
                Opacity(
                  opacity: ringOpacity.value,
                  child: Transform.scale(
                    scale: ringScale.value,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.coral, width: 2),
                      ),
                    ),
                  ),
                ),
              Transform.scale(scale: scale.value, child: child),
            ],
          ),
        );
      },
      child: _HeroCircleButton(
        icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
        onTap: widget.onTap,
        tooltip: widget.isFavorite ? 'Desfavoritar' : 'Favoritar',
      ),
    );
  }
}

/// Contagem discreta ao lado de um título de seção ("6 itens").
class _CountPill extends StatelessWidget {
  const _CountPill(this.count, this.singular, this.plural);

  final int count;
  final String singular;
  final String plural;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        '$count ${count == 1 ? singular : plural}',
        style: context.texts.labelLarge?.copyWith(color: colors.textBody),
      ),
    );
  }
}

/// Barra fixa no rodapé: abre o modo cozinha (§RF-01.11) e, ao lado, o botão
/// de adicionar a receita a uma lista de compras (RF-05.1).
class _CookBar extends ConsumerWidget {
  const _CookBar({required this.recipeId});

  final String recipeId;

  static const _height = AppSpacing.minTapTarget + 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Container(
      color: colors.paper,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(child: _buildCookButton(context)),
              const SizedBox(width: AppSpacing.xs),
              _buildAddToListButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCookButton(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.ink,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: () => context.push('/recipe/$recipeId/cook'),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          height: _height,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 20, color: colors.lime),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Modo cozinha',
                style: context.texts.labelLarge?.copyWith(color: colors.lime),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Círculo lime com sacola + "+" em ink.
  Widget _buildAddToListButton(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'Adicionar à lista de compras',
      child: Tooltip(
        message: 'Adicionar à lista de compras',
        child: Material(
          color: colors.lime,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => addRecipeToShoppingListFlow(context, ref, recipeId),
            child: SizedBox(
              width: _height,
              height: _height,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 26, color: colors.ink),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.add, size: 14, color: colors.ink),
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
