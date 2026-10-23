import React from "react";
import { AbsoluteFill, Audio, Img, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Reveal, useSpring } from "../components/Reveal";
import { Words } from "../components/Words";
import { useLayout } from "../components/useLayout";
import { C, FONT } from "../theme";
import { f, FPS, SceneDef, seg } from "../timeline";

export const Cta: React.FC<{ scene: SceneDef }> = ({ scene }) => {
  const { vertical, u } = useLayout();
  const frame = useCurrentFrame();
  const at = 0.5;
  const s = seg("cta");
  const baixe = at + s.palavras[s.palavras.length - 2].start;
  const btn = useSpring(Math.round(baixe * FPS), 10, 120);
  const pulse = 1 + Math.sin(frame / 10) * 0.025 * Math.min(1, btn);
  const enter = interpolate(frame, [0, 14], [0, 1], { extrapolateRight: "clamp" });
  const end = interpolate(frame, [f(scene.length) - 10, f(scene.length)], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ opacity: enter * end }}>
      <Sequence from={f(at)}>
        <Audio src={staticFile("audio/cta.mp3")} />
      </Sequence>
      <AbsoluteFill style={{ flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 56 * u, padding: `0 ${90 * u}px` }}>
        <Reveal delay={Math.round(at * FPS)} dy={80}>
          <Img src={staticFile("img/logoInverted.png")} style={{ width: (vertical ? 820 : 760) * u }} />
        </Reveal>
        <Words name="cta" at={at} from={1} to={s.palavras.length - 2} size={(vertical ? 84 : 78) * u} color={C.onInk} align="center" />
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 800,
            fontSize: 56 * u,
            padding: `${26 * u}px ${72 * u}px`,
            borderRadius: 999,
            background: C.paper,
            color: C.ink,
            opacity: Math.min(1, btn * 1.5),
            transform: `scale(${(0.6 + btn * 0.4) * pulse})`,
          }}
        >
          Baixe agora
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
