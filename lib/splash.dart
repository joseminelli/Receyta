import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';
import 'package:receyta/theme/typography.dart';
import 'package:receyta/widgets/tile_pattern.dart';

/// Orçamento de tempo da splash (§9.7 / roadmap A6).
abstract class SplashTimings {
  /// A bandeja entra, os ingredientes caem nela e a cúpula fecha por cima.
  /// Toca sempre.
  static const intro = Duration(milliseconds: 900);

  /// A cúpula se abre e revela o prato, brilha, sai por cima e o nome
  /// aparece. Toca quando o app está pronto.
  static const outro = Duration(milliseconds: 850);

  /// A abertura nunca passa disto — `intro + outro` num start quente.
  static const budget = Duration(milliseconds: 1800);
}

/// Splash animada sobre o azulejo de arcos do app (§9.7).
///
/// Sequência: a bandeja entra; seis ingredientes (cenoura, tomate, ovo,
/// cogumelo, limão e uma folha) caem nela em arco, um depois do outro; a
/// cúpula desce e fecha por cima, com um quique. Quando o app está pronto, a
/// cúpula se abre — levanta e tomba de lado —, o prato aparece com faíscas e
/// vapor, a cúpula some por cima e "Receyta" entra embaixo, com o lema.
///
/// A animação **não segura a abertura**: [ready] corre em paralelo à `intro`.
/// Se o app já estiver pronto quando a `intro` termina, a `outro` toca em
/// seguida (total ~1,75s). Se demorar, a splash segura na última frame da
/// `intro` (a cúpula fechada) até resolver — nunca trava, nunca corta a
/// `outro`.
class Splash extends StatefulWidget {
  const Splash({super.key, required this.ready, required this.onComplete});

  /// Inicialização do app (Drift no A7). Resolvida → a splash pode sair.
  final Future<void> ready;

  /// Chamado uma vez, quando a `outro` termina.
  final VoidCallback onComplete;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: SplashTimings.intro,
  );
  late final _outro = AnimationController(
    vsync: this,
    duration: SplashTimings.outro,
  );

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await _intro.forward().orCancel;
      await widget.ready;
      if (!mounted) return;
      await _outro.forward().orCancel;
    } on TickerCanceled {
      return; // widget saiu de cena antes da animação terminar
    }
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _intro.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.coral,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _outro]),
        builder: (context, _) {
          final settle = Curves.easeOutCubic.transform(_intro.value);
          final glow = math.sin((_outro.value / 0.6).clamp(0.0, 1.0) * math.pi);
          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 1.12 - 0.12 * settle,
                child: TilePattern(
                  motif: TileMotif.arco,
                  background: colors.coral,
                  patternColor: colors.coralPattern,
                  tile: 88,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    colors: [
                      colors.coralLight.withValues(alpha: 0.5 + 0.25 * glow),
                      colors.coral.withValues(alpha: 0.0),
                      const Color(0xFF7A1E08).withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Center(
                child: CustomPaint(
                  size: const Size(340, 420),
                  painter: _SplashPainter(
                    intro: _intro.value,
                    outro: _outro.value,
                    colors: colors,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _Food { carrot, tomato, egg, mushroom, lemon, leaf }

const _slots = [
  (food: _Food.carrot, x: -82.0, y: -18.0, size: 40.0),
  (food: _Food.tomato, x: -42.0, y: -18.0, size: 36.0),
  (food: _Food.egg, x: -2.0, y: -17.0, size: 38.0),
  (food: _Food.mushroom, x: 38.0, y: -18.0, size: 38.0),
  (food: _Food.lemon, x: 78.0, y: -17.0, size: 36.0),
  (food: _Food.leaf, x: -14.0, y: -50.0, size: 40.0),
];

class _SplashPainter extends CustomPainter {
  _SplashPainter({
    required this.intro,
    required this.outro,
    required this.colors,
  });

  /// 0..1 — bandeja, ingredientes caindo e cúpula fechando.
  final double intro;

  /// 0..1 — cúpula abrindo, brilho, saída e nome.
  final double outro;

  final AppColors colors;

  static const _domeRadius = 108.0;
  static const _plateWidth = 250.0;

  Color get _paper => colors.onSaturated;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final plateY = size.height * 0.60;

    final enter = Curves.easeOutBack.transform((intro / 0.2).clamp(0.0, 1.0));
    final scale = _lerp(0.82, 1.0, enter);
    final appear = (intro / 0.16).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(cx, plateY);
    canvas.scale(scale);
    canvas.translate(-cx, -plateY);

    _paintShadow(canvas, cx, plateY, appear);
    _paintPlate(canvas, cx, plateY, appear);
    _paintFood(canvas, cx, plateY);
    _paintSparkles(canvas, cx, plateY);
    _paintSteam(canvas, cx, plateY);
    _paintName(canvas, cx, plateY);
    _paintDome(canvas, cx, plateY, size);

    canvas.restore();

    _paintTagline(canvas, cx, plateY + 52);
  }

  void _paintShadow(Canvas canvas, double cx, double plateY, double a) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, plateY + 22),
        width: _plateWidth * 0.92,
        height: 15,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
  }

  void _paintPlate(Canvas canvas, double cx, double plateY, double a) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, plateY + 8),
          width: _plateWidth,
          height: 18,
        ),
        const Radius.circular(99),
      ),
      Paint()..color = _paper.withValues(alpha: a),
    );
    canvas.drawLine(
      Offset(cx - _plateWidth * 0.38, plateY + 3.2),
      Offset(cx + _plateWidth * 0.2, plateY + 3.2),
      Paint()
        ..color = colors.paperSoft.withValues(alpha: 0.9 * a)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFood(Canvas canvas, double cx, double plateY) {
    final pop = 1.0 +
        0.14 * math.sin(((outro - 0.12) / 0.32).clamp(0.0, 1.0) * math.pi);

    final melt =
        Curves.easeIn.transform(((outro - 0.04) / 0.3).clamp(0.0, 1.0));
    if (melt >= 1) return;

    for (var i = 0; i < _slots.length; i++) {
      final s = _slots[i];
      final start = 0.10 + i * 0.075;
      final p = ((intro - start) / 0.26).clamp(0.0, 1.0);
      if (p <= 0) continue;

      final fromLeft = i.isEven;
      final fall = Curves.easeInQuad.transform(p);
      final drift = Curves.easeOutCubic.transform(p);
      final x = _lerp(s.x + (fromLeft ? -64.0 : 64.0), s.x, drift);
      final y = _lerp(-240.0, s.y, fall);
      final spin = (fromLeft ? 1 : -1) * (1 - p) * math.pi * 1.6;

      final land = p > 0.86 ? math.sin((p - 0.86) / 0.14 * math.pi) : 0.0;
      final sx = 1.0 + 0.16 * land;
      final sy = 1.0 - 0.16 * land;
      final opacity = (p / 0.15).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(cx + x, plateY + y - 38 * melt);
      canvas.rotate(spin);
      canvas.scale(sx * pop * (1 - melt), sy * pop * (1 - melt));
      _paintFoodItem(canvas, s.food, s.size, opacity * (1 - melt));
      canvas.restore();
    }
  }

  void _paintFoodItem(Canvas canvas, _Food food, double size, double a) {
    final r = size / 2;
    final outline = Paint()
      ..color = const Color(0xFF7A1E08).withValues(alpha: 0.28 * a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    Paint fill(Color c) => Paint()..color = c.withValues(alpha: a);
    Paint stroke(Color c, double w) => Paint()
      ..color = c.withValues(alpha: a)
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;

    switch (food) {
      case _Food.tomato:
        canvas.drawCircle(Offset.zero, r * 0.92, fill(colors.danger));
        canvas.drawCircle(Offset.zero, r * 0.92, outline);
        canvas.drawCircle(
          Offset(-r * 0.32, -r * 0.3),
          r * 0.22,
          fill(const Color(0x8CFFFFFF)),
        );
        for (var k = 0; k < 5; k++) {
          final ang = -math.pi / 2 + k * 2 * math.pi / 5;
          canvas.drawLine(
            Offset(0, -r * 0.82),
            Offset(
              math.cos(ang) * r * 0.45,
              -r * 0.82 + math.sin(ang) * r * 0.3,
            ),
            stroke(colors.lime, 4),
          );
        }
      case _Food.carrot:
        final body = Path()
          ..moveTo(-r * 0.2, -r * 0.5)
          ..quadraticBezierTo(r * 0.7, -r * 0.2, r * 0.1, r * 1.0)
          ..quadraticBezierTo(-r * 0.7, r * 0.2, -r * 0.2, -r * 0.5)
          ..close();
        canvas.drawPath(body, fill(const Color(0xFFFFA23A)));
        canvas.drawPath(body, outline);
        for (final dy in const [-0.1, 0.25]) {
          canvas.drawLine(
            Offset(-r * 0.15, r * dy),
            Offset(r * 0.18, r * (dy + 0.12)),
            stroke(const Color(0xFFD9741A), 2.2),
          );
        }
        for (final dx in const [-0.28, 0.0, 0.26]) {
          canvas.drawLine(
            Offset(-r * 0.1, -r * 0.45),
            Offset(r * dx - r * 0.15, -r * 0.95),
            stroke(colors.lime, 4.2),
          );
        }
      case _Food.egg:
        final white = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(-r * 0.2, 0),
            width: r * 1.5,
            height: r * 1.3,
          ))
          ..addOval(Rect.fromCenter(
            center: Offset(r * 0.3, r * 0.1),
            width: r * 1.3,
            height: r * 1.2,
          ));
        canvas.drawPath(white, fill(_paper));
        canvas.drawPath(white, outline);
        canvas.drawCircle(
          Offset(r * 0.05, 0),
          r * 0.36,
          fill(const Color(0xFFFFC93C)),
        );
        canvas.drawCircle(
          Offset(-r * 0.05, -r * 0.1),
          r * 0.1,
          fill(const Color(0xB3FFFFFF)),
        );
      case _Food.mushroom:
        final cap = Path()
          ..addArc(
            Rect.fromCircle(center: Offset.zero, radius: r * 0.95),
            math.pi,
            math.pi,
          )
          ..close();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, r * 0.45),
              width: r * 0.62,
              height: r * 0.9,
            ),
            Radius.circular(r * 0.2),
          ),
          fill(const Color(0xFFF3E3C7)),
        );
        canvas.drawPath(cap, fill(const Color(0xFFD9A066)));
        canvas.drawPath(cap, outline);
        for (final o in const [
          Offset(-0.4, -0.35),
          Offset(0.1, -0.6),
          Offset(0.45, -0.25),
        ]) {
          canvas.drawCircle(Offset(r * o.dx, r * o.dy), r * 0.1, fill(_paper));
        }
      case _Food.lemon:
        canvas.drawCircle(Offset.zero, r * 0.95, fill(colors.lime));
        canvas.drawCircle(Offset.zero, r * 0.95, outline);
        canvas.drawCircle(
          Offset.zero,
          r * 0.74,
          fill(const Color(0xFFF6FBC6)),
        );
        for (var k = 0; k < 6; k++) {
          final ang = k * math.pi / 3;
          canvas.drawLine(
            Offset.zero,
            Offset(math.cos(ang) * r * 0.74, math.sin(ang) * r * 0.74),
            stroke(colors.lime, 2.6),
          );
        }
      case _Food.leaf:
        final leaf = Path()
          ..moveTo(-r, r * 0.15)
          ..quadraticBezierTo(0, -r * 1.05, r, r * 0.15)
          ..quadraticBezierTo(0, r * 0.95, -r, r * 0.15)
          ..close();
        canvas.drawPath(leaf, fill(colors.lime));
        canvas.drawPath(leaf, outline);
        canvas.drawLine(
          Offset(-r * 0.8, r * 0.12),
          Offset(r * 0.8, r * 0.12),
          stroke(const Color(0xFF6E8A12), 2.2),
        );
    }
  }

  void _paintSparkles(Canvas canvas, double cx, double plateY) {
    const spots = [
      (dx: -118.0, dy: -70.0, size: 11.0, delay: 0.00),
      (dx: 112.0, dy: -90.0, size: 14.0, delay: 0.06),
      (dx: -70.0, dy: -128.0, size: 9.0, delay: 0.12),
      (dx: 78.0, dy: -140.0, size: 10.0, delay: 0.04),
      (dx: 0.0, dy: -150.0, size: 12.0, delay: 0.10),
    ];
    for (final s in spots) {
      final k = ((outro - 0.18 - s.delay) / 0.4).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final a = math.sin(k * math.pi);
      final c = Offset(cx + s.dx, plateY + s.dy - k * 10);
      final r = s.size * (0.6 + 0.5 * a);
      final star = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(star, Paint()..color = _paper.withValues(alpha: a));
    }
  }

  void _paintSteam(Canvas canvas, double cx, double plateY) {
    for (var i = 0; i < 4; i++) {
      final k = ((outro - 0.1 - i * 0.07) / 0.5).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final x = cx + (i - 1.5) * 30 + math.sin(k * math.pi * 2 + i) * 6;
      final y = plateY - 70 - k * 60;
      canvas.drawCircle(
        Offset(x, y),
        _lerp(6.0, 2.4, k),
        Paint()..color = _paper.withValues(alpha: math.sin(k * math.pi) * 0.55),
      );
    }
  }

  void _paintDome(Canvas canvas, double cx, double plateY, Size size) {
    final closeT = ((intro - 0.62) / 0.3).clamp(0.0, 1.0);
    if (closeT <= 0) return;
    final drop = -150.0 * (1.0 - Curves.bounceOut.transform(closeT));
    final openT = Curves.easeOutCubic.transform((outro / 0.34).clamp(0.0, 1.0));
    final exitT = Curves.easeInCubic.transform(
      ((outro - 0.34) / 0.3).clamp(0.0, 1.0),
    );
    final lift =
        drop - _lerp(0.0, 78.0, openT) - _lerp(0.0, size.height * 0.8, exitT);
    final tilt = _lerp(0.0, -0.3, openT) + _lerp(0.0, -0.4, exitT);
    final opacity = (Curves.easeOut.transform((closeT / 0.3).clamp(0.0, 1.0)) *
            (1.0 - exitT))
        .clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final center = Offset(cx, plateY - 3);
    final hinge = Offset(cx - _domeRadius, center.dy);
    canvas.save();
    canvas.translate(0, lift);
    canvas.translate(hinge.dx, hinge.dy);
    canvas.rotate(tilt);
    canvas.translate(-hinge.dx, -hinge.dy);

    final paint = Paint()..color = _paper.withValues(alpha: opacity);
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: _domeRadius),
          math.pi,
          math.pi,
        )
        ..close(),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, 1),
          width: _domeRadius * 2 + 14,
          height: 9,
        ),
        const Radius.circular(99),
      ),
      paint,
    );
    final ridge = Paint()
      ..color = colors.coralPattern.withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final f in const [0.42, 0.66, 0.88]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: _domeRadius * f),
        math.pi,
        math.pi,
        false,
        ridge,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _domeRadius * 0.78),
      math.pi * 1.1,
      math.pi * 0.2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, center.dy - _domeRadius - 10), 9, paint);
    canvas.restore();
  }

  /// "Receyta" nasce dentro da cúpula, no lugar dos ingredientes: eles se
  /// desmancham e o nome sobe do prato, com um quique.
  void _paintName(Canvas canvas, double cx, double plateY) {
    final k = ((outro - 0.12) / 0.4).clamp(0.0, 1.0);
    if (k <= 0) return;
    final scale = _lerp(0.55, 1.0, Curves.easeOutBack.transform(k));
    final a = Curves.easeOut.transform((k / 0.5).clamp(0.0, 1.0));

    final name = TextPainter(
      text: TextSpan(
        text: 'Receyta',
        style: AppTextStyles.display(54).copyWith(
          color: _paper.withValues(alpha: a),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final baseline = Offset(cx, plateY - 6);
    canvas.save();
    canvas.translate(baseline.dx, baseline.dy);
    canvas.scale(scale);
    name.paint(canvas, Offset(-name.width / 2, -name.height));
    canvas.restore();
  }

  void _paintTagline(Canvas canvas, double cx, double top) {
    final tt = Curves.easeOut.transform(((outro - 0.4) / 0.4).clamp(0.0, 1.0));
    if (tt <= 0) return;
    final tagline = TextPainter(
      text: TextSpan(
        text: 'Suas receitas, num lugar só',
        style: TextStyle(
          color: _paper.withValues(alpha: 0.88 * tt),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tagline.paint(
      canvas,
      Offset(cx - tagline.width / 2, top + _lerp(10.0, 0.0, tt)),
    );
  }

  @override
  bool shouldRepaint(_SplashPainter old) =>
      old.intro != intro || old.outro != outro;
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
