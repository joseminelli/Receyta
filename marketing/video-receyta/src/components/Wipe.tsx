import React from "react";
import { AbsoluteFill, Easing, interpolate, Sequence, useCurrentFrame } from "remotion";
import { C } from "../theme";
import { f } from "../timeline";
import { useLayout } from "./useLayout";

const Band: React.FC = () => {
  const frame = useCurrentFrame();
  const { width, height } = useLayout();
  const p = interpolate(frame, [0, 18], [0, 1], { easing: Easing.inOut(Easing.cubic), extrapolateRight: "clamp" });
  const w = width * 0.55;
  const x = -w * 1.3 + p * (width + w * 1.6);
  return (
    <AbsoluteFill style={{ overflow: "hidden", pointerEvents: "none" }}>
      <div style={{ position: "absolute", top: -height * 0.1, height: height * 1.2, width: w, left: x, transform: "skewX(-14deg)", background: C.coral }} />
      <div style={{ position: "absolute", top: -height * 0.1, height: height * 1.2, width: w * 0.12, left: x - w * 0.16, transform: "skewX(-14deg)", background: C.onInk }} />
    </AbsoluteFill>
  );
};

export const Wipe: React.FC<{ at: number }> = ({ at }) => (
  <Sequence from={f(at) - 9} durationInFrames={20} layout="none">
    <Band />
  </Sequence>
);
