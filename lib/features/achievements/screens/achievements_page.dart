import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/core/tile_style.dart';
import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/achievements/controllers/achievements_view_model.dart';
import 'package:receyta/features/achievements/widgets/achievement_emblem.dart';
import 'package:receyta/features/achievements/widgets/achievement_trophy.dart';
import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/header_scaffold.dart';
import 'package:receyta/widgets/skeleton.dart';

/// Conquistas: um painel de progresso, "Suas conquistas" (medalhas ganhas, em
/// prateleira que expande numa grade com detalhes e o caminho até o próximo
/// nível) e "A liberar" (as que ainda não começaram). As conquistas com níveis
/// trocam o aro da medalha — bronze, prata e ouro. Tudo deriva das contagens
/// do app.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final list = achievements.valueOrNull;
    final done = list?.where((a) => a.unlocked).length;

    return HeaderScaffold(
      title: 'Conquistas',
      subtitle: list == null ? null : '$done de ${list.length}',
      color: TileColor.lime,
      body: achievements.when(
        loading: () => const _PageSkeleton(),
        error: (_, __) => _buildError(context),
        data: _buildContent,
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

  Widget _buildContent(List<Achievement> items) {
    final unlocked = [
      for (final a in items)
        if (a.unlocked) a
    ];
    final notStarted = [
      for (final a in items)
        if (!a.unlocked) a
    ]..sort((a, b) => b.progress.compareTo(a.progress));
    final allMaxed = items.every((a) => a.maxed);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.md,
        AppSpacing.screen,
        AppSpacing.xl,
      ),
      children: [
        _buildHero(items),
        const SizedBox(height: AppSpacing.lg),
        _buildUnlockedSection(unlocked),
        if (allMaxed) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildTrophy(items.length),
        ] else if (notStarted.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildLockedSection(notStarted),
        ],
      ],
    );
  }

  Widget _buildHero(List<Achievement> items) {
    final colors = context.colors;
    final texts = context.texts;
    final earned = items.fold<int>(0, (sum, a) => sum + a.level);
    final total = items.fold<int>(0, (sum, a) => sum + a.tiers.length);
    final pending = [
      for (final a in items)
        if (!a.maxed) a
    ]..sort((a, b) => b.progress.compareTo(a.progress));
    final next = pending.isEmpty ? null : pending.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CustomPaint(
              painter: _RingPainter(
                progress: total == 0 ? 0 : earned / total,
                color: colors.lime,
                track: colors.inkSoft,
              ),
              child: Center(
                child: Text(
                  '$earned/$total',
                  style: texts.titleMedium?.copyWith(
                    color: colors.onInk,
                    fontWeight: FontWeight.w800,
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
                Text(
                  next == null ? 'Tudo conquistado!' : 'Próxima conquista',
                  style: texts.labelMedium?.copyWith(
                    color: colors.onInk.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next == null
                      ? 'Você completou a coleção.'
                      : (next.nextTitle ?? next.title),
                  style: texts.titleLarge?.copyWith(
                    color: colors.onInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    next.nextTarget == 1
                        ? (next.nextDescription ?? next.description)
                        : '${next.shownCurrent} de ${next.nextTarget}',
                    style: texts.bodyMedium?.copyWith(
                      color: colors.lime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, {Widget? action}) {
    final colors = context.colors;
    final texts = context.texts;
    return Row(
      children: [
        Text(
          title,
          style: texts.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$count',
          style: texts.titleMedium?.copyWith(color: colors.textMuted),
        ),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildExpandToggle() {
    final colors = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _expanded ? 'Recolher' : 'Ver detalhes',
              style: context.texts.labelLarge?.copyWith(
                color: colors.onPaper,
                fontWeight: FontWeight.w700,
              ),
            ),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.onPaper,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedSection(List<Achievement> unlocked) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Suas conquistas',
          unlocked.length,
          action: unlocked.length > 3 ? _buildExpandToggle() : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (unlocked.isEmpty)
          Text(
            'Nenhuma ainda. A primeira está logo abaixo.',
            style: context.texts.bodyMedium?.copyWith(color: colors.textMuted),
          )
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _expanded
                  ? _buildUnlockedGrid(unlocked)
                  : _buildUnlockedShelf(unlocked),
            ),
          ),
      ],
    );
  }

  Widget _buildUnlockedShelf(List<Achievement> unlocked) {
    final colors = context.colors;
    final texts = context.texts;
    return SizedBox(
      key: const ValueKey('shelf'),
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unlocked.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final a = unlocked[i];
          return SizedBox(
            width: 84,
            child: Column(
              children: [
                AchievementEmblem(id: a.id, tone: a.tone, medal: a.medal),
                const SizedBox(height: 6),
                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: texts.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (a.hasTiers)
                  Text(
                    medalName(a.medal),
                    style: texts.labelSmall?.copyWith(color: colors.textMuted),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnlockedGrid(List<Achievement> unlocked) {
    return GridView.builder(
      key: const ValueKey('grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 232,
      ),
      itemCount: unlocked.length,
      itemBuilder: (context, i) => _buildUnlockedCard(unlocked[i]),
    );
  }

  Widget _buildUnlockedCard(Achievement a) {
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.paperSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        children: [
          AchievementEmblem(
            id: a.id,
            tone: a.tone,
            medal: a.medal,
            size: 84,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            a.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: texts.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Text(
              a.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: texts.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
          a.maxed ? _buildDoneBadge(a) : _buildNextLevel(a),
        ],
      ),
    );
  }

  Widget _buildDoneBadge(Achievement a) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 16, color: colors.onPaper),
        const SizedBox(width: 4),
        Text(
          a.hasTiers ? 'Nível máximo' : 'Conquistada',
          style: context.texts.labelMedium?.copyWith(
            color: colors.onPaper,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Caminho até o próximo nível: barra e "12/25", com o nome do nível.
  Widget _buildNextLevel(Achievement a) {
    final colors = context.colors;
    final texts = context.texts;
    final nextMedal =
        a.hasTiers ? MedalTier.values[a.level + 1] : MedalTier.single;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (a.hasTiers)
          Text(
            'Próximo: ${medalName(nextMedal)}',
            style: texts.labelSmall?.copyWith(color: colors.textMuted),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: LinearProgressIndicator(
                  value: a.progress,
                  minHeight: 6,
                  backgroundColor: colors.paper,
                  color: colors.onPaper,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '${a.shownCurrent}/${a.nextTarget}',
              style: texts.labelMedium?.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrophy(int total) {
    final colors = context.colors;
    final texts = context.texts;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          AchievementTrophy(color: colors.lime, starColor: colors.ink),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Coleção completa',
            textAlign: TextAlign.center,
            style: texts.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Você levou as $total conquistas ao nível máximo. '
            'Mestre da cozinha!',
            textAlign: TextAlign.center,
            style: texts.bodyMedium?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedSection(List<Achievement> locked) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('A liberar', locked.length),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < locked.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1.5, color: colors.paperSoft),
          _buildLockedRow(locked[i]),
        ],
      ],
    );
  }

  Widget _buildLockedRow(Achievement a) {
    final colors = context.colors;
    final texts = context.texts;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          AchievementEmblem(
            id: a.id,
            tone: a.tone,
            medal: MedalTier.none,
            size: 60,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  a.description,
                  style: texts.bodySmall?.copyWith(color: colors.textMuted),
                ),
                if (a.nextTarget != null && a.nextTarget! > 1) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          child: LinearProgressIndicator(
                            value: a.progress,
                            minHeight: 6,
                            backgroundColor: colors.paperSoft,
                            color: colors.onPaper,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${a.shownCurrent}/${a.nextTarget}',
                        style: texts.labelMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 116, radius: AppRadii.lg),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(width: 150, height: 24, radius: AppRadii.pill),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 96, radius: AppRadii.md),
            SizedBox(height: AppSpacing.lg),
            SkeletonBox(width: 110, height: 24, radius: AppRadii.pill),
            SizedBox(height: AppSpacing.sm),
            SkeletonBox(height: 72, radius: AppRadii.md),
          ],
        ),
      ),
    );
  }
}
