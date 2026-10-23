import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/features/mascot/widgets/animated_mascot.dart';
import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Camada do tour: escurece a tela, deixa um buraco redondo em volta do
/// elemento real que o passo explica, com um anel que pulsa, e põe um cartão
/// curto perto dele. Quando o passo é de outra aba, a casca do app troca de
/// aba antes e o destaque aparece no elemento de lá. Fica por cima de tudo na
/// casca; toques fora do cartão não passam.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  static const _tabSettle = Duration(milliseconds: 520);
  static const _retryEvery = Duration(milliseconds: 90);
  static const _retries = 10;

  /// Quanto o mascote sobe acima do cartão. Com o cartão abaixo do alvo, esse
  /// espaço entra na distância pra ele não cobrir o destaque.
  static const _mascotRise = 62.0;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  Rect? _target;
  int? _resolvedFor;
  int? _resolving;
  int _shownTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Acha onde o alvo do passo está agora (esperando a aba abrir e rolando a
  /// lista até ele, se for o caso), em coordenadas deste overlay.
  Future<void> _resolve() async {
    if (!mounted) return;
    final step = ref.read(tutorialStepProvider);
    if (step == null || _resolving == step) return;
    _resolving = step;

    final data = kTutorialSteps[step];
    if (data.tab != _shownTab) {
      await Future<void>.delayed(_tabSettle);
      _shownTab = data.tab;
    }

    Rect? rect;
    final target = data.target;
    if (target != null) {
      for (var i = 0; i < _retries && mounted; i++) {
        final targetContext =
            ref.read(tutorialTargetsProvider)[target]?.currentContext;
        if (targetContext != null && targetContext.mounted) {
          await Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 200),
            alignment: 0.3,
          );
          if (!mounted || !targetContext.mounted) return;
          final own = context.findRenderObject() as RenderBox?;
          final box = targetContext.findRenderObject() as RenderBox?;
          if (box != null && box.attached && own != null && own.attached) {
            rect = own.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
          }
          break;
        }
        await Future<void>.delayed(_retryEvery);
      }
    }
    if (!mounted || ref.read(tutorialStepProvider) != step) return;
    rect == null ? _pulse.stop() : _pulse.repeat();
    setState(() {
      _target = rect;
      _resolvedFor = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(tutorialStepProvider);
    if (step == null) return const SizedBox.shrink();
    if (_resolvedFor != step && _resolving != step) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
    final data = kTutorialSteps[step];
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final ready = _resolvedFor == step;
    final target = ready ? _target : null;
    final controller = ref.read(tutorialControllerProvider);
    final isLast = step == kTutorialSteps.length - 1;

    final hole = target == null
        ? Rect.fromCenter(center: size.center(Offset.zero), width: 0, height: 0)
        : target.inflate(8);

    final below = target != null && target.center.dy < size.height / 2;
    final card = AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [...previous, if (current != null) current],
      ),
      child: KeyedSubtree(
        key: ValueKey(step),
        child: _Card(
          data: data,
          step: step,
          isLast: isLast,
          onNext: controller.next,
          onSkip: controller.finish,
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: TweenAnimationBuilder<Rect?>(
              tween: RectTween(end: hole),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, rect, _) => AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  painter: _ScrimPainter(
                    hole: rect ?? hole,
                    color: colors.ink.withValues(alpha: 0.78),
                    ring: colors.lime,
                    pulse: target == null ? null : _pulse.value,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (ready)
          if (target == null)
            Center(child: _padded(card))
          else if (below)
            Positioned(
              left: 0,
              right: 0,
              top: target.bottom + 28 + _mascotRise,
              child: _padded(card),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: size.height - target.top + 28,
              child: _padded(card),
            ),
      ],
    );
  }

  Widget _padded(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
        child: child,
      );
}

class _ScrimPainter extends CustomPainter {
  const _ScrimPainter({
    required this.hole,
    required this.color,
    required this.ring,
    required this.pulse,
  });

  final Rect hole;
  final Color color;
  final Color ring;

  /// 0..1 em loop; nulo = sem anel (passo sem destaque).
  final double? pulse;

  static const _radius = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(_radius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      Paint()..color = color,
    );

    final t = pulse;
    if (t == null || hole.isEmpty) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(_radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring.withValues(alpha: 0.9),
    );
    final wave = Curves.easeOut.transform(t);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        hole.inflate(4 + 14 * wave),
        Radius.circular(_radius + 14 * wave),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring.withValues(alpha: 0.55 * (1 - wave)),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole ||
      old.color != color ||
      old.ring != ring ||
      old.pulse != pulse;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.data,
    required this.step,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  final TutorialStep data;
  final int step;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = kTutorialSteps.length;
    final card = Material(
      color: colors.paper,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProgressBar(step: step, total: total),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, size: 20, color: colors.lime),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(data.title, style: AppTextStyles.display(26)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(data.body, style: context.texts.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: const Text('Pular tour')),
                const Spacer(),
                PillButton(
                  label: isLast ? 'Concluir' : 'Próximo',
                  icon: isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  dense: true,
                  onPressed: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -60,
          right: AppSpacing.md,
          child: _TutorialMascot(step: step, isLast: isLast),
        ),
      ],
    );
  }
}

/// Barra segmentada: um trecho por passo, os já vistos e o atual cheios.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Passo ${step + 1} de $total',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= step ? colors.onPaper : colors.paperSoft,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${step + 1}/$total',
              style: context.texts.labelSmall?.copyWith(
                color: colors.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Guia do tour: os dois mascotes se alternam a cada passo (Cloche nos pares,
/// Pote nos ímpares). Entra quicando por trás do cartão e reage ao passo: acena
/// no primeiro, apresenta nos do meio e comemora no último.
class _TutorialMascot extends StatelessWidget {
  const _TutorialMascot({required this.step, required this.isLast});

  final int step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final kind = step.isEven ? MascotKind.cloche : MascotKind.pote;
    final greeting = step == 0
        ? MascotMood.waving
        : isLast
            ? MascotMood.celebrating
            : MascotMood.presenting;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) =>
          Transform.translate(offset: Offset(0, (1 - t) * 46), child: child),
      child: AnimatedMascot(
        kind: kind,
        width: kind == MascotKind.cloche ? 68 : 48,
        greeting: greeting,
        tappable: false,
      ),
    );
  }
}
