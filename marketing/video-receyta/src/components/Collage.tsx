import React from "react";
import { interpolate, useCurrentFrame } from "remotion";
import { loadFont } from "@remotion/google-fonts/Caveat";
import { C, FONT } from "../theme";
import { FPS } from "../timeline";
import { useSpring } from "./Reveal";

const hand = loadFont("normal", { weights: ["600"] }).fontFamily;

type Common = { at: number; k: number; fade: number; from: "left" | "right" | "bottom"; rot: number };

const clamp = { extrapolateLeft: "clamp", extrapolateRight: "clamp" } as const;

const Frame: React.FC<Common & { w: number; h: number; radius: number; bg: string; children: React.ReactNode; z: number }> = ({ at, k, fade, from, rot, w, h, radius, bg, children, z }) => {
  const frame = useCurrentFrame();
  const p = useSpring(Math.round(at * FPS), 11, 120);
  const dx = from === "left" ? -1400 : from === "right" ? 1400 : 0;
  const dy = from === "bottom" ? 1300 : 0;
  const idle = Math.sin((frame + z * 17) / 24) * 0.8;
  return (
    <div
      style={{
        position: "absolute",
        width: w * k,
        height: h * k,
        marginLeft: (-w * k) / 2,
        marginTop: (-h * k) / 2,
        borderRadius: radius * k,
        background: bg,
        overflow: "hidden",
        boxShadow: `0 ${26 * k}px ${60 * k}px rgba(0,0,0,0.5)`,
        opacity: Math.min(1, p * 2) * fade,
        transform: `translate(${(1 - p) * dx * k}px, ${(1 - p) * dy * k + (1 - fade) * 90 * k}px) rotate(${rot * p + idle}deg) scale(${1 - (1 - fade) * 0.25})`,
        filter: `blur(${(1 - fade) * 14}px)`,
        zIndex: z,
      }}
    >
      {children}
    </div>
  );
};

export const Screenshot: React.FC<Common & { cx: number; cy: number }> = ({ cx, cy, ...c }) => {
  const frame = useCurrentFrame();
  const flash = interpolate(frame - Math.round(c.at * FPS), [0, 2, 9], [0, 0.85, 0], clamp);
  const k = c.k;
  return (
    <div style={{ position: "absolute", left: cx, top: cy }}>
      <Frame {...c} w={470} h={840} radius={44} bg="#FFFFFF" z={1}>
        <div style={{ padding: `${26 * k}px ${30 * k}px`, fontFamily: FONT, fontWeight: 700, fontSize: 24 * k, color: "#16150F", display: "flex", justifyContent: "space-between" }}>
          <span>9:41</span>
          <span>5G ▮</span>
        </div>
        <div style={{ margin: `0 ${22 * k}px`, height: 330 * k, borderRadius: 26 * k, background: "linear-gradient(#F3C65B 0 22%, #E2762F 22% 46%, #F6E3A1 46% 58%, #C8492B 58% 82%, #F6E3A1 82%)" }} />
        <div style={{ margin: `${26 * k}px ${30 * k}px 0`, height: 34 * k, width: "74%", borderRadius: 12 * k, background: "#16150F" }} />
        <div style={{ margin: `${16 * k}px ${30 * k}px 0`, height: 18 * k, width: "46%", borderRadius: 9 * k, background: "#C9C5B8" }} />
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <div key={i} style={{ margin: `${22 * k}px ${30 * k}px 0`, display: "flex", alignItems: "center", gap: 14 * k }}>
            <div style={{ width: 20 * k, height: 20 * k, borderRadius: "50%", border: `${3 * k}px solid #C9C5B8` }} />
            <div style={{ height: 18 * k, width: `${78 - (i % 3) * 14}%`, borderRadius: 9 * k, background: "#E3DFD2" }} />
          </div>
        ))}
        <div style={{ position: "absolute", inset: 0, background: "#fff", opacity: flash }} />
      </Frame>
    </div>
  );
};

const NOTE = [
  { t: "Bolo da vovó", size: 62, y: 118 },
  { t: "3 ovos, 2 xíc. de açúcar", size: 46, y: 218 },
  { t: "1 xíc. de óleo (ou manteiga?)", size: 46, y: 292 },
  { t: "assar uns 40 min…", size: 46, y: 366 },
  { t: "não esquecer a cenoura!!", size: 46, y: 440 },
];

export const Notebook: React.FC<Common & { cx: number; cy: number }> = ({ cx, cy, ...c }) => {
  const frame = useCurrentFrame();
  const k = c.k;
  const t0 = Math.round(c.at * FPS) + 8;
  return (
    <div style={{ position: "absolute", left: cx, top: cy }}>
      <Frame {...c} w={560} h={700} radius={22} bg="#F8F1DD" z={2}>
        {Array.from({ length: 11 }).map((_, i) => (
          <div key={i} style={{ position: "absolute", left: 0, right: 0, top: (140 + i * 74) * k, height: 2 * k, background: "rgba(80,120,190,0.28)" }} />
        ))}
        <div style={{ position: "absolute", top: 0, bottom: 0, left: 92 * k, width: 3 * k, background: "rgba(255,90,56,0.45)" }} />
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} style={{ position: "absolute", left: 22 * k, top: (50 + i * 84) * k, width: 34 * k, height: 34 * k, borderRadius: "50%", background: "#16150F", opacity: 0.8 }} />
        ))}
        <div style={{ position: "absolute", left: 330 * k, top: 470 * k, width: 190 * k, height: 190 * k, borderRadius: "50%", border: `${10 * k}px solid rgba(120,70,30,0.18)` }} />
        {NOTE.map((n, i) => {
          const w = interpolate(frame, [t0 + i * 7, t0 + i * 7 + 16], [0, 100], clamp);
          return (
            <div key={i} style={{ position: "absolute", left: 112 * k, top: (n.y - n.size * 0.8) * k, fontFamily: hand, fontSize: n.size * k, color: "#2A3B6B", whiteSpace: "nowrap", clipPath: `inset(0 ${100 - w}% 0 0)`, transform: `rotate(${i % 2 ? -0.8 : 0.6}deg)` }}>
              {n.t}
            </div>
          );
        })}
        <svg style={{ position: "absolute", left: 112 * k, top: 134 * k }} width={330 * k} height={26 * k} viewBox="0 0 330 26" fill="none" stroke="#FF5A38" strokeWidth={5 * k} strokeLinecap="round">
          <path d="M4 14 C60 2, 110 24, 170 12 S280 6, 326 16" strokeDasharray="360" strokeDashoffset={interpolate(frame - t0, [14, 30], [360, 0], clamp)} />
        </svg>
      </Frame>
    </div>
  );
};

const URL_TEXT = "receitas-da-net.com.br/bolo-de-cenoura-v2?ref=feed&utm_source=…";

export const LinkBar: React.FC<Common & { cx: number; cy: number; brokenAt: number }> = ({ cx, cy, brokenAt, ...c }) => {
  const frame = useCurrentFrame();
  const k = c.k;
  const t0 = Math.round(c.at * FPS) + 6;
  const chars = Math.floor(interpolate(frame, [t0, t0 + 26], [0, URL_TEXT.length], clamp));
  const broken = interpolate(frame / FPS, [brokenAt, brokenAt + 0.18], [0, 1], clamp);
  return (
    <div style={{ position: "absolute", left: cx, top: cy }}>
      <Frame {...c} w={880} h={150} radius={75} bg="#FFFFFF" z={3}>
        <div style={{ display: "flex", alignItems: "center", gap: 22 * k, height: "100%", padding: `0 ${40 * k}px`, fontFamily: FONT, fontWeight: 600, fontSize: 31 * k }}>
          <svg width={50 * k} height={50 * k} viewBox="0 0 24 24" fill="none" stroke="#686555" strokeWidth="2" strokeLinecap="round">
            <circle cx="12" cy="12" r="9" />
            <path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18" />
          </svg>
          <span style={{ color: "#2F6FDE", textDecoration: "underline", whiteSpace: "nowrap", overflow: "hidden", flex: 1, opacity: 1 - broken * 0.7 }}>{URL_TEXT.slice(0, chars)}</span>
          <span style={{ background: C.coral, color: "#fff", fontWeight: 800, fontSize: 30 * k, padding: `${8 * k}px ${22 * k}px`, borderRadius: 999, opacity: broken, transform: `scale(${0.6 + broken * 0.4})` }}>404</span>
        </div>
      </Frame>
    </div>
  );
};
