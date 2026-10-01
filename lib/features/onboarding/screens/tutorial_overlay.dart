import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receyta/features/onboarding/controllers/tutorial.dart';
import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/pill_button.dart';

/// Camada do tour: escurece a tela, deixa um buraco redondo em volta do
/// elemento real que o passo explica e põe um cartão curto perto dele.
/// Fica por cima de tudo na casca do app; toques fora do cartão não passam.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key});

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  Rect? _target;
  int? _resolvedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  /// Acha onde o alvo do passo está agora (e rola a lista até ele, se for o
  /// caso), em coordenadas deste overlay.
  Future<void> _resolve() async {
    if (!mounted) return;
    final step = ref.read(tutorialStepProvider);
    if (step == null) return;
    final target = kTutorialSteps[step].target;
    Rect? rect;
    if (target != null) {
      final targetContext =
          ref.read(tutorialTargetsProvider)[target]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        final own = context.findRenderObject() as RenderBox?;
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 200),
          alignment: 0.3,
        );
        if (!mounted || !targetContext.mounted) return;
        final box = targetContext.findRenderObject() as RenderBox?;
        if (box != null && box.attached && own != null && own.attached) {
          rect = own.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
        }
      }
    }
    setState(() {
      _target = rect;
      _resolvedFor = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(tutorialStepProvider);
    if (step == null) return const SizedBox.shrink();
    if (_resolvedFor != step) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
    final data = kTutorialSteps[step];
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final target = _resolvedFor == step ? _target : null;
    final controller = ref.read(tutorialControllerProvider);
    final isLast = step == kTutorialSteps.length - 1;

    final hole = target == null
        ? Rect.fromCenter(center: size.center(Offset.zero), width: 0, height: 0)
        : target.inflate(8);

    final below = target != null && target.center.dy < size.height / 2;
    final card = _Card(
      data: data,
      step: step,
      isLast: isLast,
      onNext: controller.next,
      onSkip: controller.finish,
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
              builder: (context, rect, _) => CustomPaint(
                painter: _ScrimPainter(
                  hole: rect ?? hole,
                  color: colors.ink.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ),
        if (target == null)
          Center(child: _padded(card))
        else if (below)
          Positioned(
            left: 0,
            right: 0,
            top: target.bottom + 24,
            child: _padded(card),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: size.height - target.top + 24,
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
  const _ScrimPainter({required this.hole, required this.color});

  final Rect hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(22)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cut),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.color != color;
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
    return Material(
      color: colors.paper,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step + 1} DE ${kTutorialSteps.length}',
              style:
                  context.texts.labelSmall?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(data.title, style: AppTextStyles.display(26)),
            const SizedBox(height: AppSpacing.xs),
            Text(data.body, style: context.texts.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: const Text('Pular tour')),
                const Spacer(),
                PillButton(
                  label: isLast ? 'Concluir' : 'Próximo',
                  dense: true,
                  onPressed: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
