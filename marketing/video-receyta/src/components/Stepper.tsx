import React from "react";
import { C, FONT } from "../theme";

const STEPS = ["Importar", "Organizar", "Planejar", "Comprar", "Cozinhar"];

const mix = (a: number) => {
  const r = Math.round(245 + (22 - 245) * a);
  const g = Math.round(242 + (21 - 242) * a);
  const b = Math.round(234 + (15 - 234) * a);
  return `rgba(${r},${g},${b},${0.6 + 0.4 * a})`;
};

export const Stepper: React.FC<{ pos: number; u: number }> = ({ pos, u }) => {
  const w = 190 * u;
  const gap = 14 * u;
  const h = 62 * u;
  return (
    <div style={{ position: "relative", display: "flex", gap, fontFamily: FONT }}>
      <div style={{ position: "absolute", left: 0, top: 0, width: w, height: h, borderRadius: 999, background: C.paper, transform: `translateX(${pos * (w + gap)}px)` }} />
      {STEPS.map((s, i) => (
        <div
          key={s}
          style={{
            position: "relative",
            width: w,
            height: h,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            borderRadius: 999,
            fontWeight: 700,
            fontSize: 28 * u,
            color: mix(Math.max(0, 1 - Math.abs(pos - i))),
            border: `${2 * u}px solid rgba(245,242,234,0.28)`,
            boxSizing: "border-box",
          }}
        >
          {s}
        </div>
      ))}
    </div>
  );
};
