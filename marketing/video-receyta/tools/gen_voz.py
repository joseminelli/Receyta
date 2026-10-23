"""Gera a narração do vídeo do Receyta (ElevenLabs, Jessica + eleven_v3) com alinhamento por caractere."""
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AUDIO = ROOT / "audio"
VOICE_NAME = "Jessica"
MODEL = "eleven_v3"

SEGMENTOS = [
    ("intro", "Conheça o Receyta. O caderno de receitas que cabe no seu bolso."),
    ("problema", "Toda semana, a mesma pergunta: o que vamos comer? A receita tá num print, num caderno, num link que sumiu."),
    ("virada", "Mas cozinhar pode ser simples."),
    ("importar", "Cole o link, e a receita já vem pronta."),
    ("organizar", "Guarde em pastas do seu jeito."),
    ("planejar", "Escolha o dia e a refeição, e a semana se organiza."),
    ("comprar", "A lista de compras se monta sozinha."),
    ("cozinhar", "E na hora de cozinhar, a tela fica acesa, com timers em cada passo."),
    ("cta", "Receyta. Suas receitas, num lugar só. Baixe agora."),
]


def chave():
    k = os.environ.get("ELEVENLABS_API_KEY")
    if k:
        return k
    import winreg
    with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as reg:
        return winreg.QueryValueEx(reg, "ELEVENLABS_API_KEY")[0]


def chamar(url, k, corpo=None):
    req = urllib.request.Request(
        url,
        data=json.dumps(corpo).encode("utf-8") if corpo else None,
        headers={"xi-api-key": k, "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def main():
    k = chave()
    vozes = chamar("https://api.elevenlabs.io/v1/voices", k)["voices"]
    voz = next(v["voice_id"] for v in vozes if v["name"].startswith(VOICE_NAME))
    AUDIO.mkdir(parents=True, exist_ok=True)
    so = set(sys.argv[1:])
    for nome, texto in SEGMENTOS:
        if so and nome not in so:
            continue
        r = chamar(
            f"https://api.elevenlabs.io/v1/text-to-speech/{voz}/with-timestamps",
            k,
            {"text": texto, "model_id": MODEL, "language_code": "pt"},
        )
        (AUDIO / f"{nome}.mp3").write_bytes(base64.b64decode(r["audio_base64"]))
        (AUDIO / f"{nome}.json").write_text(
            json.dumps({"texto": texto, "alinhamento": r["alignment"]}, ensure_ascii=False),
            encoding="utf-8",
        )
        fim = r["alignment"]["character_end_times_seconds"][-1]
        print(f"{nome}: {fim:.2f}s")


if __name__ == "__main__":
    main()
