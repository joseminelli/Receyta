import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/smart_collections.dart';
import 'package:receyta/features/recipes/controllers/smart_collections_view_model.dart';
import 'package:receyta/features/recipes/screens/smart_collection_style.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/header_scaffold.dart';

/// Todas as coleções inteligentes que têm receita hoje, em lista: título, a
/// regra e quantas receitas caem nela. Tocar abre a coleção.
class SmartCollectionsPage extends ConsumerWidget {
  const SmartCollectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(smartCollectionsProvider);

    return HeaderScaffold(
      title: 'Coleções',
      subtitle: 'Listas que se montam sozinhas',
      color: TileColor.lime,
      body: collections.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Nada por aqui ainda',
                  style: context.texts.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screen),
              itemCount: collections.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final entry = collections.entries.elementAt(i);
                return _Row(
                  collection: entry.key,
                  count: entry.value.length,
                  onTap: () => context.push('/collection/${entry.key.name}'),
                );
              },
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
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
      borderRadius: BorderRadius.circular(AppRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(color: colors.ink, shape: BoxShape.circle),
                child: Icon(collection.icon, size: 24, color: colors.lime),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      style: context.texts.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      collection.description,
                      style: context.texts.labelLarge
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text('$count', style: context.texts.displaySmall),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
