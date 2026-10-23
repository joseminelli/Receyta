import React from "react";
import { C } from "../theme";

const RATIO = 1486 / 720;

export const phoneHeight = (width: number) => {
  const b = width * 0.032;
  const inner = width - b * 2;
  return b * 2 + inner * 0.075 + inner * RATIO;
};

const StatusBar: React.FC<{ h: number }> = ({ h }) => (
  <div style={{ height: h, background: C.ink, display: "flex", alignItems: "center", justifyContent: "space-between", padding: `0 ${h * 0.7}px`, color: C.onInk }}>
    <span style={{ fontWeight: 700, fontSize: h * 0.5 }}>9:41</span>
    <svg width={h * 1.9} height={h * 0.5} viewBox="0 0 38 10" fill={C.onInk}>
      <rect x="0" y="6" width="3" height="4" rx="1" />
      <rect x="5" y="4" width="3" height="6" rx="1" />
      <rect x="10" y="2" width="3" height="8" rx="1" />
      <rect x="15" y="0" width="3" height="10" rx="1" />
      <rect x="22" y="0.5" width="15" height="9" rx="2.5" fill="none" stroke={C.onInk} strokeWidth="1" />
      <rect x="23.5" y="2" width="12" height="6" rx="1.5" />
    </svg>
  </div>
);

export const Phone: React.FC<{ width: number; children: React.ReactNode; style?: React.CSSProperties }> = ({ width, children, style }) => {
  const b = width * 0.032;
  const inner = width - b * 2;
  const strip = inner * 0.075;
  const screenH = inner * RATIO;
  return (
    <div
      style={{
        width,
        height: phoneHeight(width),
        borderRadius: width * 0.13,
        background: C.ink,
        padding: b,
        boxSizing: "border-box",
        boxShadow: `0 ${width * 0.06}px ${width * 0.12}px rgba(0,0,0,0.55), 0 0 0 ${width * 0.006}px rgba(245,242,234,0.28)`,
        ...style,
      }}
    >
      <div style={{ borderRadius: width * 0.105, overflow: "hidden", background: C.ink }}>
        <StatusBar h={strip} />
        <div style={{ width: inner, height: screenH, position: "relative", overflow: "hidden" }}>{children}</div>
      </div>
    </div>
  );
};
