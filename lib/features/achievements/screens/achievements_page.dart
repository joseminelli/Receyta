import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/achievements/controllers/achievements_view_model.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/skeleton.dart';

/// Conquistas: uma grade de medalhões, coloridos quando já ganhos e apagados
/// (com a barra de progresso) enquanto faltam. Tudo deriva das contagens do
/// app — não há nada a "resgatar".
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final list = achievements.valueOrNull;
    final done = list?.where((a) => a.unlocked).length;

    return HeaderScaffold(
      title: 'Conquistas',
      subtitle: list == null ? null : '$done de ${list.length}',
      color: TileColor.lime,
      body: achievements.when(
        loading: () => const _GridSkeleton(),
        error: (_, __) => _buildError(context),
        data: (items) => _buildGrid(items),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedMascot(
              kind: MascotKind.pote,
              mood: MascotMood.sad,
              width: 120,
              semanticLabel: 'Pote, triste',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Não deu para carregar as conquistas',
              style: context.texts.displaySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<Achievement> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.screen),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 214,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _AchievementCard(achievement: items[i]),
    );
  }
}

IconData _iconFor(AchievementId id) => switch (id) {
      AchievementId.firstRecipe => Icons.menu_book_rounded,
      AchievementId.tenRecipes => Icons.collections_bookmark_rounded,
      AchievementId.twentyFiveRecipes => Icons.local_library_rounded,
      AchievementId.firstFavorite => Icons.favorite_rounded,
      AchievementId.firstCooked => Icons.soup_kitchen_rounded,
      AchievementId.tenCooked => Icons.restaurant_rounded,
      AchievementId.fiftyCooked => Icons.workspace_premium_rounded,
      AchievementId.firstMeal => Icons.event_available_rounded,
      AchievementId.plannedWeek => Icons.calendar_month_rounded,
      AchievementId.firstShoppingList => Icons.shopping_basket_rounded,
      AchievementId.house => Icons.home_rounded,
    };

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  Color _accent(AppColors colors) => switch (achievement.tone) {
        AchievementTone.lime => colors.lime,
        AchievementTone.coral => colors.coral,
        AchievementTone.violet => colors.violet,
      };

  Color _onAccent(AppColors colors) => switch (achievement.tone) {
        AchievementTone.lime => colors.ink,
        AchievementTone.coral || AchievementTone.violet => colors.onSaturated,
      };

  Widget _medallion(AppColors colors) {
    final unlocked = achievement.unlocked;
    return Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: unlocked ? _accent(colors) : colors.paper,
        shape: BoxShape.circle,
      ),
      child: Icon(
        unlocked ? _iconFor(achievement.id) : Icons.lock_outline_rounded,
        size: 30,
        color: unlocked ? _onAccent(colors) : colors.textMuted,
      ),
    );
  }

  Widget _status(BuildContext context, AppColors colors) {
    final texts = context.texts;
    if (achievement.unlocked) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: colors.onPaper),
          const SizedBox(width: 4),
          Text(
            'Conquistada',
            style: texts.labelMedium?.copyWith(
              color: colors.onPaper,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    if (achievement.target == 1) {
      return Text(
        'Ainda não',
        style: texts.labelMedium?.copyWith(color: colors.textMuted),
      );
    }
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              value: achievement.progress,
              minHeight: 8,
              backgroundColor: colors.paper,
              color: _accent(colors),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '${achievement.current}/${achievement.target}',
          style: texts.labelMedium?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final unlocked = achievement.unlocked;

    return Semantics(
      label: '${achievement.title}. ${achievement.description} '
          '${unlocked ? 'Conquistada.' : '${achievement.current} de ${achievement.target}.'}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.paperSoft,
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Column(
            children: [
              _medallion(colors),
              const SizedBox(height: AppSpacing.xs),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: texts.titleSmall?.copyWith(
                  color: unlocked ? colors.onPaper : colors.textBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: texts.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ),
              _status(context, colors),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screen),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 220,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 214,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const SkeletonBox(radius: AppRadii.md),
      ),
    );
  }
}
