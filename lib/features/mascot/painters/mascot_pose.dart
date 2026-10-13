import 'dart:math' as math;
import 'dart:ui';

/// Duração do pulo de comemoração, em segundos.
const celebrationSeconds = 1.5;

/// Duração do aceno, em segundos.
const waveSeconds = 2.4;

/// Estado visual de um instante do mascote. O painter só desenha isto; quem
/// calcula a pose (idle, thinking, waving, celebrating) são as funções de
/// movimento. Ângulos em radianos, positivo = para fora do corpo (braços e
/// pernas). `look` vai de -1 a 1, `mouth` de 0 (sorriso) a 1 (boca aberta),
/// `hand*` de 0 (luva fechada) a 1 (mão aberta), `wrist*` balança a mão e
/// `burst` de 0 a 1 é o progresso do confete (0 = sem confete). `lid` de 0 a 1
/// ergue a peça de cima (tampa do Pote, botão do Cloche). `dx` desloca o corpo
/// para o lado e `sad` de 0 a 1 carrega o rosto triste (pálpebras caídas e
/// boca para baixo).
class MascotPose {
  final double dx;
  final double dy;
  final double scaleX;
  final double scaleY;
  final double armLeft;
  final double armRight;
  final double handLeft;
  final double handRight;
  final double wristLeft;
  final double wristRight;
  final double legLeft;
  final double legRight;
  final double blink;
  final double tilt;
  final double mouth;
  final double burst;
  final double lid;
  final double sad;
  final Offset look;

  const MascotPose({
    this.dx = 0,
    this.dy = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.armLeft = 0.06,
    this.armRight = 0.06,
    this.handLeft = 0,
    this.handRight = 0,
    this.wristLeft = 0,
    this.wristRight = 0,
    this.legLeft = 0,
    this.legRight = 0,
    this.blink = 0,
    this.tilt = 0,
    this.mouth = 0,
    this.burst = 0,
    this.lid = 0,
    this.sad = 0,
    this.look = Offset.zero,
  });

  static const rest = MascotPose();

  MascotPose copyWith({
    double? dx,
    double? dy,
    double? armLeft,
    double? armRight,
    double? handLeft,
    double? handRight,
    double? wristLeft,
    double? wristRight,
    double? legLeft,
    double? legRight,
    double? tilt,
    double? mouth,
    Offset? look,
  }) {
    return MascotPose(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scaleX: scaleX,
      scaleY: scaleY,
      armLeft: armLeft ?? this.armLeft,
      armRight: armRight ?? this.armRight,
      handLeft: handLeft ?? this.handLeft,
      handRight: handRight ?? this.handRight,
      wristLeft: wristLeft ?? this.wristLeft,
      wristRight: wristRight ?? this.wristRight,
      legLeft: legLeft ?? this.legLeft,
      legRight: legRight ?? this.legRight,
      blink: blink,
      tilt: tilt ?? this.tilt,
      mouth: mouth ?? this.mouth,
      burst: burst,
      lid: lid,
      sad: sad,
      look: look ?? this.look,
    );
  }

  static MascotPose lerp(MascotPose a, MascotPose b, double t) {
    double l(double x, double y) => lerpDouble(x, y, t)!;
    return MascotPose(
      dx: l(a.dx, b.dx),
      dy: l(a.dy, b.dy),
      scaleX: l(a.scaleX, b.scaleX),
      scaleY: l(a.scaleY, b.scaleY),
      armLeft: l(a.armLeft, b.armLeft),
      armRight: l(a.armRight, b.armRight),
      handLeft: l(a.handLeft, b.handLeft),
      handRight: l(a.handRight, b.handRight),
      wristLeft: l(a.wristLeft, b.wristLeft),
      wristRight: l(a.wristRight, b.wristRight),
      legLeft: l(a.legLeft, b.legLeft),
      legRight: l(a.legRight, b.legRight),
      blink: l(a.blink, b.blink),
      tilt: l(a.tilt, b.tilt),
      mouth: l(a.mouth, b.mouth),
      burst: b.burst,
      lid: l(a.lid, b.lid),
      sad: l(a.sad, b.sad),
      look: Offset.lerp(a.look, b.look, t)!,
    );
  }
}

/// Espera viva: respira, balança o peso de um pé para o outro, o olhar vaga e,
/// a cada 9 s, dá um aceno rápido com a mão aberta.
MascotPose idlePose(double seconds) {
  final phase = seconds * 2 * math.pi / 3.2;
  final breath = math.sin(phase);
  final sway = math.sin(seconds * 2 * math.pi / 6.4);
  final armSwing = math.sin(phase - 0.6) * 0.05;
  final blinkClock = seconds % 4.4;
  final blink =
      blinkClock < 0.14 ? math.sin(blinkClock / 0.14 * math.pi) : 0.0;
  final fidgetClock = seconds % 9.0;
  final fidget = fidgetClock > 6.4 && fidgetClock < 8.0
      ? math.sin(math.pi * (fidgetClock - 6.4) / 1.6)
      : 0.0;
  return MascotPose(
    dx: sway * 2.5,
    dy: -3 * breath,
    scaleX: 1 - breath * 0.008,
    scaleY: 1 + breath * 0.015,
    armLeft: 0.06 + armSwing,
    armRight: 0.06 - armSwing + fidget * 2.2,
    handRight: math.min(1.0, fidget * 3),
    wristRight: fidget * math.sin(seconds * 11) * 0.4,
    legLeft: math.sin(phase) * 0.03 + sway * 0.03,
    legRight: -math.sin(phase) * 0.03 + sway * 0.03,
    blink: blink,
    tilt: sway * 0.025 - fidget * 0.04,
    look: Offset(
      0.45 + math.sin(seconds * 0.7) * 0.25 + math.sin(seconds * 1.9) * 0.15,
      -0.2 + math.sin(seconds * 0.9) * 0.1,
    ),
  );
}

/// Pensativo: olhar girando para cima, cabeça inclinada, mão no queixo e pé
/// batendo no chão.
MascotPose thinkingPose(double seconds) {
  return idlePose(seconds).copyWith(
    armRight: 0.7 + math.sin(seconds * 2.4) * 0.08,
    handRight: 0.45,
    wristRight: math.sin(seconds * 3) * 0.12,
    legRight: 0.2 * math.max(0.0, math.sin(seconds * 7)),
    tilt: 0.06 + math.sin(seconds * 1.1) * 0.02,
    look: Offset(
      math.cos(seconds * 1.7) * 0.85,
      -0.55 + math.sin(seconds * 1.7) * 0.2,
    ),
  );
}

/// Aceno: mão aberta balançando, saltinhos, passos alternados e olhar de
/// frente.
MascotPose wavingPose(double seconds) {
  final base = idlePose(seconds);
  final step = math.sin(seconds * 6);
  return base.copyWith(
    dy: base.dy - 5 * step.abs(),
    armLeft: 0.25 + math.sin(seconds * 6 - 0.8) * 0.1,
    armRight: 2.3 + math.sin(seconds * 10) * 0.2,
    handRight: 1,
    wristRight: math.sin(seconds * 12) * 0.45,
    legLeft: step * 0.12,
    legRight: -step * 0.12,
    tilt: -0.05 + math.sin(seconds * 3) * 0.03,
    mouth: 0.55,
    look: Offset.zero,
  );
}

/// Pulo de comemoração: agacha, salta de braços e pernas abertos, mãos abertas
/// balançando, boca aberta e confete; amortece na aterrissagem. [seconds] conta
/// desde o início.
MascotPose celebratePose(double seconds) {
  final t = seconds.clamp(0.0, celebrationSeconds);
  final crouch = (t / 0.22).clamp(0.0, 1.0);
  final air = ((t - 0.22) / 0.7).clamp(0.0, 1.0);
  final land = ((t - 0.92) / 0.5).clamp(0.0, 1.0);
  final push = 1 - (air * 4).clamp(0.0, 1.0);
  final lift = math.sin(math.pi * air);
  final impact = math.sin(math.pi * land);
  final squash = 0.12 * crouch * push + 0.14 * impact - 0.06 * lift;
  final arms = 2.5 * math.sin(math.pi * ((t - 0.1) / 1.1).clamp(0.0, 1.0));
  final open = (arms / 1.6).clamp(0.0, 1.0);
  final wiggle = math.sin(seconds * 22) * 0.4 * open;
  return MascotPose(
    dy: 6 * crouch * push - 48 * lift + 4 * impact,
    scaleX: 1 + squash * 0.6,
    scaleY: 1 - squash,
    armLeft: arms,
    armRight: arms,
    handLeft: open,
    handRight: open,
    wristLeft: wiggle,
    wristRight: -wiggle,
    legLeft: 0.5 * lift - 0.12 * impact,
    legRight: 0.5 * lift - 0.12 * impact,
    tilt: math.sin(math.pi * 2 * air) * 0.1 * lift,
    mouth: math.sin(math.pi * ((t - 0.05) / 1.2).clamp(0.0, 1.0)),
    burst: ((t - 0.3) / 1.15).clamp(0.0, 1.0),
    lid: lift,
    look: Offset(0, -0.6 * lift),
  );
}

/// Triste: encolhido, olhar baixo e de lado, cabeça pendida, braços e pernas
/// encostados e um suspiro lento a cada 5 s.
MascotPose sadPose(double seconds) {
  final sigh = math.sin(seconds * 2 * math.pi / 5.2);
  final glance = math.sin(seconds * 0.5);
  final blinkClock = seconds % 6.0;
  final blink =
      blinkClock < 0.3 ? math.sin(blinkClock / 0.3 * math.pi) : 0.0;
  return MascotPose(
    dy: 5 + sigh * 1.5,
    scaleX: 1.02 + sigh * 0.006,
    scaleY: 0.96 + sigh * 0.012,
    armLeft: -0.02,
    armRight: -0.02,
    legLeft: -0.03,
    legRight: -0.03,
    blink: blink,
    tilt: 0.045 + math.sin(seconds * 0.8) * 0.01,
    sad: 1,
    look: Offset(glance * 0.3, 0.7),
  );
}

/// Apresentando: um braço estendido para o lado, mão aberta, saltinhos e olhar
/// voltado para o que está sendo mostrado.
MascotPose presentingPose(double seconds) {
  final base = idlePose(seconds);
  final hop = math.sin(seconds * 5).abs();
  return base.copyWith(
    dy: base.dy - 3 * hop,
    armLeft: 1.55 + math.sin(seconds * 4) * 0.12,
    handLeft: 1,
    wristLeft: math.sin(seconds * 6) * 0.2,
    armRight: 0.15,
    tilt: 0.05 + math.sin(seconds * 2) * 0.02,
    mouth: 0.3,
    look: Offset(-0.5 + math.sin(seconds * 1.5) * 0.2, 0.1),
  );
}
