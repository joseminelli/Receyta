import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Qual gesto a dica ensina (decide a mini animação).
enum GestureHintKind {
  /// Deslizar uma linha pros lados revelando ações.
  swipeRow,

  /// Deslizar entre páginas (dias, meses).
  swipePages,

  /// Segurar e arrastar até uma pasta ou a lixeira.
  dragToTarget,

  /// Segurar e arrastar pra trocar de lugar.
  reorder,
}

/// Dica única de um gesto escondido: um mini cartão anima o gesto ao lado do
/// texto. Fica até o usuário dispensar; a escolha é guardada por [hintId].
class GestureHint extends StatefulWidget {
  const GestureHint({
    super.key,
    required this.hintId,
    required this.kind,
    required this.title,
    required this.message,
    this.startIcon = Icons.check,
    this.endIcon = Icons.delete_outline,
    this.after = const [],
  });

  final String hintId;

  /// Dicas que precisam já ter sido dispensadas antes desta aparecer, pra
  /// uma tela nunca mostrar várias de uma vez.
  final List<String> after;
  final GestureHintKind kind;
  final String title;
  final String message;

  /// [GestureHintKind.swipeRow]: ação ao deslizar pra direita.
  /// [GestureHintKind.dragToTarget]: primeiro destino.
  final IconData startIcon;

  /// [GestureHintKind.swipeRow]: ação ao deslizar pra esquerda.
  /// [GestureHintKind.dragToTarget]: segundo destino.
  final IconData endIcon;

  @override
  State<GestureHint> createState() => _GestureHintState();
}

class _GestureHintState extends State<GestureHint>
    with SingleTickerProviderStateMixin {
  static const _demoSize = Size(76, 48);

  bool _visible = false;

  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.kind == GestureHintKind.dragToTarget ? 4800 : 3200,
    ),
  );

  static final _slide = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 8),
    _ease(0, 1, 20),
    TweenSequenceItem(tween: ConstantTween(1), weight: 10),
    _ease(1, 0, 16),
    _ease(0, -1, 20),
    TweenSequenceItem(tween: ConstantTween(-1), weight: 10),
    _ease(-1, 0, 16),
  ]);

  static TweenSequenceItem<double> _ease(double a, double b, double weight) =>
      TweenSequenceItem(
        tween: Tween(begin: a, end: b)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: weight,
      );

  static String _keyFor(String id) => 'swipe_hint_seen_v2_$id';

  String get _key => _keyFor(widget.hintId);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _demo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      final waiting =
          widget.after.any((id) => !(prefs.getBool(_keyFor(id)) ?? false));
      if (!mounted || seen || waiting) return;
      setState(() => _visible = true);
      if (!MediaQuery.disableAnimationsOf(context)) _demo.repeat();
    } catch (_) {}
  }

  Future<void> _dismiss() async {
    _demo.stop();
    setState(() => _visible = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {}
  }

  Widget _buildDemo(AppColors colors) {
    final body = switch (widget.kind) {
      GestureHintKind.swipeRow => _swipeRowDemo(colors),
      GestureHintKind.swipePages => _swipePagesDemo(colors),
      GestureHintKind.dragToTarget => _dragToTargetDemo(colors),
      GestureHintKind.reorder => _reorderDemo(colors),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: _demoSize.width,
        height: _demoSize.height,
        child: ColoredBox(color: colors.inkSoft, child: body),
      ),
    );
  }

  Widget _card(AppColors colors, {double width = 44, double height = 30}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Container(
        width: width / 2,
        height: 4,
        decoration: BoxDecoration(
          color: colors.textMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _swipeRowDemo(AppColors colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(widget.startIcon, size: 16, color: colors.lime),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(widget.endIcon, size: 16, color: colors.danger),
          ),
        ),
        AnimatedBuilder(
          animation: _demo,
          builder: (_, child) => Transform.translate(
            offset: Offset(_slide.evaluate(_demo) * 20, 0),
            child: child,
          ),
          child: _card(colors),
        ),
      ],
    );
  }

  Widget _swipePagesDemo(AppColors colors) {
    const pitch = 46.0;
    return AnimatedBuilder(
      animation: _demo,
      builder: (_, __) {
        final shift = -_slide.evaluate(_demo) * pitch;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (final slot in const [-1, 0, 1])
              Transform.translate(
                offset: Offset(slot * pitch + shift, 0),
                child: Opacity(
                  opacity: (1 - (slot * pitch + shift).abs() / (pitch * 1.4))
                      .clamp(0.25, 1.0),
                  child: _card(colors, width: 38, height: 30),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _dragToTargetDemo(AppColors colors) {
    return AnimatedBuilder(
      animation: _demo,
      builder: (_, __) {
        final t = _demo.value;
        final first = t < 0.5;
        final local = first ? t * 2 : (t - 0.5) * 2;
        final lift = Curves.easeOut.transform((local / 0.15).clamp(0.0, 1.0));
        final move = Curves.easeInOutCubic
            .transform(((local - 0.2) / 0.45).clamp(0.0, 1.0));
        final land = ((local - 0.65) / 0.1).clamp(0.0, 1.0);
        final fade = 1 - ((local - 0.88) / 0.12).clamp(0.0, 1.0);
        final accent = first ? colors.lime : colors.danger;
        final icon = first ? widget.startIcon : widget.endIcon;

        return Stack(
          children: [
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.scale(
                  scale: 1 + 0.25 * math.sin(land * math.pi),
                  child: Icon(icon, size: 22, color: accent),
                ),
              ),
            ),
            Positioned(
              left: 8 + move * 22,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: fade,
                  child: Transform.scale(
                    scale: 1 + 0.15 * lift - 0.35 * land,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35 * lift),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _card(colors, width: 34, height: 26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _reorderDemo(AppColors colors) {
    return AnimatedBuilder(
      animation: _demo,
      builder: (_, __) {
        final t = _demo.value;
        final lift = Curves.easeOut.transform((t / 0.12).clamp(0.0, 1.0));
        final move =
            Curves.easeInOutCubic.transform(((t - 0.2) / 0.4).clamp(0.0, 1.0));
        final drop = 1 - ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        final back = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
        final pos = (move * drop) + 0 * back;
        const gap = 22.0;
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, gap * 0.5 - pos * gap),
              child: Opacity(
                opacity: 0.6,
                child: _card(colors, width: 52, height: 16),
              ),
            ),
            Transform.translate(
              offset: Offset(0, -gap * 0.5 + pos * gap),
              child: Transform.scale(
                scale: 1 + 0.12 * lift * drop,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.35 * lift * drop),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _card(colors, width: 52, height: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: !_visible
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.ink,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    _buildDemo(colors),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: texts.titleSmall?.copyWith(
                              color: colors.onInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: texts.bodySmall?.copyWith(
                              color: colors.onInk.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                'Entendi',
                                style: texts.labelLarge?.copyWith(
                                  color: colors.lime,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
