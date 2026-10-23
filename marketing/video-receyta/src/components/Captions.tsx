import React from "react";
import { useCurrentFrame } from "remotion";
import { C, FONT } from "../theme";
import { FPS, seg, SegName } from "../timeline";

export const Captions: React.FC<{ name: SegName; at: number; size: number; color?: string; align?: "center" | "left" }> = ({ name, at, size, color = C.onInk, align = "center" }) => {
  const t = useCurrentFrame() / FPS - at;
  return (
    <div style={{ fontFamily: FONT, fontWeight: 700, fontSize: size, lineHeight: 1.18, textAlign: align, color }}>
      {seg(name).palavras.map((w, i) => (
        <span key={i} style={{ opacity: t >= w.start - 0.02 ? 1 : 0.25 }}>
          {w.w}{" "}
        </span>
      ))}
    </div>
  );
};
