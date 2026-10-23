import React from "react";
import { AbsoluteFill, Audio, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Reveal } from "../components/Reveal";
import { useLayout } from "../components/useLayout";
import { C, FONT } from "../theme";
import { f, FPS, SceneDef, seg } from "../timeline";

const LINES = [0.08, 0.2, 0.34, 0.5, 0.66, 0.8, 0.92];

export const Virada: React.FC<{ scene: SceneDef }> = ({ scene }) => {
  const { width, height, u } = useLayout();
  const frame = useCurrentFrame();
  const at = scene.audioAt ?? 0;
  const simples = at + seg("virada").palavras[4].start;
  const t = frame / FPS;
  const spread = interpolate(t, [simples - 0.35, simples + 0.25], [0.9, -0.02], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const shown = interpolate(t, [simples - 0.35, simples - 0.2], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const exit = interpolate(frame, [f(scene.length) - 8, f(scene.length)], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const size = Math.min(width * 0.2, 280 * u);
  return (
    <AbsoluteFill style={{ opacity: exit }}>
      <Sequence from={f(at)}>
        <Audio src={staticFile("audio/virada.mp3")} />
      </Sequence>
      {LINES.map((x, i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            left: x * width,
            top: 0,
            width: 2 * u,
            height: height * interpolate(t, [0.1 + i * 0.04, 0.6 + i * 0.04], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" }),
            background: "rgba(245,242,234,0.12)",
          }}
        />
      ))}
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", gap: 20 * u }}>
        <Reveal delay={Math.round(at * FPS)}>
          <div style={{ fontFamily: FONT, fontWeight: 600, fontSize: 56 * u, color: "rgba(245,242,234,0.7)" }}>Mas cozinhar pode ser</div>
        </Reveal>
        <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: size, color: C.lime, letterSpacing: `${spread}em`, opacity: shown, lineHeight: 1 }}>Simples.</div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
