/* Sintetiza os efeitos sonoros do vídeo (whoosh, pop, toque, impacto) em WAV mono. */
import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const SR = 44100;
const pasta = join(dirname(fileURLToPath(import.meta.url)), "..", "public", "audio", "sfx");
mkdirSync(pasta, { recursive: true });

const wav = (nome, dur, fn) => {
  const n = Math.floor(SR * dur);
  const d = new Float32Array(n);
  for (let i = 0; i < n; i++) d[i] = fn(i / SR, i / n);
  let peak = 0;
  for (const v of d) peak = Math.max(peak, Math.abs(v));
  const g = 0.9 / (peak || 1);
  const buf = Buffer.alloc(44 + n * 2);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + n * 2, 4);
  buf.write("WAVEfmt ", 8);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(1, 22);
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 2, 28);
  buf.writeUInt16LE(2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write("data", 36);
  buf.writeUInt32LE(n * 2, 40);
  for (let i = 0; i < n; i++) buf.writeInt16LE(Math.round(Math.max(-1, Math.min(1, d[i] * g)) * 32767), 44 + i * 2);
  writeFileSync(join(pasta, `${nome}.wav`), buf);
  console.log(nome);
};

const rnd = () => Math.random() * 2 - 1;

{
  let low = 0;
  let band = 0;
  wav("whoosh", 0.7, (t, p) => {
    const fc = 250 + 3200 * Math.sin(Math.PI * p) ** 1.5;
    const f = 2 * Math.sin((Math.PI * fc) / SR);
    const x = rnd();
    low += f * band;
    const high = x - low - 0.35 * band;
    band += f * high;
    return band * Math.sin(Math.PI * p) ** 1.4;
  });
}

wav("pop", 0.2, (t) => Math.sin(2 * Math.PI * (260 + 520 * Math.exp(-t * 38)) * t) * Math.exp(-t * 22));

wav("tap", 0.1, (t) => (Math.sin(2 * Math.PI * 1500 * t) * 0.6 + rnd() * 0.4) * Math.exp(-t * 85));

wav("hit", 0.7, (t) => Math.sin(2 * Math.PI * (48 + 90 * Math.exp(-t * 18)) * t) * Math.exp(-t * 6.5) + rnd() * Math.exp(-t * 60) * 0.35);

wav("err", 0.35, (t) => (Math.sin(2 * Math.PI * 190 * t) + Math.sin(2 * Math.PI * 200 * t)) * Math.exp(-t * 9) * (t < 0.12 ? 1 : 0.6));
