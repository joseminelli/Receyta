import React from "react";
import { AbsoluteFill, Img, staticFile } from "remotion";
import { Backdrop } from "./components/Backdrop";
import { Chip } from "./components/Chip";
import { Phone, phoneHeight } from "./components/Phone";
import { useLayout } from "./components/useLayout";
import { C, FONT } from "./theme";
import { useFont } from "./useFont";

const Screen: React.FC<{ src: string }> = ({ src }) => <Img src={staticFile(src)} style={{ width: "100%", height: "100%", objectFit: "cover" }} />;

const Slogan: React.FC<{ size: number; align: "center" | "left" }> = ({ size, align }) => (
  <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: size, lineHeight: 1.02, letterSpacing: -0.035 * size, textAlign: align, color: C.onInk }}>
    Suas receitas,
    <br />
    <span style={{ color: C.coral }}>num lugar só.</span>
  </div>
);

const Pill: React.FC<{ u: number }> = ({ u }) => (
  <div style={{ fontFamily: FONT, fontWeight: 800, fontSize: 52 * u, padding: `${24 * u}px ${68 * u}px`, borderRadius: 999, background: C.paper, color: C.ink, display: "inline-block" }}>Baixe agora</div>
);

export const Banner: React.FC = () => {
  useFont();
  const { width, height, vertical, u } = useLayout();
  const front = vertical ? width * 0.56 : (height * 0.82) / (phoneHeight(100) / 100);
  const back = front * 0.86;
  return (
    <AbsoluteFill style={{ background: C.ink }}>
      <Backdrop />
      {vertical ? (
        <>
          <AbsoluteFill style={{ alignItems: "center", paddingTop: 130 * u, gap: 56 * u }}>
            <Img src={staticFile("img/logoInverted.png")} style={{ width: 760 * u }} />
            <Slogan size={118 * u} align="center" />
            <Pill u={u} />
          </AbsoluteFill>
          <div style={{ position: "absolute", left: width * 0.5 - back * 1.02, top: height * 0.5, transform: "perspective(2200px) rotateY(14deg) rotate(-5deg)" }}>
            <Phone width={back}>
              <Screen src="img/home.png" />
            </Phone>
          </div>
          <div style={{ position: "absolute", left: width * 0.5 - front * 0.18, top: height * 0.47, transform: "perspective(2200px) rotateY(-10deg) rotate(4deg)" }}>
            <Phone width={front}>
              <Screen src="img/detalhe.png" />
            </Phone>
          </div>
          <Chip text="Lasanha de carne moída" delay={-60} u={u} style={{ left: 60 * u, top: height * 0.5 }} />
          <Chip text="Pasta: Jantas" delay={-60} u={u} phase={20} style={{ right: 50 * u, top: height * 0.435 }} />
          <Chip text="Amanhã · Almoço" delay={-60} u={u} phase={40} style={{ left: 90 * u, top: height * 0.78 }} />
          <div style={{ position: "absolute", left: -30 * u, bottom: 40 * u, width: 420 * u }}>
            <Img src={staticFile("img/clo_apresentando.png")} style={{ width: "100%" }} />
          </div>
        </>
      ) : (
        <>
          <AbsoluteFill style={{ justifyContent: "center", paddingLeft: 140 * u, gap: 54 * u, width: width * 0.55 }}>
            <Img src={staticFile("img/logoInverted.png")} style={{ width: 640 * u }} />
            <Slogan size={132 * u} align="left" />
            <div>
              <Pill u={u} />
            </div>
          </AbsoluteFill>
          <div style={{ position: "absolute", left: width * 0.58, top: height * 0.17, transform: "perspective(2200px) rotateY(12deg) rotate(-4deg)" }}>
            <Phone width={back}>
              <Screen src="img/home.png" />
            </Phone>
          </div>
          <div style={{ position: "absolute", left: width * 0.58 + back * 0.78, top: height * 0.1, transform: "perspective(2200px) rotateY(-10deg) rotate(3deg)" }}>
            <Phone width={front}>
              <Screen src="img/detalhe.png" />
            </Phone>
          </div>
          <Chip text="Lasanha de carne moída" delay={-60} u={u} style={{ left: width * 0.5, top: height * 0.22 }} />
          <Chip text="Pasta: Jantas" delay={-60} u={u} phase={20} style={{ left: width * 0.52, top: height * 0.7 }} />
          <div style={{ position: "absolute", left: width * 0.4, bottom: -20 * u, width: 330 * u }}>
            <Img src={staticFile("img/clo_apresentando.png")} style={{ width: "100%" }} />
          </div>
        </>
      )}
    </AbsoluteFill>
  );
};
