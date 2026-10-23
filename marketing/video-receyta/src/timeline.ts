import narration from "./narration.json";

export const FPS = 30;
export const f = (s: number) => Math.round(s * FPS);

export type SegName = keyof typeof narration;
export type Word = { w: string; start: number; end: number };

export const seg = (n: SegName) => narration[n] as { texto: string; duracao: number; palavras: Word[] };

export type SceneDef = {
  id: string;
  start: number;
  length: number;
  audio?: SegName;
  audioAt?: number;
};

const raw: Array<[string, number, SegName | null]> = [
  ["intro", 4.8, "intro"],
  ["problema", 9.6, "problema"],
  ["virada", 2.4, "virada"],
  ["importar", 3.6, "importar"],
  ["detalhe", 3.0, null],
  ["organizar", 3.0, "organizar"],
  ["planejar", 4.2, "planejar"],
  ["comprar", 3.6, "comprar"],
  ["cozinhar", 4.8, "cozinhar"],
  ["cta", 6.0, "cta"],
];

let acc = 0;
export const SCENES: Record<string, SceneDef> = {};
for (const [id, len, audio] of raw) {
  SCENES[id] = { id, start: acc, length: len, audio: audio ?? undefined, audioAt: 0.2 };
  acc += len;
}

export const TOTAL_SECONDS = acc;
export const BPM = 100;
export const BEAT = 60 / BPM;
export const TOTAL_FRAMES = f(acc);

export const CLIP_FRAMES: Record<string, number> = {
  importar: 92,
  detalhe: 83,
  pasta: 75,
  planejar: 124,
  lista: 104,
  cozinha: 136,
};
