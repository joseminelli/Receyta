#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
out vec4 fragColor;

// Fundo animado da splash (§9.7): tons de coral em movimento lento atrás da
// bandeja. Para ajustar a aparência, mexa só no PAINEL abaixo.

// ─────────────────────────  PAINEL DE AJUSTE  ─────────────────────────
// Depois de editar: hot restart (tecla R no `flutter run`) para recompilar.

const float INTENSITY   = 1.0;  // força do efeito. 0 = coral chapado, 1 = sutil, 2 = forte.
const float SPEED       = 1.0;   // velocidade do movimento. 0 = congelado.
const float SCALE       = 1.5;   // tamanho do padrão. maior = ondas menores.
const float RING_MIX    = 0.35;  // 0 = só o fluxo macio; 1 = só os anéis da cúpula.
const float CENTER_CALM = 0.55;  // miolo mais calmo que as bordas. 0 = uniforme, 1 = centro chapado.

const vec3 CORAL       = vec3(1.000, 0.353, 0.220); // base — #FF5A38
const vec3 CORAL_DARK  = vec3(0.706, 0.180, 0.063); // vale da onda — mais escuro = mais contraste
const vec3 CORAL_LIGHT = vec3(1.000, 0.560, 0.435); // crista da onda — mais claro = mais brilho
// ─────────────────────────────────────────────────────────────────────

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
  return v / 3.0;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 p = (frag - 0.5 * uSize) / uSize.y;
  float t = uTime * SPEED;
  float r = length(p);

  float w = flow(p * SCALE, t) * 2.4;
  float ring = sin(r * 7.0 - t * 1.4 + w * 1.2);
  float wave = mix(w, ring, RING_MIX);

  float calm = mix(1.0 - CENTER_CALM, 1.0, smoothstep(0.0, 0.95, r));
  float amt = wave * INTENSITY * calm;

  vec3 col = CORAL;
  col = mix(col, CORAL_DARK, clamp(-amt, 0.0, 1.0));
  col = mix(col, CORAL_LIGHT, clamp(amt, 0.0, 1.0));

  fragColor = vec4(col, 1.0);
}
