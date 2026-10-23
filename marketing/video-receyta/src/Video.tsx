import React from "react";
import { AbsoluteFill, Audio, Sequence, staticFile } from "remotion";
import { Backdrop } from "./components/Backdrop";
import { Cta } from "./scenes/Cta";
import { Intro } from "./scenes/Intro";
import { Problema } from "./scenes/Problema";
import { Steps } from "./scenes/Steps";
import { Virada } from "./scenes/Virada";
import { C, FONT } from "./theme";
import { useFont } from "./useFont";
import { f, SCENES } from "./timeline";
import { Wipe } from "./components/Wipe";
import { sfxEvents, WIPES } from "./sfx";

const STEPS_FRAMES = f(SCENES.cta.start - SCENES.importar.start);

const slot = (id: string, node: React.ReactNode) => (
  <Sequence key={id} from={f(SCENES[id].start)} durationInFrames={f(SCENES[id].length)} layout="none">
    {node}
  </Sequence>
);

export const Video: React.FC = () => {
  useFont();
  return (
    <AbsoluteFill style={{ background: C.ink, fontFamily: FONT }}>
      <Backdrop />
      <Audio src={staticFile("audio/musica.mp3")} volume={0.2} />
      {slot("intro", <Intro scene={SCENES.intro} />)}
      {slot("problema", <Problema scene={SCENES.problema} />)}
      {slot("virada", <Virada scene={SCENES.virada} />)}
      <Sequence from={f(SCENES.importar.start)} durationInFrames={STEPS_FRAMES} layout="none">
        <Steps total={STEPS_FRAMES} />
      </Sequence>
      {slot("cta", <Cta scene={SCENES.cta} />)}
      {WIPES.map((w) => (
        <Wipe key={w} at={w} />
      ))}
      {sfxEvents().map((e, i) => (
        <Sequence key={i} from={Math.round(e.at * 30)} layout="none">
          <Audio src={staticFile(`audio/sfx/${e.file}.wav`)} volume={e.vol} />
        </Sequence>
      ))}
    </AbsoluteFill>
  );
};
