"""Gera variações de um segmento (seeds diferentes) para escolher a melhor pronúncia."""
import base64
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_voz as g

nome = sys.argv[1]
texto = dict(g.SEGMENTOS)[nome]
k = g.chave()
voz = next(v["voice_id"] for v in g.chamar("https://api.elevenlabs.io/v1/voices", k)["voices"] if v["name"].startswith(g.VOICE_NAME))
pasta = g.AUDIO / "takes"
pasta.mkdir(parents=True, exist_ok=True)
for seed in (11, 22, 33):
    r = g.chamar(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voz}/with-timestamps",
        k,
        {"text": texto, "model_id": g.MODEL, "language_code": "pt", "seed": seed},
    )
    (pasta / f"{nome}_{seed}.mp3").write_bytes(base64.b64decode(r["audio_base64"]))
    (pasta / f"{nome}_{seed}.json").write_text(
        g.json.dumps({"texto": texto, "alinhamento": r["alignment"]}, ensure_ascii=False), encoding="utf-8"
    )
    print(seed, round(r["alignment"]["character_end_times_seconds"][-1], 2))
