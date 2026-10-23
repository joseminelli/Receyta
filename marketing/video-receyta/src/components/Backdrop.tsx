import React from "react";
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from "remotion";
import { C } from "../theme";

const Glow: React.FC<{ color: string; x: number; y: number; r: number; opacity: number }> = ({ color, x, y, r, opacity }) => (
  <div
    style={{
      position: "absolute",
      left: `${x}%`,
      top: `${y}%`,
      width: r,
      height: r,
      marginLeft: -r / 2,
      marginTop: -r / 2,
      borderRadius: "50%",
      background: `radial-gradient(circle, ${color} 0%, transparent 68%)`,
      opacity,
    }}
  />
);

export const Backdrop: React.FC = () => {
  const frame = useCurrentFrame();
  const { width, height } = useVideoConfig();
  const m = Math.max(width, height);
  const t = frame / 90;
  return (
    <AbsoluteFill style={{ background: `linear-gradient(160deg, #211F17 0%, ${C.ink} 55%, #100F0A 100%)`, overflow: "hidden" }}>
      <Glow color={C.violet} x={18 + Math.sin(t) * 8} y={14 + Math.cos(t * 0.8) * 6} r={m * 0.95} opacity={0.5} />
      <Glow color={C.coral} x={86 + Math.cos(t * 0.9) * 7} y={78 + Math.sin(t * 0.7) * 7} r={m * 0.9} opacity={0.42} />
      <Glow color={C.lime} x={72 + Math.sin(t * 0.6) * 10} y={8 + Math.cos(t) * 5} r={m * 0.45} opacity={0.14} />
      <AbsoluteFill style={{ backgroundImage: "radial-gradient(rgba(245,242,234,0.1) 2.5px, transparent 3px)", backgroundSize: "54px 54px" }} />
    </AbsoluteFill>
  );
};
