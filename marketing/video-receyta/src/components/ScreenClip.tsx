import React from "react";
import { AbsoluteFill, OffthreadVideo, staticFile } from "remotion";
import { CLIP_FRAMES } from "../timeline";

export const ScreenClip: React.FC<{ clip: keyof typeof CLIP_FRAMES }> = ({ clip }) => (
  <AbsoluteFill>
    <OffthreadVideo src={staticFile(`clips/${clip}.mp4`)} style={{ width: "100%", height: "100%", objectFit: "cover" }} muted />
  </AbsoluteFill>
);
