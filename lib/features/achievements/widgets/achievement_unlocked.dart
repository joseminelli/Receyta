import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:receyta/domain/engine/achievements.dart';
import 'package:receyta/features/achievements/widgets/achievement_emblem.dart';
import 'package:receyta/messenger.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Comemora uma conquista nova: um cartão no centro, por cima de tudo, com a
/// medalha estourando, anéis se abrindo e um brilho passando. Fecha sozinho,
/// ao tocar fora ou em "Fechar"; "Ver conquistas" leva à tela delas. O futuro
/// completa quando o cartão sai — pra enfileirar várias sem sobrepor.
Future<void> showAchievementUnlocked(Achievement achievement) {
  final overlay = rootNavigatorKey.currentState?.overlay;
  if (overlay == null) return Future.value();
  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _UnlockedMoment(
      achievement: achievement,
      onClosed: (openList) {
        entry.remove();
        if (!done.isCompleted) done.complete();
        if (openList) openAchievements();
      },
    ),
  );
  overlay.insert(entry);
  HapticFeedback.heavyImpact();
  return done.future;
}

class _UnlockedMoment extends StatefulWidget {
  const _UnlockedMoment({required this.achievement, required this.onClosed});

  final Achievement achievement;
  final void Function(bool openList) onClosed;

  @override
  State<_UnlockedMoment> createState() => _UnlockedMomentState();
}

class _UnlockedMomentState extends State<_UnlockedMoment>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _cardFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.18, curve: Curves.easeOut),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _cardScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.3, curve: Curves.easeOutBack),
    reverseCurve: Curves.easeIn,
  );
  late final Animation<double> _emblemScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.12, 0.5, curve: Curves.elasticOut),
  );
  late final Animation<double> _shine = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.45, 0.8, curve: Curves.easeInOut),
  );
  late final Animation<double> _rings = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.2, 1, curve: Curves.easeOut),
  );

  Timer? _auto;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _auto = Timer(const Duration(seconds: 8), () => _close(false));
  }

  Future<void> _close(bool openList) async {
    if (_closing) return;
    _closing = true;
    _auto?.cancel();
    await _intro.reverse();
    if (mounted) widget.onClosed(openList);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _intro.dispose();
    super.dispose();
  }

  Widget _buildEmblem(AppColors colors) {
    final a = widget.achievement;
    final accent = achievementAccent(colors, a.tone);
    return SizedBox(
      width: 168,
      height: 168,
      child: CustomPaint(
        painter: _RingsPainter(animation: _rings, color: accent),
        child: Center(
          child: ScaleTransition(
            scale: _emblemScale,
            child: AnimatedBuilder(
              animation: _shine,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                  stops: const [0.38, 0.5, 0.62],
                  transform: _Slide(_shine.value * 2 - 1),
                ).createShader(rect),
                child: child,
              ),
              child: AchievementEmblem(
                id: a.id,
                tone: a.tone,
                unlocked: true,
                size: 120,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final a = widget.achievement;
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.ink,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.inkSoft, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _buildEmblem(colors)),
          Text(
            'CONQUISTA DESBLOQUEADA',
            textAlign: TextAlign.center,
            style: texts.labelSmall?.copyWith(
              color: colors.lime,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: texts.displaySmall?.copyWith(color: colors.onInk),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            a.description,
            textAlign: TextAlign.center,
            style: texts.bodyMedium?.copyWith(
              color: colors.onInk.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Ver conquistas',
            variant: PillButtonVariant.accent,
            dense: true,
            onPressed: () => _close(true),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _close(false),
            child: Text(
              'Fechar',
              style: texts.labelLarge?.copyWith(
                color: colors.onInk.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(false),
              child: FadeTransition(
                opacity: _cardFade,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: FadeTransition(
                opacity: _cardFade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.88, end: 1).animate(_cardScale),
                  child: _buildCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.animation, required this.color})
      : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide * 0.36;
    for (var k = 0; k < 2; k++) {
      final p = (animation.value * 1.25 - k * 0.3).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      canvas.drawCircle(
        center,
        base + (size.shortestSide / 2 - base) * Curves.easeOut.transform(p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: (1 - p) * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}
