#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Fundo animado da splash (§9.7): tom sobre tom em `coral`, deliberadamente
// discreto — um fluxo lento domain-warped e um eco leve de anéis concêntricos
// da cúpula. A bandeja branca sempre domina; o fundo é só um respiro de vida,
// nunca um padrão que compete. `uTime` vem do progresso da animação.
uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

const vec3 CORAL    = vec3(1.000, 0.353, 0.220); // #FF5A38
const vec3 CORAL_LT = vec3(1.000, 0.478, 0.369); // #FF7A5E  (coralPattern)
const vec3 CORAL_DK = vec3(0.804, 0.243, 0.114); // coral mais fundo

float flow(vec2 p, float t) {
  float v = 0.0;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    p += 0.24 * vec2(
      sin(p.y * 2.0 + t * (0.7 + 0.14 * fi) + fi),
      cos(p.x * 2.0 - t * (0.5 + 0.10 * fi))
    );
    v += sin(length(p) * 3.4 - t * 1.0 + fi * 1.9);
  }
  return v / 3.0; // -1..1
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - 0.5 * uSize) / uSize.y;
  float t = uTime;

  float w = flow(p * 1.5, t);

  float r = length(p);
  float ring = sin(r * 7.0 - t * 1.4 + w * 1.4);

  // Sombra assinada: o fluxo domina, os anéis só temperam. Escuro puxa para
  // CORAL_DK, claro puxa (menos) para CORAL_LT.
  float shade = 0.80 * w + 0.20 * ring; // ~ -1..1

  vec3 col = CORAL;
  col = mix(col, CORAL_DK, clamp(-shade, 0.0, 1.0) * 0.32);
  col = mix(col, CORAL_LT, clamp( shade, 0.0, 1.0) * 0.24);

  // Centro mais calmo, não morto: mantém metade da variação no miolo (onde
  // fica a bandeja) e abre para a variação cheia nas bordas.
  float calm = smoothstep(0.0, 0.8, r);
  col = mix(CORAL, col, 0.5 + 0.5 * calm);

  fragColor = vec4(col, 1.0);
}
