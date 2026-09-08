import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:receyta/theme/app_theme.dart';
import 'package:receyta/theme/tokens.dart';

/// Orçamento de tempo da splash (§9.7 / roadmap A6).
abstract class SplashTimings {
  /// Entrada da bandeja + os seis ingredientes em arco. Toca sempre.
  static const intro = Duration(milliseconds: 1150);

  /// Cúpula e pegador sobem e saem; o wordmark aparece. Toca quando o app
  /// está pronto.
  static const outro = Duration(milliseconds: 600);

  /// A abertura nunca passa disto — `intro + outro` num start quente.
  static const budget = Duration(milliseconds: 1800);
}

/// Splash animada sobre fundo `coral` (§9.7).
///
/// Sequência: a bandeja entra em escala; seis ingredientes sobem em arco e
/// somem ao alcançar a cúpula; a cúpula e o pegador sobem e saem por cima,
/// a barra permanece, e o wordmark aparece no lugar da cúpula.
///
/// A animação **não segura a abertura**: [ready] corre em paralelo à `intro`.
/// Se o app já estiver pronto quando a `intro` termina, a `outro` toca em
/// seguida (total ~1,75s). Se demorar, a splash segura na última frame da
/// `intro` até resolver — nunca trava, nunca corta a `outro`.
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

  /// Fundo fluido (§9.7). Nulo = shader não carregou → cai para `coral` chapado.
  ui.FragmentShader? _bgShader;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _run();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/splash_background.frag',
      );
      if (!mounted) return;
      setState(() => _bgShader = program.fragmentShader());
    } catch (_) {
      // Web antiga ou falha de asset: o fundo `coral` chapado já resolve.
    }
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
    _bgShader?.dispose();
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
          // O "relógio" do shader vem do progresso da própria animação — fluxo
          // durante a intro, um empurrão na outro, e congela no fim (a splash
          // já saiu de cena). Nada de loop infinito — os testes assentam.
          final time = _intro.value * 6.0 + _outro.value * 3.0;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_bgShader != null)
                CustomPaint(painter: _BackgroundPainter(_bgShader!, time))
              else
                ColoredBox(color: colors.coral),
              Center(
                child: CustomPaint(
                  size: const Size(220, 260),
                  painter: _SplashPainter(
                    intro: _intro.value,
                    outro: _outro.value,
                    colors: colors,
                    textStyle: context.texts.displayLarge!,
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

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.shader, this.time);

  final ui.FragmentShader shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.time != time || old.shader != shader;
}

class _SplashPainter extends CustomPainter {
  _SplashPainter({
    required this.intro,
    required this.outro,
    required this.colors,
    required this.textStyle,
  });

  /// 0..1 — entrada da bandeja (0..~0.26) e ingredientes (~0.26..~0.9).
  final double intro;

  /// 0..1 — saída da cúpula e entrada do wordmark.
  final double outro;

  final AppColors colors;
  final TextStyle textStyle;

  static const _ingredientCount = 6;

  // --- Ajustes finos da composição — mexa aqui ---------------------------
  static const _domeRadius = 52.0;
  static const _wordmarkSize = 34.0;

  /// Centro vertical do wordmark, medido para cima a partir do topo da barra.
  /// Maior sobe, menor desce. A cúpula ocupa ~66px acima da barra.
  static const _wordmarkRise = 46.0;

  /// `true`: o `y` fica `coral` e some no fundo (efeito "vazado" da §9.7).
  /// `false`: wordmark inteiro em `paper`, totalmente legível.
  static const _wordmarkYVanishes = false;
  // ---------------------------------------------------------------------

  Color get _paper => colors.onSaturated;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final barY = size.height * 0.78;
    final domeCenter = Offset(cx, barY - 14);
    const domeRadius = _domeRadius;
    final fill = Paint()..color = _paper;

    // Entrada: 0.86 → 1 em escala, nos primeiros ~300ms (intro 0..0.26).
    final enterT = Curves.easeOutBack.transform((intro / 0.26).clamp(0.0, 1.0));
    final scale = _lerp(0.86, 1.0, enterT);

    // Saída: cúpula + pegador sobem e saem depressa, bem antes de o wordmark
    // entrar — senão os dois se atropelam no meio.
    final exitT = Curves.easeInCubic.transform((outro / 0.6).clamp(0.0, 1.0));
    final domeLift = -_lerp(0.0, size.height * 0.9, exitT);
    final domeOpacity = (1.0 - outro * 2.0).clamp(0.0, 1.0);

    // --- barra (sempre) ---
    canvas.save();
    canvas.translate(cx, barY);
    canvas.scale(scale);
    canvas.translate(-cx, -barY);
    final barRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, barY), width: 150, height: 18),
      const Radius.circular(99),
    );
    canvas.drawRRect(barRect, fill);
    canvas.restore();

    // --- cúpula + pegador (entram na intro, saem na outro) ---
    canvas.save();
    canvas.translate(0, domeLift);
    canvas.translate(cx, domeCenter.dy);
    canvas.scale(scale);
    canvas.translate(-cx, -domeCenter.dy);

    final domePaint = Paint()..color = _paper.withValues(alpha: domeOpacity);

    // cúpula: meia-lua
    final domePath = Path()
      ..addArc(
        Rect.fromCircle(center: domeCenter, radius: domeRadius),
        math.pi,
        math.pi,
      )
      ..close();
    canvas.drawPath(domePath, domePaint);

    // detalhe: três nervuras concêntricas na cúpula, como as ranhuras de uma
    // cloche de verdade. Eco discreto do ícone Clara (§9.5), sem virar textura.
    if (enterT > 0.55) {
      final ridge = Paint()
        ..color = colors.coralPattern.withValues(
            alpha: domeOpacity * ((enterT - 0.55) / 0.45).clamp(0.0, 1.0) * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      for (final f in const [0.42, 0.66, 0.88]) {
        canvas.drawArc(
          Rect.fromCircle(center: domeCenter, radius: domeRadius * f),
          math.pi,
          math.pi,
          false,
          ridge,
        );
      }
    }

    // pegador: círculo sobre a cúpula
    canvas.drawCircle(
      Offset(cx, domeCenter.dy - domeRadius - 10),
      7,
      domePaint,
    );
    canvas.restore();

    // --- ingredientes em arco: todos concluem antes do fim da intro, senão
    // sobra um fantasma parado quando o wordmark entra ---
    for (var i = 0; i < _ingredientCount; i++) {
      final start = 0.22 + i * 0.078;
      final end = start + 0.30;
      final p = ((intro - start) / (end - start)).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;

      final fromLeft = i.isEven;
      final startX = cx + (fromLeft ? -1 : 1) * (70 + i * 8);
      final startY = size.height + 20;
      final peak = 90.0 + (i % 3) * 22;

      final x = _lerp(startX, cx, Curves.easeInOut.transform(p));
      final y =
          _lerp(startY, domeCenter.dy, p) - math.sin(p * math.pi) * peak;

      // some ao alcançar a cúpula
      final opacity = (1.0 - Curves.easeIn.transform(p)).clamp(0.0, 1.0);
      // detalhe: leve giro na subida e um toque de cor da paleta em alguns
      final spin = (fromLeft ? 1 : -1) * p * math.pi * 0.9;
      _paintIngredient(
        canvas,
        Offset(x, y),
        i,
        _ingredientColor(i).withValues(alpha: opacity),
        spin,
      );
    }

    // --- vapor: três fiapos sobem da barra logo que a cúpula levanta, e
    // dissipam antes de o wordmark firmar — não cruzam o texto ---
    if (outro > 0.05 && outro < 0.55) {
      for (var i = 0; i < 3; i++) {
        final t = ((outro - 0.05 - i * 0.06) / 0.42).clamp(0.0, 1.0);
        if (t <= 0 || t >= 1) continue;
        final sx = cx + (i - 1) * 14 + math.sin(t * math.pi * 2 + i) * 4;
        final sy = barY - 8 - t * 22;
        final a = (math.sin(t * math.pi) * 0.55).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(sx, sy),
          _lerp(4.5, 1.8, t),
          Paint()..color = _paper.withValues(alpha: a),
        );
      }
    }

    // --- wordmark: entra depois que a cúpula já saiu (outro ~0.4 em diante) ---
    if (outro > 0.4) {
      final wm = Curves.easeOut.transform(((outro - 0.4) / 0.6).clamp(0.0, 1.0));
      if (wm > 0) {
        _paintWordmark(canvas, Offset(cx, barY - _wordmarkRise), wm);
      }
    }
  }

  /// Toque de paleta: a maioria em `paper`, alguns com a cor da seção.
  Color _ingredientColor(int i) => switch (i) {
        1 => colors.lime,
        4 => colors.violet,
        _ => _paper,
      };

  void _paintIngredient(
      Canvas canvas, Offset c, int i, Color color, double rotation) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    switch (i % 3) {
      case 0: // redondo (tomate / ovo)
        canvas.drawCircle(Offset.zero, 9, paint);
      case 1: // folha — lente
        final path = Path()
          ..moveTo(-10, 0)
          ..quadraticBezierTo(0, -11, 10, 0)
          ..quadraticBezierTo(0, 11, -10, 0)
          ..close();
        canvas.drawPath(path, paint);
      case 2: // cenoura — triângulo arredondado
        final path = Path()
          ..moveTo(0, -10)
          ..lineTo(8, 8)
          ..lineTo(-8, 8)
          ..close();
        canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  void _paintWordmark(Canvas canvas, Offset center, double t) {
    // "Rece" + "y" + "ta". O "y vazado" da §9.7 é um furo na CÚPULA (coral
    // aparece através dele), não no wordmark — aqui o padrão é legível.
    final style = textStyle.copyWith(
      fontSize: _wordmarkSize,
      color: _paper.withValues(alpha: t),
    );
    final yStyle = style.copyWith(
      color: (_wordmarkYVanishes ? colors.coral : _paper).withValues(alpha: t),
    );
    final tp = TextPainter(
      text: TextSpan(children: [
        TextSpan(text: 'Rece', style: style),
        TextSpan(text: 'y', style: yStyle),
        TextSpan(text: 'ta', style: style),
      ]),
      textDirection: TextDirection.ltr,
    )..layout();
    final slide = _lerp(10.0, 0.0, t);
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2) + Offset(0, slide));
  }

  @override
  bool shouldRepaint(_SplashPainter old) =>
      old.intro != intro || old.outro != outro;
}

/// `lerpDouble` sem o nullable de `dart:ui`.
double _lerp(double a, double b, double t) => a + (b - a) * t;
