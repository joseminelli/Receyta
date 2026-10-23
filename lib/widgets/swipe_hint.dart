import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Dica única de que as linhas da lista respondem a deslizar. Um mini cartão
/// anima o gesto pros dois lados, revelando as ações, ao lado do texto. Fica
/// até o usuário dispensar; a escolha é guardada por [hintId].
class SwipeHint extends StatefulWidget {
  const SwipeHint({
    super.key,
    required this.hintId,
    required this.message,
    this.startIcon = Icons.check,
    this.endIcon = Icons.delete_outline,
  });

  final String hintId;
  final String message;

  /// Ação revelada deslizando pra direita.
  final IconData startIcon;

  /// Ação revelada deslizando pra esquerda.
  final IconData endIcon;

  @override
  State<SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<SwipeHint>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  static final _slide = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0), weight: 8),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(1), weight: 10),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 16,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: -1.0)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(-1), weight: 10),
    TweenSequenceItem(
      tween: Tween(begin: -1.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeInOutCubic)),
      weight: 16,
    ),
  ]);

  String get _key => 'swipe_hint_seen_v2_${widget.hintId}';

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
      if (!mounted || seen) return;
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
    const width = 76.0;
    const height = 44.0;
    const travel = 20.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: colors.inkSoft,
          child: Stack(
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
                  offset: Offset(_slide.evaluate(_demo) * travel, 0),
                  child: child,
                ),
                child: Container(
                  width: 44,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 22,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.textMuted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                            'Deslize para os lados',
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
