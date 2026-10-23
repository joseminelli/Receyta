import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/features/recipes/controllers/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/brand_loader.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Busca (§RF-01.9): nome, sobre, notas (FTS5) e tag. Campo em pílula sobre um
/// bloco `ink` (mesma linguagem do header da home), atalhos de tag quando vazio,
/// resultados na mesma grade da home.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const _recentKey = 'recent_searches';
  static const _recentLimit = 8;
  static const _quickMinutes = 30;

  final _controller = TextEditingController();
  Timer? _debounce;
  bool _onlyFavorites = false;
  bool _onlyQuick = false;
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_recentKey) ?? const <String>[];
    if (mounted) setState(() => _recent = stored);
  }

  Future<void> _remember(String raw) async {
    final term = raw.trim();
    if (term.isEmpty) return;
    final next = [
      term,
      ..._recent.where((r) => r.toLowerCase() != term.toLowerCase()),
    ].take(_recentLimit).toList();
    setState(() => _recent = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentKey, next);
  }

  Future<void> _clearRecent() async {
    setState(() => _recent = const []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
  }

  List<Recipe> _applyFilters(List<Recipe> list) {
    if (!_onlyFavorites && !_onlyQuick) return list;
    return [
      for (final r in list)
        if ((!_onlyFavorites || r.isFavorite) && (!_onlyQuick || _isQuick(r)))
          r,
    ];
  }

  bool _isQuick(Recipe r) {
    final total = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
    return total > 0 && total <= _quickMinutes;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _setQuery(String value) {
    _debounce?.cancel();
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    ref.read(searchQueryProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = ref.watch(searchQueryProvider).trim();
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: colors.paper,
      body: Column(
        children: [
          _SearchHeader(
            controller: _controller,
            onChanged: _onChanged,
            onClear: () => _setQuery(''),
            onBack: () => context.pop(),
            onSubmitted: _remember,
          ),
          _QuickFilters(
            onlyFavorites: _onlyFavorites,
            onlyQuick: _onlyQuick,
            onFavorites: (v) => setState(() => _onlyFavorites = v),
            onQuick: (v) => setState(() => _onlyQuick = v),
          ),
          Expanded(
            child: query.isEmpty
                ? _Browse(
                    onPickTag: _setQuery,
                    recent: _recent,
                    onPickRecent: _setQuery,
                    onClearRecent: _clearRecent,
                    filter: _applyFilters,
                  )
                : results.when(
                    loading: () => const Center(child: BrandLoader()),
                    error: (_, __) => const _Message('Não deu para buscar.'),
                    data: (raw) {
                      final list = _applyFilters(raw);
                      if (list.isNotEmpty) {
                        return _GridBody(
                          recipes: list,
                          label:
                              '${list.length} ${list.length == 1 ? 'RESULTADO' : 'RESULTADOS'}',
                          onOpen: () => _remember(query),
                        );
                      }
                      return _Message(
                        raw.isNotEmpty
                            ? 'Nenhum resultado com esses filtros.\nTente desligar um deles.'
                            : 'Nada encontrado para "$query".',
                        mascotMood: MascotMood.sad,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onBack,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              _buildSearchRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternBackground(AppColors colors) {
    return Positioned(
      top: -50,
      right: -40,
      child: SizedBox(
        width: 200,
        height: 200,
        child: TilePattern(
          motif: TileMotif.arco,
          background: colors.ink,
          patternColor: colors.inkPattern,
        ),
      ),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.screen,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              color: colors.onSaturated,
            ),
            Expanded(child: _buildSearchField(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: colors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: colors.onPaper,
              style: context.texts.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'Nome, notas ou tag',
                isCollapsed: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 18),
              color: colors.textMuted,
              tooltip: 'Limpar',
            ),
        ],
      ),
    );
  }
}

/// Filtros rápidos (favoritas, até 30 min) que valem pra busca e pra grade
/// de "todas as receitas".
class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.onlyFavorites,
    required this.onlyQuick,
    required this.onFavorites,
    required this.onQuick,
  });

  final bool onlyFavorites;
  final bool onlyQuick;
  final ValueChanged<bool> onFavorites;
  final ValueChanged<bool> onQuick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        0,
      ),
      child: Wrap(
        spacing: AppSpacing.xs,
        children: [
          FilterChip(
            label: const Text('Favoritas'),
            avatar: const Icon(Icons.favorite_border, size: 16),
            selected: onlyFavorites,
            onSelected: onFavorites,
          ),
          FilterChip(
            label: const Text('Até 30 min'),
            avatar: const Icon(Icons.timer_outlined, size: 16),
            selected: onlyQuick,
            onSelected: onQuick,
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.terms,
    required this.onPick,
    required this.onClear,
  });

  final List<String> terms;
  final ValueChanged<String> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('BUSCAS RECENTES', style: context.texts.labelSmall),
            ),
            InkWell(
              onTap: onClear,
              child: Text(
                'Limpar',
                style: context.texts.labelLarge?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final t in terms)
              Material(
                color: colors.paperSoft,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: InkWell(
                  onTap: () => onPick(t),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: colors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Text(t, style: context.texts.labelLarge),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Campo vazio: atalhos de tag no topo e a grade de todas as receitas embaixo —
/// a tela não fica em branco esperando você digitar.
class _Browse extends ConsumerWidget {
  const _Browse({
    required this.onPickTag,
    required this.recent,
    required this.onPickRecent,
    required this.onClearRecent,
    required this.filter,
  });

  final ValueChanged<String> onPickTag;
  final List<String> recent;
  final ValueChanged<String> onPickRecent;
  final VoidCallback onClearRecent;
  final List<Recipe> Function(List<Recipe>) filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(inUseTagsProvider).valueOrNull ?? const <Tag>[];
    final everything =
        ref.watch(allRecipesProvider).valueOrNull ?? const <Recipe>[];
    final all = filter(everything);

    if (tags.isEmpty && everything.isEmpty) {
      return const _Message(
        'Busque uma receita pelo nome,\npelas notas ou por uma tag.',
        mascotMood: MascotMood.idle,
      );
    }

    return _GridBody(
      recipes: all,
      label: 'TODAS AS RECEITAS · ${all.length}',
      leading: (tags.isEmpty && recent.isEmpty)
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recent.isNotEmpty)
                  _RecentRow(
                    terms: recent,
                    onPick: onPickRecent,
                    onClear: onClearRecent,
                  ),
                if (tags.isNotEmpty) _TagRow(tags: tags, onPick: onPickTag),
              ],
            ),
    );
  }
}

class _TagRow extends StatefulWidget {
  const _TagRow({required this.tags, required this.onPick});

  final List<Tag> tags;
  final ValueChanged<String> onPick;

  @override
  State<_TagRow> createState() => _TagRowState();
}

class _TagRowState extends State<_TagRow> {
  /// ~2 linhas de chip (padding 12 + texto ~17 por linha, + o `runSpacing`
  /// entre elas). Acima disso a lista de tags corria sem limite algum.
  static const _collapsedHeight = 90.0;

  /// Só compensa mostrar o botão quando dá pra imaginar que vai passar de
  /// 2 linhas — não dá pra medir o `Wrap` sem montar, então é estimativa.
  static const _toggleThreshold = 8;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showToggle = widget.tags.length > _toggleThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUSCAR POR TAG', style: context.texts.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: ClipRect(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: !showToggle || _expanded
                    ? double.infinity
                    : _collapsedHeight,
              ),
              child: Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in widget.tags)
                    Material(
                      color: colors.paperSoft,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: InkWell(
                        onTap: () => widget.onPick(t.name),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(t.name, style: context.texts.labelLarge),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showToggle) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Esconder' : 'Mostrar todas',
              style: context.texts.labelLarge?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// Rótulo caps + grade de `RecipeCard`, com um cabeçalho opcional (atalhos).
class _GridBody extends StatelessWidget {
  const _GridBody({
    required this.recipes,
    required this.label,
    this.leading,
    this.onOpen,
  });

  final List<Recipe> recipes;
  final String label;
  final Widget? leading;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.lg,
            AppSpacing.screen,
            AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) leading!,
                Text(label, style: context.texts.labelSmall),
              ],
            ),
          ),
        ),
        if (recipes.isEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xxl,
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
                  recipe: recipes[i],
                  onTap: () {
                    onOpen?.call();
                    context.push('/recipe/${recipes[i].id}', extra: recipes[i]);
                  },
                ),
                childCount: recipes.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.mascotMood});

  final String text;
  final MascotMood? mascotMood;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mascotMood != null) ...[
              AnimatedMascot(
                kind: MascotKind.pote,
                mood: mascotMood!,
                width: 110,
                semanticLabel:
                    mascotMood == MascotMood.sad ? 'Pote, triste' : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
