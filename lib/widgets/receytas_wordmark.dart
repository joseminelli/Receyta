import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// O "Rece**y**tas" grande do cabeçalho da home — o wordmark da marca. Easter
/// egg: 5 toques em menos de 1,5s disparam um estouro (escala + giro que
/// decai) e o "y" ganha, por um instante, a textura do azulejo `arco` (o
/// mesmo módulo usado na peça decorativa do cabeçalho de receitas, §9.4) em
/// vez da cor chapada — sem bloco de fundo, sem cor alheia à paleta, só o
/// próprio padrão do app vazando pela letra e voltando ao coral sólido no
/// final. Autocontido — não depende de nada da tela que o usa, por isso vive
/// em `widgets/` e não junto da `RecipesPage`.
class ReceytasWordmark extends StatefulWidget {
  const ReceytasWordmark({super.key});

  @override
  State<ReceytasWordmark> createState() => _ReceytasWordmarkState();
}

class _ReceytasWordmarkState extends State<ReceytasWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const _tapsNeeded = 5;
  static const _tapWindow = Duration(milliseconds: 1500);

  int _taps = 0;
  DateTime? _windowStart;

  void _onTap() {
    final now = DateTime.now();
    if (_windowStart == null || now.difference(_windowStart!) > _tapWindow) {
      _windowStart = now;
      _taps = 1;
    } else {
      _taps++;
    }
    if (_taps >= _tapsNeeded) {
      _taps = 0;
      _windowStart = null;
      _anim.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final style = AppTextStyles.display(64).copyWith(color: colors.onSaturated);

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          // Estouro: sobe e volta pro tamanho normal (pico em t=0.5), e é
          // também quanto a textura do "y" fica visível nesse mesmo pico.
          final burst = math.sin(t * math.pi).clamp(0.0, 1.0);
          final scale = 1 + burst * 0.3;
          // Giro que decai — bastante no começo, nada no fim.
          final angle = math.sin(t * math.pi * 5) * (1 - t) * 0.12;
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: style,
                    children: [
                      const TextSpan(text: 'Rece'),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: _TexturedY(
                          style: style,
                          burst: burst,
                          color: colors.coral,
                          patternColor: colors.coralPattern,
                          devicePixelRatio: dpr,
                        ),
                      ),
                      const TextSpan(text: 'tas'),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// O "y" propriamente dito: coral sólido em repouso, com a versão texturada
/// (via `ShaderMask` sobre o mesmo glifo) surgindo por cima conforme [burst]
/// sobe — em vez de trocar de cor, ela "revela" o padrão por baixo.
class _TexturedY extends StatelessWidget {
  const _TexturedY({
    required this.style,
    required this.burst,
    required this.color,
    required this.patternColor,
    required this.devicePixelRatio,
  });

  final TextStyle style;
  final double burst;
  final Color color;
  final Color patternColor;
  final double devicePixelRatio;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('y', style: style.copyWith(color: color)),
        if (burst > 0.01)
          Opacity(
            opacity: burst,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (_) => tileShader(
                motif: TileMotif.arco,
                background: color,
                patternColor: patternColor,
                tile: 12,
                devicePixelRatio: devicePixelRatio,
              ),
              child: Text('y', style: style),
            ),
          ),
      ],
    );
  }
}
