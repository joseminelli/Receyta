import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/domain/models/recipe.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/action_menu_button.dart';
import 'package:receyta/widgets/recipe_card.dart';
import 'package:receyta/widgets/recipe_cover.dart';
import 'package:receyta/widgets/tile_appearance.dart';

/// Como ordenar os resultados da busca. [relevance] mantém a ordem do FTS.
enum SearchSort {
  relevance('Relevância', Icons.auto_awesome_outlined),
  recent('Mais recentes', Icons.schedule),
  fastest('Mais rápidas', Icons.timer_outlined),
  alphabetical('A–Z', Icons.sort_by_alpha);

  const SearchSort(this.label, this.icon);

  final String label;
  final IconData icon;

  List<Recipe> apply(List<Recipe> list) {
    if (this == relevance) return list;
    final sorted = [...list];
    switch (this) {
      case relevance:
        break;
      case recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case fastest:
        sorted.sort((a, b) {
          final ta = _totalMinutes(a);
          final tb = _totalMinutes(b);
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return ta.compareTo(tb);
        });
      case alphabetical:
        sorted.sort(
          (a, b) => _fold(a.name).compareTo(_fold(b.name)),
        );
    }
    return sorted;
  }
}

int? _totalMinutes(Recipe r) {
  final total = (r.prepMinutes ?? 0) + (r.cookMinutes ?? 0);
  return total > 0 ? total : null;
}

const _from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
const _to = 'aaaaaeeeeiiiiooooouuuucn';

/// Minúsculas e sem acento, caractere a caractere (o tamanho não muda, então
/// os índices valem também no texto original).
String _fold(String text) {
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = _from.indexOf(ch);
    out.write(i >= 0 ? _to[i] : ch);
  }
  return out.toString();
}

List<String> _tokens(String query) => [
      for (final t in _fold(query).split(RegExp(r'\s+')))
        if (t.isNotEmpty) t,
    ];

/// Trecho das notas/sobre onde o termo apareceu, quando o nome não basta pra
/// explicar por que a receita casou.
String? _matchHint(Recipe r, List<String> tokens) {
  if (tokens.isEmpty) return null;
  final name = _fold(r.name);
  if (tokens.any(name.contains)) return null;

  final sources = [
    ('Notas', r.notes),
    ('Sobre', r.about),
  ];
  for (final (label, raw) in sources) {
    if (raw == null || raw.trim().isEmpty) continue;
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final folded = _fold(text);
    for (final t in tokens) {
      final at = folded.indexOf(t);
      if (at < 0) continue;
      final start = (at - 24).clamp(0, text.length);
      final end = (at + t.length + 40).clamp(0, text.length);
      final head = start > 0 ? '…' : '';
      final tail = end < text.length ? '…' : '';
      return '$label: $head${text.substring(start, end)}$tail';
    }
  }
  return null;
}

/// [text] com os trechos que casam com [tokens] em negrito.
List<TextSpan> _highlight(String text, List<String> tokens, TextStyle? bold) {
  if (tokens.isEmpty) return [TextSpan(text: text)];
  final folded = _fold(text);
  final marked = List<bool>.filled(text.length, false);
  for (final t in tokens) {
    var from = 0;
    while (true) {
      final at = folded.indexOf(t, from);
      if (at < 0) break;
      for (var i = at; i < at + t.length && i < marked.length; i++) {
        marked[i] = true;
      }
      from = at + t.length;
    }
  }
  final spans = <TextSpan>[];
  var i = 0;
  while (i < text.length) {
    final on = marked[i];
    var j = i;
    while (j < text.length && marked[j] == on) {
      j++;
    }
    spans.add(
      TextSpan(text: text.substring(i, j), style: on ? bold : null),
    );
    i = j;
  }
  return spans;
}

/// Resultados da busca: barra com contador, ordenação e alternador
/// lista/grade, e o corpo no formato escolhido.
class SearchResults extends StatelessWidget {
  const SearchResults({
    super.key,
    required this.recipes,
    required this.query,
    required this.asList,
    required this.sort,
    required this.onToggleView,
    required this.onSort,
    required this.onOpen,
  });

  final List<Recipe> recipes;
  final String query;
  final bool asList;
  final SearchSort sort;
  final VoidCallback onToggleView;
  final ValueChanged<SearchSort> onSort;
  final VoidCallback onOpen;

  void _open(BuildContext context, Recipe recipe) {
    onOpen();
    context.push('/recipe/${recipe.id}', extra: recipe);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sort.apply(recipes);
    final tokens = _tokens(query);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildBar(context)),
        if (asList)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xs,
              AppSpacing.screen,
              AppSpacing.xxl,
            ),
            sliver: SliverList.separated(
              itemCount: sorted.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, i) => _ResultTile(
                recipe: sorted[i],
                tokens: tokens,
                onTap: () => _open(context, sorted[i]),
              ),
            ),
          )
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
                  recipe: sorted[i],
                  onTap: () => _open(context, sorted[i]),
                ),
                childCount: sorted.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    final colors = context.colors;
    final count = recipes.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'RESULTADO' : 'RESULTADOS'}',
              style: context.texts.labelSmall,
            ),
          ),
          ActionMenuButton(
            tooltip: 'Ordenar',
            items: [
              for (final option in SearchSort.values)
                ActionMenuItem(
                  icon: option.icon,
                  label: option.label,
                  selected: option == sort,
                  onTap: () => onSort(option),
                ),
            ],
            triggerBuilder: (context, open) => Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert, size: 18, color: colors.textMuted),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    sort.label,
                    style: context.texts.labelLarge?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleView,
            tooltip: asList ? 'Ver em grade' : 'Ver em lista',
            icon: Icon(
              asList ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
              size: 20,
            ),
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.recipe,
    required this.tokens,
    required this.onTap,
  });

  final Recipe recipe;
  final List<String> tokens;
  final VoidCallback onTap;

  static const _thumb = 64.0;

  String? get _meta {
    final parts = [
      if (_totalMinutes(recipe) case final m?) '$m min',
      if (recipe.servings case final s?) '$s ${s == 1 ? 'porção' : 'porções'}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final tile = resolveTileAppearance(
      colors,
      color: recipe.tileColor,
      motif: recipe.tileMotif,
      seedId: recipe.id,
    );
    final meta = _meta;
    final hint = _matchHint(recipe, tokens);
    final nameStyle = texts.bodyLarge?.copyWith(fontWeight: FontWeight.w600);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Material(
        color: colors.paperSoft,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm - 4),
                  child: SizedBox(
                    width: _thumb,
                    height: _thumb,
                    child: ColoredBox(
                      color: tile.background,
                      child: Hero(
                        tag: recipeTileHeroTag(recipe.id),
                        flightShuttleBuilder:
                            recipeTileHeroFlightShuttleBuilder,
                        child: RecipeCover(
                          recipe: recipe,
                          tile: tile,
                          cacheWidth: 200,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: nameStyle,
                          children: _highlight(
                            recipe.name,
                            tokens,
                            nameStyle?.copyWith(
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (meta != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            meta,
                            style: texts.labelLarge
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ),
                      if (hint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text.rich(
                            TextSpan(
                              style: texts.bodyMedium
                                  ?.copyWith(color: colors.textMuted),
                              children: _highlight(
                                hint,
                                tokens,
                                texts.bodyMedium?.copyWith(
                                  color: colors.onPaper,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (recipe.isFavorite)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
                    child: Icon(
                      Icons.favorite,
                      size: 18,
                      color: colors.coral,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
