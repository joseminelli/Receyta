import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { C, FONT } from "../theme";
import { useSpring } from "./Reveal";

export const Chip: React.FC<{ text: string; delay: number; u: number; phase?: number; exitAt?: number; style?: React.CSSProperties }> = ({ text, delay, u, phase = 0, exitAt, style }) => {
  const p = useSpring(delay, 12, 140);
  const frame = useCurrentFrame();
  const out = exitAt === undefined ? 1 : interpolate(frame, [exitAt - 8, exitAt], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const bob = Math.sin((frame + phase) / 14) * 8 * u;
  return (
    <div
      style={{
        position: "absolute",
        padding: `${16 * u}px ${28 * u}px`,
        borderRadius: 999,
        background: C.paper,
        border: `${3 * u}px solid ${C.ink}`,
        color: C.ink,
        fontFamily: FONT,
        fontWeight: 700,
        fontSize: 30 * u,
        whiteSpace: "nowrap",
        boxShadow: `0 ${10 * u}px ${24 * u}px rgba(22,21,15,0.18)`,
        opacity: Math.min(1, p * 1.5) * out,
        transform: `translateY(${bob + (1 - p) * 40 * u}px) scale(${0.7 + p * 0.3})`,
        ...style,
      }}
    >
      {text}
    </div>
  );
};
