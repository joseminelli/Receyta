#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Fundo da splash (§9.7): tom sobre tom em `coral`, um fluxo lento domain-warped
// com um eco leve dos anéis da cúpula. A bandeja branca sempre domina. `uTime`
// vem do progresso da animação, não de um relógio infinito.
uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

const vec3 CORAL    = vec3(1.000, 0.353, 0.220);
const vec3 CORAL_LT = vec3(1.000, 0.478, 0.369);
const vec3 CORAL_DK = vec3(0.804, 0.243, 0.114);

float flow(vec2 p, float t) {
  float v = 0.0;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    p += 0.26 * vec2(
      sin(p.y * 2.0 + t * (0.7 + 0.14 * fi) + fi),
      cos(p.x * 2.0 - t * (0.5 + 0.10 * fi))
    );
    v += sin(length(p) * 3.4 - t * 1.0 + fi * 1.9);
  }
  return v / 2.2;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - 0.5 * uSize) / uSize.y;
  float t = uTime;

  float w = flow(p * 1.5, t);
  float r = length(p);
  float ring = sin(r * 7.0 - t * 1.4 + w * 1.4);

  float shade = clamp(0.82 * w + 0.20 * ring, -1.0, 1.0);

  vec3 col = CORAL;
  col = mix(col, CORAL_DK, clamp(-shade, 0.0, 1.0) * 0.50);
  col = mix(col, CORAL_LT, clamp( shade, 0.0, 1.0) * 0.34);

  float calm = smoothstep(0.0, 0.9, r);
  col = mix(CORAL, col, 0.68 + 0.32 * calm);

  fragColor = vec4(col, 1.0);
}
