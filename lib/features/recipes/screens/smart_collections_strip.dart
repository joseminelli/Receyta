import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

extension SmartCollectionStyle on SmartCollection {
  IconData get icon => switch (this) {
        SmartCollection.quick => Icons.bolt_rounded,
        SmartCollection.neverCooked => Icons.restaurant_menu_rounded,
        SmartCollection.mostCooked => Icons.repeat_rounded,
        SmartCollection.forgotten => Icons.hourglass_empty_rounded,
        SmartCollection.favorites => Icons.favorite_rounded,
      };

  TileColor get color => switch (this) {
        SmartCollection.quick => TileColor.lime,
        SmartCollection.neverCooked => TileColor.violet,
        SmartCollection.mostCooked => TileColor.coral,
        SmartCollection.forgotten => TileColor.mar,
        SmartCollection.favorites => TileColor.framboesa,
      };
}

/// A faixa começa recolhida a cada abertura do app (só o cabeçalho), pra não
/// empurrar os recentes pra baixo; tocar no cabeçalho abre e fecha.
final collectionsExpandedProvider = StateProvider<bool>((ref) => false);

/// Faixa "Coleções" da home: atalhos para listas montadas por regra (rápidas,
/// nunca cozinhei...). Visualmente de outra família que as pastas — pílulas
/// baixas num fundo neutro, com o medalhão escuro e o ícone —, porque não são
/// lugares onde se guarda receita, e sim filtros que se atualizam sozinhos.
/// Some quando nenhuma regra tem receita.
class SmartCollectionsStrip extends ConsumerWidget {
  const SmartCollectionsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(smartCollectionsProvider);
    if (collections.isEmpty) return const SizedBox.shrink();
    final expanded = ref.watch(collectionsExpandedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref, expanded, collections.length),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: expanded
              ? SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screen,
                    ),
                    itemCount: collections.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final entry = collections.entries.elementAt(i);
                      return _Pill(
                        collection: entry.key,
                        count: entry.value.length,
                        onTap: () =>
                            context.push('/collection/${entry.key.name}'),
                      );
                    },
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// Linha em pílula (e não só um título), com a seta num círculo e o verbo
  /// "Mostrar"/"Ocultar": deixa claro que dá pra abrir e fechar.
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    bool expanded,
    int count,
  ) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.lg,
        AppSpacing.screen,
        expanded ? AppSpacing.sm : 0,
      ),
      child: Material(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              ref.read(collectionsExpandedProvider.notifier).state = !expanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, size: 20, color: colors.ink),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Coleções',
                  style: context.texts.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$count',
                  style: context.texts.labelLarge
                      ?.copyWith(color: colors.textMuted),
                ),
                const Spacer(),
                Text(
                  expanded ? 'Ocultar' : 'Mostrar',
                  style: context.texts.labelLarge
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 22,
                      color: colors.lime,
                      semanticLabel:
                          expanded ? 'Ocultar coleções' : 'Mostrar coleções',
                    ),
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.collection,
    required this.count,
    required this.onTap,
  });

  final SmartCollection collection;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.paperSoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(collection.icon, size: 22, color: colors.lime),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    collection.title,
                    style: context.texts.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.1),
                  ),
                  Text(
                    '$count ${count == 1 ? 'receita' : 'receitas'}',
                    style: context.texts.labelLarge
                        ?.copyWith(color: colors.textMuted, height: 1.2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
