import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { FONT } from "../theme";
import { FPS, seg, SegName } from "../timeline";
import { useSpring } from "./Reveal";

const W: React.FC<{ text: string; at: number; color: string }> = ({ text, at, color }) => {
  const frame = useCurrentFrame();
  const p = useSpring(Math.round(at * FPS), 14, 140);
  const blur = interpolate(frame - at * FPS, [0, 8], [8, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <span style={{ display: "inline-block", marginRight: "0.28em", opacity: Math.min(1, p * 1.6), transform: `translateY(${(1 - p) * 0.35}em)`, filter: `blur(${blur}px)`, color }}>
      {text}
    </span>
  );
};

export const Words: React.FC<{ name: SegName; at: number; from: number; to: number; size: number; color: string; align?: "center" | "left"; weight?: number }> = ({ name, at, from, to, size, color, align = "center", weight = 800 }) => (
  <div style={{ fontFamily: FONT, fontWeight: weight, fontSize: size, lineHeight: 1.05, letterSpacing: -0.03 * size, textAlign: align, color }}>
    {seg(name).palavras.slice(from, to).map((w, i) => (
      <W key={i} text={w.w} at={at + w.start} color={color} />
    ))}
  </div>
);
