"""Converte o alinhamento por caractere do ElevenLabs em palavras com tempo e publica áudio e JSON para o Remotion."""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AUDIO = ROOT / "audio"
PUBLIC_AUDIO = ROOT / "public" / "audio"
SAIDA = ROOT / "src" / "narration.json"


def palavras(alinhamento):
    chars = alinhamento["characters"]
    ini = alinhamento["character_start_times_seconds"]
    fim = alinhamento["character_end_times_seconds"]
    out, atual = [], None
    for c, a, b in zip(chars, ini, fim):
        if c.isspace():
            if atual:
                out.append(atual)
                atual = None
            continue
        if atual is None:
            atual = {"w": c, "start": a, "end": b}
        else:
            atual["w"] += c
            atual["end"] = b
    if atual:
        out.append(atual)
    return out


def main():
    PUBLIC_AUDIO.mkdir(parents=True, exist_ok=True)
    dados = {}
    for j in sorted(AUDIO.glob("*.json")):
        nome = j.stem
        conteudo = json.loads(j.read_text(encoding="utf-8"))
        ws = palavras(conteudo["alinhamento"])
        dados[nome] = {"texto": conteudo["texto"], "duracao": ws[-1]["end"], "palavras": ws}
        shutil.copy(AUDIO / f"{nome}.mp3", PUBLIC_AUDIO / f"{nome}.mp3")
    SAIDA.parent.mkdir(parents=True, exist_ok=True)
    SAIDA.write_text(json.dumps(dados, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"{len(dados)} segmentos")


if __name__ == "__main__":
    main()
