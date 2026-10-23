import { STEP_DEFS } from "./stepsData";
import { CLIP_START_FRAMES } from "./stepsData";
import { FPS, SCENES, seg } from "./timeline";

export type SfxEvent = { file: "whoosh" | "pop" | "tap" | "hit" | "err"; at: number; vol: number };

const VOL = { whoosh: 0.32, pop: 0.3, tap: 0.4, hit: 0.5, err: 0.25 } as const;
const ev = (file: SfxEvent["file"], at: number): SfxEvent => ({ file, at, vol: VOL[file] });

export const WIPES = [SCENES.problema.start, SCENES.importar.start, SCENES.cta.start];

export const sfxEvents = (): SfxEvent[] => {
  const out: SfxEvent[] = [];
  WIPES.forEach((w) => out.push(ev("whoosh", w - 0.15)));
  [50, 60, 70].forEach((d) => out.push(ev("pop", d / FPS)));

  const pa = SCENES.problema.start + (SCENES.problema.audioAt ?? 0);
  const pw = seg("problema").palavras;
  [12, 14, 16].forEach((i) => out.push(ev("pop", pa + pw[i].start)));
  out.push(ev("err", pa + pw[18].start));
  out.push(ev("hit", pa + pw[19].start));

  const va = SCENES.virada.start + (SCENES.virada.audioAt ?? 0);
  out.push(ev("hit", va + seg("virada").palavras[4].start - 0.1));

  const base = SCENES.importar.start;
  STEP_DEFS.forEach((d) => {
    const s = SCENES[d.id].start;
    d.chips.forEach((c) => out.push(ev("pop", s + c.delay / FPS)));
    d.taps.forEach((t) => out.push(ev("tap", s + CLIP_START_FRAMES / FPS + t[0])));
  });
  void base;

  const ca = SCENES.cta.start + 0.5;
  const cw = seg("cta").palavras;
  out.push(ev("pop", SCENES.cta.start + 0.55));
  out.push(ev("pop", ca + cw[cw.length - 2].start));
  return out.filter((e) => e.at >= 0);
};
