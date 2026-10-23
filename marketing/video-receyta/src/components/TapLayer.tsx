import React from "react";
import { useCurrentFrame } from "remotion";
import { C } from "../theme";
import { FPS } from "../timeline";
import { TapDef } from "../stepsData";

const Ripple: React.FC<{ tap: TapDef; w: number; h: number }> = ({ tap, w, h }) => {
  const frame = useCurrentFrame();
  const age = frame - Math.round(tap[0] * FPS);
  if (age < 0 || age > 16) return null;
  const p = age / 16;
  const r = w * 0.085;
  return (
    <div style={{ position: "absolute", left: tap[1] * w - r, top: tap[2] * h - r, width: r * 2, height: r * 2, pointerEvents: "none" }}>
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", border: `${w * 0.008}px solid ${C.coral}`, opacity: 1 - p, transform: `scale(${0.35 + p * 1.1})` }} />
      <div style={{ position: "absolute", inset: r * 0.55, borderRadius: "50%", background: "rgba(255,255,255,0.65)", boxShadow: "0 0 0 2px rgba(22,21,15,0.25)", opacity: Math.max(0, 1 - p * 1.7), transform: `scale(${1 - p * 0.4})` }} />
    </div>
  );
};

export const TapLayer: React.FC<{ taps: TapDef[]; w: number; h: number; children: React.ReactNode }> = ({ taps, w, h, children }) => (
  <div style={{ position: "absolute", left: 0, top: 0, width: w, height: h }}>
    {children}
    {taps.map((tap, i) => (
      <Ripple key={i} tap={tap} w={w} h={h} />
    ))}
  </div>
);
