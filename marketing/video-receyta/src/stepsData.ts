import { CLIP_FRAMES } from "./timeline";

export type TapDef = [number, number, number];
export type ChipDef = { text: string; fx: number; fy: number; delay: number };

export type StepDef = {
  id: "importar" | "detalhe" | "organizar" | "planejar" | "comprar" | "cozinhar";
  clip: keyof typeof CLIP_FRAMES;
  active: number;
  num: string;
  pre?: string;
  verb: string;
  chips: ChipDef[];
  taps: TapDef[];
};

export const STEP_DEFS: StepDef[] = [
  {
    id: "importar",
    clip: "importar",
    active: 0,
    num: "01",
    verb: "Importe",
    chips: [
      { text: "tudogostoso.com.br", fx: -0.3, fy: 0.12, delay: 30 },
      { text: "Receita encontrada", fx: 0.62, fy: 0.55, delay: 60 },
    ],
    taps: [[0.1, 0.77, 0.235], [0.7, 0.73, 0.355], [2.45, 0.93, 0.035]],
  },
  {
    id: "detalhe",
    clip: "detalhe",
    active: 0,
    num: "01",
    pre: "Receita",
    verb: "pronta",
    chips: [{ text: "50 min · 15 porções", fx: -0.3, fy: 0.3, delay: 20 }],
    taps: [[0.05, 0.5, 0.82]],
  },
  {
    id: "organizar",
    clip: "pasta",
    active: 1,
    num: "02",
    verb: "Organize",
    chips: [{ text: "Pasta: Jantas", fx: -0.28, fy: 0.2, delay: 25 }],
    taps: [[0.15, 0.45, 0.28], [0.95, 0.12, 0.2]],
  },
  {
    id: "planejar",
    clip: "planejar",
    active: 2,
    num: "03",
    verb: "Planeje",
    chips: [
      { text: "Amanhã · Almoço", fx: -0.3, fy: 0.25, delay: 30 },
      { text: "Agendada", fx: 0.6, fy: 0.62, delay: 70 },
    ],
    taps: [[0.15, 0.67, 0.54], [1.85, 0.33, 0.665], [2.3, 0.5, 0.93]],
  },
  {
    id: "comprar",
    clip: "lista",
    active: 3,
    num: "04",
    verb: "Compre",
    chips: [{ text: "Lista de 23/10", fx: -0.28, fy: 0.22, delay: 25 }],
    taps: [[1.9, 0.07, 0.24], [2.3, 0.07, 0.24]],
  },
  {
    id: "cozinhar",
    clip: "cozinha",
    active: 4,
    num: "05",
    verb: "Cozinhe",
    chips: [
      { text: "Tela sempre acesa", fx: -0.3, fy: 0.2, delay: 25 },
      { text: "Timer 3:00", fx: 0.6, fy: 0.6, delay: 60 },
    ],
    taps: [[0.02, 0.45, 0.94], [0.4, 0.55, 0.24], [0.78, 0.93, 0.17], [2.3, 0.43, 0.41]],
  },
];

export const CLIP_START_FRAMES = 6;
