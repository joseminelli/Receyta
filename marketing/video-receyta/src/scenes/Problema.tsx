import React from "react";
import { AbsoluteFill, Audio, Img, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { LinkBar, Notebook, Screenshot } from "../components/Collage";
import { Words } from "../components/Words";
import { useSpring } from "../components/Reveal";
import { useLayout } from "../components/useLayout";
import { C } from "../theme";
import { f, FPS, SceneDef, seg } from "../timeline";

const ramp = (t: number, a: number, b: number, from: number, to: number) => interpolate(t, [a, b], [from, to], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

export const Problema: React.FC<{ scene: SceneDef }> = ({ scene }) => {
  const { width, height, vertical, u } = useLayout();
  const frame = useCurrentFrame();
  const t = frame / FPS;
  const at = scene.audioAt ?? 0;
  const s = seg("problema");
  const wt = (i: number) => at + s.palavras[i].start;
  const phaseB = wt(9) - 0.25;
  const sumiu = wt(19);
  const aOut = ramp(t, phaseB, phaseB + 0.4, 1, 0);
  const bIn = ramp(t, phaseB, phaseB + 0.3, 0, 1);
  const fade = ramp(t, sumiu - 0.05, sumiu + 0.5, 1, 0);
  const exit = interpolate(frame, [f(scene.length) - 8, f(scene.length)], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const clo = useSpring(Math.round(wt(5) * FPS), 10, 110);
  const big = (vertical ? 118 : 120) * u;
  const align = vertical ? "left" : "center";
  const k = vertical ? u : u * 0.62;
  const pos = vertical
    ? { print: [0.3 * width, 0.4 * height], note: [0.69 * width, 0.5 * height], link: [0.5 * width, 0.76 * height] }
    : { print: [0.27 * width, 0.5 * height], note: [0.5 * width, 0.44 * height], link: [0.73 * width, 0.6 * height] };
  return (
    <AbsoluteFill style={{ opacity: exit }}>
      <Sequence from={f(at)}>
        <Audio src={staticFile("audio/problema.mp3")} />
      </Sequence>
      <AbsoluteFill style={{ opacity: aOut, justifyContent: "center", padding: `0 ${90 * u}px`, transform: `translateY(${(1 - aOut) * -60 * u}px)` }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 30 * u, alignItems: vertical ? "flex-start" : "center" }}>
          <Words name="problema" at={at} from={0} to={5} size={big * 0.78} color={C.onInk} align={align} />
          <Words name="problema" at={at} from={5} to={9} size={big * 1.55} color={C.coral} align={align} />
        </div>
      </AbsoluteFill>
      <div style={{ position: "absolute", right: 30 * u, bottom: 90 * u, width: 360 * u, opacity: aOut, transform: `translateY(${(1 - clo) * 300 * u}px)` }}>
        <Img src={staticFile("img/clo_pensando.png")} style={{ width: "100%" }} />
      </div>
      <AbsoluteFill style={{ opacity: bIn }}>
        <Screenshot cx={pos.print[0]} cy={pos.print[1]} at={wt(12)} k={k} fade={fade} from="left" rot={-7} />
        <Notebook cx={pos.note[0]} cy={pos.note[1]} at={wt(14)} k={k} fade={fade} from="right" rot={5} />
        <LinkBar cx={pos.link[0]} cy={pos.link[1]} at={wt(16)} k={k} fade={fade} from="bottom" rot={-2} brokenAt={wt(18)} />
      </AbsoluteFill>
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", opacity: ramp(t, sumiu, sumiu + 0.2, 0, 1) }}>
        <Words name="problema" at={at} from={19} to={20} size={260 * u} color={C.coral} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
