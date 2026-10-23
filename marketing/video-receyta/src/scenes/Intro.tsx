import React from "react";
import { AbsoluteFill, Audio, Img, interpolate, Sequence, staticFile, useCurrentFrame } from "remotion";
import { Captions } from "../components/Captions";
import { Chip } from "../components/Chip";
import { Phone, phoneHeight } from "../components/Phone";
import { Reveal, useSpring } from "../components/Reveal";
import { useLayout } from "../components/useLayout";
import { f, SceneDef } from "../timeline";

export const Intro: React.FC<{ scene: SceneDef }> = ({ scene }) => {
  const { width, height, vertical, u } = useLayout();
  const frame = useCurrentFrame();
  const rise = useSpring(10, 18, 70);
  const clo = useSpring(30, 9, 110);
  const exit = interpolate(frame, [f(scene.length) - 8, f(scene.length)], [1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  const phoneW = vertical ? width * 0.58 : (height * 0.95) / (phoneHeight(100) / 100);
  const phoneTop = vertical ? 800 * u : height * 0.1;
  const phoneLeft = vertical ? (width - phoneW) / 2 : width - phoneW - 200 * u;
  const logoW = (vertical ? 700 : 620) * u;
  const cap = scene.audio ? <Captions name={scene.audio} at={scene.audioAt ?? 0} size={(vertical ? 60 : 64) * u} align={vertical ? "center" : "left"} /> : null;
  const logo = (
    <Reveal>
      <Img src={staticFile("img/logoInverted.png")} style={{ width: logoW }} />
    </Reveal>
  );
  return (
    <AbsoluteFill style={{ opacity: exit }}>
      {scene.audio ? (
        <Sequence from={f(scene.audioAt ?? 0)}>
          <Audio src={staticFile(`audio/${scene.audio}.mp3`)} />
        </Sequence>
      ) : null}
      {vertical ? (
        <AbsoluteFill style={{ alignItems: "center", paddingTop: 130 * u }}>
          {logo}
          <div style={{ marginTop: 40 * u, padding: `0 ${90 * u}px` }}>{cap}</div>
        </AbsoluteFill>
      ) : (
        <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 150 * u, gap: 50 * u, width: width * 0.5 }}>
          {logo}
          {cap}
        </AbsoluteFill>
      )}
      <div style={{ position: "absolute", left: phoneLeft, top: phoneTop + (1 - rise) * 900 * u, transform: "perspective(2200px) rotateY(-8deg) rotateX(3deg)" }}>
        <Phone width={phoneW}>
          <Img src={staticFile("img/home.png")} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </Phone>
      </div>
      <div style={{ position: "absolute", left: phoneLeft, top: phoneTop }}>
        <Chip text="Lasanha de carne moída" delay={50} u={u} phase={0} style={{ left: -(vertical ? 230 : 330) * u, top: 150 * u }} />
        <Chip text="Bolo de cenoura" delay={60} u={u} phase={25} style={{ left: phoneW - (vertical ? 120 : 190) * u, top: 330 * u }} />
        <Chip text="Pasta: Jantas" delay={70} u={u} phase={50} style={{ left: -(vertical ? 160 : 260) * u, top: 560 * u }} />
      </div>
      <div style={{ position: "absolute", left: vertical ? 20 * u : phoneLeft - 520 * u, bottom: vertical ? 40 * u : 30 * u, width: 400 * u, transform: `translateY(${(1 - clo) * 400 * u}px) rotate(${(1 - clo) * -25}deg)` }}>
        <Img src={staticFile("img/clo_apresentando.png")} style={{ width: "100%" }} />
      </div>
    </AbsoluteFill>
  );
};
