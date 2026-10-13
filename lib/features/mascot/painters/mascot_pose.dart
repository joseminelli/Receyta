import 'dart:math' as math;
import 'dart:ui';

/// Duração do pulo de comemoração, em segundos.
const celebrationSeconds = 1.5;

/// Duração do aceno, em segundos.
const waveSeconds = 2.4;

/// Estado visual de um instante do mascote. O painter só desenha isto; quem
/// calcula a pose (idle, thinking, waving, celebrating) são as funções de
/// movimento. Ângulos em radianos, positivo = braço para fora. `look` vai de
/// -1 a 1, `mouth` de 0 (sorriso) a 1 (boca aberta) e `burst` de 0 a 1 é o
/// progresso do confete (0 = sem confete).
class MascotPose {
  final double dy;
  final double scaleX;
  final double scaleY;
  final double armLeft;
  final double armRight;
  final double blink;
  final double tilt;
  final double mouth;
  final double burst;
  final Offset look;

  const MascotPose({
    this.dy = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.armLeft = 0.06,
    this.armRight = 0.06,
    this.blink = 0,
    this.tilt = 0,
    this.mouth = 0,
    this.burst = 0,
    this.look = Offset.zero,
  });

  static const rest = MascotPose();

  MascotPose copyWith({
    double? dy,
    double? armLeft,
    double? armRight,
    double? tilt,
    double? mouth,
    Offset? look,
  }) {
    return MascotPose(
      dy: dy ?? this.dy,
      scaleX: scaleX,
      scaleY: scaleY,
      armLeft: armLeft ?? this.armLeft,
      armRight: armRight ?? this.armRight,
      blink: blink,
      tilt: tilt ?? this.tilt,
      mouth: mouth ?? this.mouth,
      burst: burst,
      look: look ?? this.look,
    );
  }

  static MascotPose lerp(MascotPose a, MascotPose b, double t) {
    return MascotPose(
      dy: lerpDouble(a.dy, b.dy, t)!,
      scaleX: lerpDouble(a.scaleX, b.scaleX, t)!,
      scaleY: lerpDouble(a.scaleY, b.scaleY, t)!,
      armLeft: lerpDouble(a.armLeft, b.armLeft, t)!,
      armRight: lerpDouble(a.armRight, b.armRight, t)!,
      blink: lerpDouble(a.blink, b.blink, t)!,
      tilt: lerpDouble(a.tilt, b.tilt, t)!,
      mouth: lerpDouble(a.mouth, b.mouth, t)!,
      burst: b.burst,
      look: Offset.lerp(a.look, b.look, t)!,
    );
  }
}

/// Respiração e flutuação contínuas: ciclo de 3,2 s, piscada a cada 4,4 s.
MascotPose idlePose(double seconds) {
  final phase = seconds * 2 * math.pi / 3.2;
  final breath = math.sin(phase);
  final armSwing = math.sin(phase - 0.6) * 0.05;
  final blinkClock = seconds % 4.4;
  final blink =
      blinkClock < 0.14 ? math.sin(blinkClock / 0.14 * math.pi) : 0.0;
  return MascotPose(
    dy: -3 * breath,
    scaleX: 1 - breath * 0.008,
    scaleY: 1 + breath * 0.015,
    armLeft: 0.06 + armSwing,
    armRight: 0.06 - armSwing,
    blink: blink,
    look: Offset(math.sin(seconds * 0.7) * 0.4, 0),
  );
}

/// Pensativo: olhar girando para cima, cabeça levemente inclinada e um braço
/// levantado.
MascotPose thinkingPose(double seconds) {
  return idlePose(seconds).copyWith(
    armRight: 0.7 + math.sin(seconds * 2.4) * 0.08,
    tilt: 0.06 + math.sin(seconds * 1.1) * 0.02,
    look: Offset(
      math.cos(seconds * 1.7) * 0.85,
      -0.55 + math.sin(seconds * 1.7) * 0.2,
    ),
  );
}

/// Aceno: braço erguido balançando, saltinhos e olhar de frente.
MascotPose wavingPose(double seconds) {
  final base = idlePose(seconds);
  return base.copyWith(
    dy: base.dy - 5 * math.sin(seconds * 6).abs(),
    armRight: 2.3 + math.sin(seconds * 10) * 0.35,
    tilt: -0.05 + math.sin(seconds * 3) * 0.03,
    mouth: 0.55,
    look: Offset.zero,
  );
}

/// Pulo de comemoração: agacha, salta com os braços para cima, abre a boca,
/// solta confete e amortece na aterrissagem. [seconds] conta desde o início.
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
  return MascotPose(
    dy: 6 * crouch * push - 48 * lift + 4 * impact,
    scaleX: 1 + squash * 0.6,
    scaleY: 1 - squash,
    armLeft: arms,
    armRight: arms,
    tilt: math.sin(math.pi * 2 * air) * 0.1 * lift,
    mouth: math.sin(math.pi * ((t - 0.05) / 1.2).clamp(0.0, 1.0)),
    burst: ((t - 0.3) / 1.15).clamp(0.0, 1.0),
    look: Offset(0, -0.6 * lift),
  );
}
