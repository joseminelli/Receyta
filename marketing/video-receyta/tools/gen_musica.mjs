/* Sintetiza a trilha instrumental leve do vídeo (pad, baixo, arpejo e batida suave) em WAV estéreo. */
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const SR = 44100;
const DUR = Number(process.argv[2] ?? 46);
const BPM = 100;
const BEAT = 60 / BPM;
const BAR = BEAT * 4;
const N = Math.floor(SR * DUR);
const L = new Float32Array(N);
const R = new Float32Array(N);

const hz = (m) => 440 * Math.pow(2, (m - 69) / 12);
const CHORDS = [
  { root: 36, notes: [60, 64, 67, 72] },
  { root: 31, notes: [59, 62, 67, 71] },
  { root: 33, notes: [57, 60, 64, 69] },
  { root: 29, notes: [57, 60, 65, 69] },
];
const ARP = [0, 1, 2, 3, 2, 1, 2, 3];

const add = (start, len, fn, pan = 0) => {
  const a = Math.floor(start * SR);
  const n = Math.floor(len * SR);
  const gl = Math.cos(((pan + 1) * Math.PI) / 4);
  const gr = Math.sin(((pan + 1) * Math.PI) / 4);
  for (let i = 0; i < n && a + i < N; i++) {
    const v = fn(i / SR, i / n);
    L[a + i] += v * gl;
    R[a + i] += v * gr;
  }
};

const bars = Math.ceil(DUR / BAR);
for (let b = 0; b < bars; b++) {
  const ch = CHORDS[b % 4];
  const t0 = b * BAR;
  for (const [k, m] of ch.notes.entries()) {
    const f = hz(m);
    add(t0, BAR + 0.8, (t, p) => {
      const env = Math.min(1, t / 0.9) * Math.max(0, 1 - Math.max(0, t - BAR) / 0.8);
      const s = Math.sin(2 * Math.PI * f * t) + 0.4 * Math.sin(2 * Math.PI * f * 2.003 * t) + 0.18 * Math.sin(2 * Math.PI * f * 3.01 * t);
      return s * env * 0.05;
    }, k % 2 ? 0.45 : -0.45);
  }
  const rf = hz(ch.root);
  for (let q = 0; q < 2; q++) {
    add(t0 + q * 2 * BEAT, 1.6 * BEAT, (t) => Math.sin(2 * Math.PI * rf * t) * Math.exp(-t * 2.2) * 0.2 * Math.min(1, t / 0.01), 0);
  }
  if (b >= 1) {
    for (let e = 0; e < 8; e++) {
      const m = ch.notes[ARP[e]] + (e % 4 === 3 ? 12 : 0);
      const f = hz(m + 12);
      add(t0 + e * BEAT * 0.5, 0.9, (t) => (Math.sin(2 * Math.PI * f * t) + 0.35 * Math.sin(2 * Math.PI * f * 2 * t)) * Math.exp(-t * 6.5) * 0.085 * Math.min(1, t / 0.004), ((e % 5) - 2) * 0.25);
    }
  }
  if (b >= 2) {
    for (let q = 0; q < 4; q++) {
      const tk = t0 + q * BEAT;
      if (q % 2 === 0) add(tk, 0.28, (t) => Math.sin(2 * Math.PI * (48 + 70 * Math.exp(-t * 28)) * t) * Math.exp(-t * 11) * 0.28, 0);
      add(tk + BEAT * 0.5, 0.06, (t) => (Math.random() * 2 - 1) * Math.exp(-t * 70) * 0.05, 0.3);
    }
  }
}

let peak = 0;
for (let i = 0; i < N; i++) peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i]));
const g = 0.85 / peak;
const fadeIn = SR * 1.2;
const fadeOut = SR * 3.2;
const buf = Buffer.alloc(44 + N * 4);
buf.write("RIFF", 0);
buf.writeUInt32LE(36 + N * 4, 4);
buf.write("WAVEfmt ", 8);
buf.writeUInt32LE(16, 16);
buf.writeUInt16LE(1, 20);
buf.writeUInt16LE(2, 22);
buf.writeUInt32LE(SR, 24);
buf.writeUInt32LE(SR * 4, 28);
buf.writeUInt16LE(4, 32);
buf.writeUInt16LE(16, 34);
buf.write("data", 36);
buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  const env = Math.min(1, i / fadeIn) * Math.min(1, (N - i) / fadeOut);
  buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(L[i] * g * env * 32767))), 44 + i * 4);
  buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(R[i] * g * env * 32767))), 46 + i * 4);
}
const out = join(dirname(fileURLToPath(import.meta.url)), "..", "audio", "musica.wav");
writeFileSync(out, buf);
console.log(out);
