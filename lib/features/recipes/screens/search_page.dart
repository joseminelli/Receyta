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
import 'package:receyta/widgets/app_sheet.dart';
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

  Future<void> _removeRecent(String term) async {
    final next = [
      for (final r in _recent)
        if (r != term) r,
    ];
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
            filters: _HeaderFilters(
              query: query,
              onlyFavorites: _onlyFavorites,
              onlyQuick: _onlyQuick,
              onFavorites: (v) => setState(() => _onlyFavorites = v),
              onQuick: (v) => setState(() => _onlyQuick = v),
              onPickTag: _setQuery,
            ),
          ),
          Expanded(
            child: query.isEmpty
                ? _Browse(
                    recent: _recent,
                    onPickRecent: _setQuery,
                    onRemoveRecent: _removeRecent,
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
    required this.filters,
  });

  final Widget filters;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.sm,
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
          filters,
          const SizedBox(height: AppSpacing.md),
        ],
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

/// Filtros no próprio bloco escuro do cabeçalho: favoritas, até 30 min e um
/// seletor de tag. Desligado é só contorno; ligado inverte pra `paper`.
class _HeaderFilters extends ConsumerWidget {
  const _HeaderFilters({
    required this.query,
    required this.onlyFavorites,
    required this.onlyQuick,
    required this.onFavorites,
    required this.onQuick,
    required this.onPickTag,
  });

  final String query;
  final bool onlyFavorites;
  final bool onlyQuick;
  final ValueChanged<bool> onFavorites;
  final ValueChanged<bool> onQuick;
  final ValueChanged<String> onPickTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(inUseTagsProvider).valueOrNull ?? const <Tag>[];
    final activeTag = tags
        .map((t) => t.name)
        .where((n) => n.toLowerCase() == query.toLowerCase())
        .firstOrNull;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        children: [
          _OnInkPill(
            label: 'Favoritas',
            icon: onlyFavorites ? Icons.favorite : Icons.favorite_border,
            selected: onlyFavorites,
            onTap: () => onFavorites(!onlyFavorites),
          ),
          _OnInkPill(
            label: 'Até 30 min',
            icon: Icons.timer_outlined,
            selected: onlyQuick,
            onTap: () => onQuick(!onlyQuick),
          ),
          if (tags.isNotEmpty)
            _OnInkPill(
              label: activeTag ?? 'Tags',
              icon: Icons.sell_outlined,
              trailing: activeTag != null ? Icons.close : Icons.expand_more,
              selected: activeTag != null,
              onTap: () async {
                if (activeTag != null) return onPickTag('');
                final picked = await _pickTag(context, tags);
                if (picked != null) onPickTag(picked);
              },
            ),
        ],
      ),
    );
  }

  Future<String?> _pickTag(BuildContext context, List<Tag> tags) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        final colors = sheet.colors;
        return AppSheetFrame(
          title: 'Buscar por tag',
          subtitle: '${tags.length} em uso nas suas receitas',
          scrollable: true,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in tags)
                  Material(
                    color: colors.paperSoft,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: InkWell(
                      onTap: () => Navigator.of(sheet).pop(t.name),
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(t.name, style: sheet.texts.labelLarge),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnInkPill extends StatelessWidget {
  const _OnInkPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final IconData? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = selected ? colors.onPaper : colors.onSaturated;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? colors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected
                ? colors.paper
                : colors.onSaturated.withValues(alpha: 0.35),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: context.texts.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(trailing, size: 16, color: fg),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Buscas recentes como lista: toque refaz a busca, o X tira só aquela.
class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.terms,
    required this.onPick,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> terms;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  static const _visible = 4;

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
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: colors.textMuted,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Limpar'),
            ),
          ],
        ),
        for (final t in terms.take(_visible))
          InkWell(
            onTap: () => onPick(t),
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: colors.textMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(t),
                    icon: const Icon(Icons.close, size: 18),
                    color: colors.textMuted,
                    tooltip: 'Remover',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

/// Campo vazio: buscas recentes e a grade de todas as receitas — a tela não
/// fica em branco esperando você digitar.
class _Browse extends ConsumerWidget {
  const _Browse({
    required this.recent,
    required this.onPickRecent,
    required this.onRemoveRecent,
    required this.onClearRecent,
    required this.filter,
  });

  final List<String> recent;
  final ValueChanged<String> onPickRecent;
  final ValueChanged<String> onRemoveRecent;
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
      leading: recent.isEmpty
          ? null
          : _RecentList(
              terms: recent,
              onPick: onPickRecent,
              onRemove: onRemoveRecent,
              onClear: onClearRecent,
            ),
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
