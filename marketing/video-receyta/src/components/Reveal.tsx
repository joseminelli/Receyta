import React from "react";
import { interpolate, spring, useCurrentFrame, useVideoConfig } from "remotion";

export const useSpring = (delay = 0, damping = 16, stiffness = 120) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  return spring({ frame: frame - delay, fps, config: { damping, stiffness } });
};

export const Reveal: React.FC<{ delay?: number; dy?: number; children: React.ReactNode; style?: React.CSSProperties }> = ({ delay = 0, dy = 40, children, style }) => {
  const p = useSpring(delay);
  const frame = useCurrentFrame();
  const blur = interpolate(frame - delay, [0, 10], [10, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <div style={{ opacity: Math.min(1, p * 1.4), transform: `translateY(${(1 - p) * dy}px)`, filter: `blur(${blur}px)`, ...style }}>{children}</div>
  );
};
