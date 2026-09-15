import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';

/// Loader da marca: a mesma cúpula do ícone (`assets/brand/logoIcon.png`,
/// também usada na splash em `lib/splash.dart`) "respirando" sobre a bandeja
/// — sobe com um squash-and-stretch suave (o bounce fica elástico, não
/// mecânico) e solta fumacinha contínua, num loop sem sequência única de
/// abertura do app. Substitui o `CircularProgressIndicator` genérico nas
/// telas que esperam o banco/rede (ingredientes, pastas, tags, lixeira,
/// importação por foto).
///
/// Sozinho, sem depender de nada da tela que o usa — mesmo espírito do
/// [ReceytasWordmark] em `receytas_wordmark.dart`.
class BrandLoader extends StatefulWidget {
  const BrandLoader({super.key, this.size = 56, this.color});

  final double size;

  /// `null` usa `colors.coral` — a cor do ícone em si.
  final Color? color;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colors.coral;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _BrandLoaderPainter(t: _controller.value, color: color),
      ),
    );
  }
}

class _BrandLoaderPainter extends CustomPainter {
  _BrandLoaderPainter({required this.t, required this.color});

  /// 0..1, um ciclo do loop.
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final cx = size.width / 2;
    final trayY = size.height * 0.72;
    final domeRadius = s * 0.30;
    final domeCenter = Offset(cx, trayY - s * 0.04);

    // Onda suave 0..1..0 por ciclo — a cúpula sobe na 1ª metade, desce na 2ª.
    final wave = (math.sin(2 * math.pi * t - math.pi / 2) + 1) / 2;
    final lift = wave * s * 0.11;
    final fill = Paint()..color = color;

    // Squash-and-stretch: estica na subida/descida rápida (meio do
    // movimento), esmaga de leve perto do topo/embaixo (onde a velocidade
    // é quase zero) — é o que faz o bounce parecer elástico/vivo em vez de
    // só transladar pra cima e pra baixo.
    final stretch = math.sin(2 * math.pi * t);
    final scaleY = 1 + stretch * 0.08;
    final scaleX = 1 - stretch * 0.05;

    // --- bandeja (fixa) ---
    final trayRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, trayY), width: s * 0.82, height: s * 0.1),
      const Radius.circular(99),
    );
    canvas.drawRRect(trayRect, fill);

    // --- fumacinha: 3 fiapos contínuos, defasados, sempre subindo e
    // dissipando (não só quando a cúpula está aberta) — dá a sensação de
    // fluxo constante em vez de um pulso só por ciclo. Cada um roda 2x mais
    // rápido que o bounce e balança de leve pros lados enquanto sobe.
    for (var i = 0; i < 3; i++) {
      final p = (t * 2 + i / 3) % 1.0;
      final sway = math.sin(p * math.pi * 2 + i * 2.1) * s * 0.05;
      final riseX = cx + sway;
      final riseY = domeCenter.dy - domeRadius - s * 0.12 - p * s * 0.4;
      final fade = math.sin(p * math.pi).clamp(0.0, 1.0);
      final steamPaint = Paint()
        ..color = color.withValues(alpha: fade * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02);
      canvas.drawCircle(
        Offset(riseX, riseY),
        _lerp(s * 0.05, s * 0.014, p),
        steamPaint,
      );
    }

    // --- cúpula + pegador (sobem com squash-and-stretch) ---
    canvas.save();
    canvas.translate(cx, domeCenter.dy - lift);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-cx, -(domeCenter.dy - lift));

    final domePath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, domeCenter.dy - lift), radius: domeRadius),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(domePath, fill);

    canvas.drawCircle(
      Offset(cx, domeCenter.dy - lift - domeRadius - s * 0.09),
      s * 0.065,
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrandLoaderPainter old) =>
      old.t != t || old.color != color;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
