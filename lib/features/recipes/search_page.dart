import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/domain/models/tag.dart';
import 'package:receyta/features/recipes/recipes_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
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
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
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
          ),
          Expanded(
            child: query.isEmpty
                ? _Browse(onPickTag: _setQuery)
                : results.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const _Message('Não deu para buscar.'),
                    data: (list) => list.isEmpty
                        ? _Message('Nada encontrado para "$query".')
                        : _GridBody(
                            recipes: list,
                            label:
                                '${list.length} ${list.length == 1 ? 'RESULTADO' : 'RESULTADOS'}',
                          ),
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
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

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
              Positioned(
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
              ),
              SafeArea(
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
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colors.paper,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  size: 20, color: colors.textMuted),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  onChanged: onChanged,
                                  textInputAction: TextInputAction.search,
                                  cursorColor: colors.ink,
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
                        ),
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
}

/// Campo vazio: atalhos de tag no topo e a grade de todas as receitas embaixo —
/// a tela não fica em branco esperando você digitar.
class _Browse extends ConsumerWidget {
  const _Browse({required this.onPickTag});

  final ValueChanged<String> onPickTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(inUseTagsProvider).valueOrNull ?? const <Tag>[];
    final all = ref.watch(allRecipesProvider).valueOrNull ?? const <Recipe>[];

    if (tags.isEmpty && all.isEmpty) {
      return const _Message(
        'Busque uma receita pelo nome,\npelas notas ou por uma tag.',
        icon: Icons.search,
      );
    }

    return _GridBody(
      recipes: all,
      label: 'TODAS AS RECEITAS',
      leading: tags.isEmpty ? null : _TagRow(tags: tags, onPick: onPickTag),
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
  });

  final List<Recipe> recipes;
  final String label;
  final Widget? leading;

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
                  onTap: () => context.push('/recipe/${recipes[i].id}'),
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
  const _Message(this.text, {this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 40, color: colors.textMuted),
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
