import React from "react";
import { AbsoluteFill, Audio, interpolate, Sequence, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Captions } from "../components/Captions";
import { Chip } from "../components/Chip";
import { Phone, phoneHeight } from "../components/Phone";
import { Reveal } from "../components/Reveal";
import { ScreenClip } from "../components/ScreenClip";
import { Stepper } from "../components/Stepper";
import { useLayout } from "../components/useLayout";
import { TapLayer } from "../components/TapLayer";
import { CLIP_START_FRAMES, STEP_DEFS, StepDef } from "../stepsData";
import { C, FONT } from "../theme";
import { f, SCENES, SegName } from "../timeline";

type Pose = [number, number, number, number, number];

const POSES_V: Pose[] = [
  [0, 0, -5, 0, 1],
  [-40, 0, 6, -2, 1.04],
  [40, 0, -7, 2, 1],
  [-30, 0, 5, -1.5, 1.05],
  [30, 0, -6, 1.5, 1],
  [0, 0, 0, 0, 1.06],
];
const POSES_H: Pose[] = [
  [0, 0, -9, 0, 1],
  [-25, 0, 9, -2, 1.03],
  [25, 0, -10, 2, 1],
  [-20, 0, 8, -1.5, 1.04],
  [20, 0, -9, 1.5, 1],
  [0, 0, 0, 0, 1.05],
];

const Layer: React.FC<{ def: StepDef; len: number; w: number; h: number }> = ({ def, len, w, h }) => {
  const frame = useCurrentFrame();
  const fadeIn = interpolate(frame, [0, 8], [0, 1], { extrapolateRight: "clamp" });
  return (
    <AbsoluteFill style={{ opacity: fadeIn }}>
      <TapLayer taps={def.taps} w={w} h={h}>
        <ScreenClip clip={def.clip} />
      </TapLayer>
    </AbsoluteFill>
  );
};

const CaptionBlock: React.FC<{ name: SegName; at: number; len: number; u: number; vertical: boolean; box: React.CSSProperties }> = ({ name, at, len, u, vertical, box }) => {
  const frame = useCurrentFrame();
  const out = interpolate(frame, [len - 8, len], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ position: "absolute", opacity: out, ...box }}>
      <Captions name={name} at={at} size={(vertical ? 52 : 58) * u} align={vertical ? "center" : "left"} />
    </div>
  );
};

const Heading: React.FC<{ def: StepDef; len: number; u: number; vertical: boolean }> = ({ def, len, u, vertical }) => {
  const frame = useCurrentFrame();
  const out = interpolate(frame, [len - 8, len], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const size = (vertical ? 150 : 170) * u;
  return (
    <div style={{ fontFamily: FONT, color: C.onInk, opacity: out, transform: `translateY(${(1 - out) * -30 * u}px)`, filter: `blur(${(1 - out) * 8}px)` }}>
      <Reveal>
        <div style={{ fontWeight: 800, fontSize: 40 * u, color: C.lime, letterSpacing: 2 * u }}>{def.num}</div>
      </Reveal>
      <Reveal delay={4}>
        <div style={{ fontWeight: 800, fontSize: size, lineHeight: 1, letterSpacing: -4 * u }}>
          {def.pre ? <span style={{ fontSize: size * 0.5, display: "block", color: "rgba(245,242,234,0.6)", letterSpacing: 0 }}>{def.pre}</span> : null}
          <span style={{ color: C.coral }}>{def.verb}</span>
        </div>
      </Reveal>
    </div>
  );
};

export const Steps: React.FC<{ total: number }> = ({ total }) => {
  const { width, height, vertical, u } = useLayout();
  const { fps } = useVideoConfig();
  const frame = useCurrentFrame();
  const t0 = SCENES.importar.start;
  const starts = STEP_DEFS.map((d) => f(SCENES[d.id].start - t0));
  const lens = STEP_DEFS.map((d) => f(SCENES[d.id].length));
  const poses = vertical ? POSES_V : POSES_H;
  const phoneW = vertical ? width * 0.48 : (height * 0.86) / (phoneHeight(100) / 100);
  const ph = phoneHeight(phoneW);
  const inner = phoneW * (1 - 0.064);
  const screenH = (inner * 1486) / 720;
  const enter = spring({ frame, fps, config: { damping: 18, stiffness: 70 } });
  const exit = interpolate(frame, [total - 8, total], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });

  let pose: Pose = poses[0];
  let pos = STEP_DEFS[0].active;
  for (let i = 1; i < STEP_DEFS.length; i++) {
    const p = spring({ frame: frame - starts[i] + 2, fps, config: { damping: 18, stiffness: 90 } });
    pose = pose.map((v, k) => v + (poses[i][k] - v) * p) as Pose;
    pos += (STEP_DEFS[i].active - STEP_DEFS[i - 1].active) * p;
  }

  const phoneLeft = vertical ? (width - phoneW) / 2 : width - phoneW - 230 * u;
  const phoneTop = vertical ? 430 * u : (height - ph) / 2;
  return (
    <AbsoluteFill style={{ opacity: exit }}>
      {STEP_DEFS.map((d, i) =>
        SCENES[d.id].audio ? (
          <Sequence key={d.id} from={starts[i] + f(SCENES[d.id].audioAt ?? 0)}>
            <Audio src={staticFile(`audio/${SCENES[d.id].audio}.mp3`)} />
          </Sequence>
        ) : null,
      )}
      <div style={{ position: "absolute", left: vertical ? 90 * u : 130 * u, top: vertical ? 110 * u : height * 0.2 }}>
        {STEP_DEFS.map((d, i) => (
          <Sequence key={d.id} from={starts[i]} durationInFrames={lens[i]} layout="none">
            <div style={{ position: "absolute", left: 0, top: 0, width: 900 * u }}>
              <Heading def={d} len={lens[i]} u={u} vertical={vertical} />
            </div>
          </Sequence>
        ))}
      </div>
      {STEP_DEFS.map((d, i) =>
        SCENES[d.id].audio ? (
          <Sequence key={d.id} from={starts[i]} durationInFrames={lens[i]} layout="none">
            <CaptionBlock name={SCENES[d.id].audio!} at={SCENES[d.id].audioAt ?? 0} len={lens[i]} u={u} vertical={vertical} box={vertical ? { left: 90 * u, right: 90 * u, bottom: 210 * u } : { left: 130 * u, right: width - (phoneLeft - 120 * u), top: height * 0.58 }} />
          </Sequence>
        ) : null,
      )}
      <div style={{ position: "absolute", bottom: vertical ? 80 * u : 90 * u, left: vertical ? (width - 1006 * u * 0.8) / 2 : 130 * u }}>
        <Stepper pos={pos} u={u * 0.8} />
      </div>
      <div
        style={{
          position: "absolute",
          left: phoneLeft,
          top: phoneTop,
          width: phoneW,
          height: ph,
          transform: `translate(${pose[0] * u}px, ${pose[1] * u + (1 - enter) * 260 * u}px) perspective(2200px) rotateY(${pose[2]}deg) rotateX(2deg) rotateZ(${pose[3]}deg) scale(${pose[4]})`,
        }}
      >
        <Phone width={phoneW}>
          {STEP_DEFS.map((d, i) => (
            <Sequence key={d.id} from={starts[i] + CLIP_START_FRAMES} durationInFrames={lens[i] + 10} layout="none">
              <Layer def={d} len={lens[i]} w={inner} h={screenH} />
            </Sequence>
          ))}
        </Phone>
        {STEP_DEFS.map((d, i) => (
          <Sequence key={d.id} from={starts[i]} durationInFrames={lens[i]} layout="none">
            {d.chips.map((c, ci) => (
              <Chip key={c.text} text={c.text} delay={c.delay} u={u} phase={ci * 20} exitAt={lens[i]} style={{ left: `${c.fx * 100}%`, top: `${c.fy * 100}%` }} />
            ))}
          </Sequence>
        ))}
      </div>
    </AbsoluteFill>
  );
};
