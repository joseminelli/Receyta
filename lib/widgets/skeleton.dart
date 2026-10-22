import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Casca de carregamento: os [SkeletonBox] filhos ganham um brilho que varre
/// da esquerda pra direita, com um só controlador pra árvore inteira. Sem
/// animação quando o sistema pede movimento reduzido. [base] é a cor dos
/// blocos (padrão `paperSoft`; sobre fundo `ink`, passe `inkSoft`).
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child, this.base});

  final Widget child;
  final Color? base;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = widget.base ?? colors.paperSoft;
    final highlight = Color.alphaBlend(
      colors.onPaper.withValues(alpha: 0.08),
      base,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return _SkeletonBase(color: base, child: widget.child);
    }
    return Semantics(
      label: 'Carregando',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) => ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) => LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              transform: _Slide(_controller.value * 2 - 1),
            ).createShader(rect),
            child: _SkeletonBase(color: base, child: child!),
          ),
        ),
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

class _SkeletonBase extends InheritedWidget {
  const _SkeletonBase({required this.color, required super.child});

  final Color color;

  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonBase>()?.color ??
      context.colors.paperSoft;

  @override
  bool updateShouldNotify(_SkeletonBase old) => old.color != color;
}

/// Bloco cinza arredondado que imita um pedaço de conteúdo; use dentro de um
/// [Skeleton].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadii.sm,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _SkeletonBase.of(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lista vertical de cartões-fantasma, pra telas de listas simples.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({
    super.key,
    this.count = 4,
    this.cardHeight = 96,
    this.base,
  });

  final int count;
  final double cardHeight;
  final Color? base;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      base: base,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        children: [
          for (var i = 0; i < count; i++) ...[
            SkeletonBox(height: cardHeight, radius: AppRadii.lg),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
