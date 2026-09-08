#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Fundo animado da splash (§9.7): três camadas em tons de `coral` — um fluxo
// domain-warped, anéis concêntricos que ecoam a cúpula, e uma ondulação
// diagonal fina por cima. Tom sobre tom: a bandeja branca sempre domina.
// `uTime` vem do progresso da animação, não de um relógio infinito.
uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

const vec3 CORAL    = vec3(1.000, 0.353, 0.220); // #FF5A38
const vec3 CORAL_LT = vec3(1.000, 0.478, 0.369); // #FF7A5E  (coralPattern)
const vec3 CORAL_DK = vec3(0.804, 0.243, 0.114); // coral mais fundo

float flow(vec2 p, float t) {
  float v = 0.0;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    p += 0.32 * vec2(
      sin(p.y * 2.4 + t * (1.0 + 0.20 * fi) + fi),
      cos(p.x * 2.4 - t * (0.8 + 0.15 * fi))
    );
    v += sin(length(p) * 4.6 - t * 1.7 + fi * 1.9);
  }
  return v / 4.0; // -1..1
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - 0.5 * uSize) / uSize.y;
  float t = uTime;

  float w = flow(p * 1.8, t);

  float r = length(p);
  float ring = sin(r * 15.0 - t * 2.6 + w * 2.2);
  ring = smoothstep(0.05, 0.85, abs(ring));

  float ripple = sin((p.x + p.y) * 20.0 + w * 3.0 - t * 3.2);

  float m = clamp(0.45 + 0.30 * w + 0.26 * ring + 0.09 * ripple, 0.0, 1.0);

  vec3 col = mix(CORAL_DK, CORAL, smoothstep(0.12, 0.58, m));
  col = mix(col, CORAL_LT, smoothstep(0.58, 1.0, m));

  // centro mais calmo: a bandeja precisa de ar
  float calm = smoothstep(0.0, 0.5, r);
  col = mix(mix(CORAL, CORAL_DK, 0.12), col, 0.34 + 0.66 * calm);

  fragColor = vec4(col, 1.0);
}
