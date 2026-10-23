#!/usr/bin/env bash
# Corta a barra de status, recorta o trecho útil, acelera e exporta cada clipe (com 1,5 s de último quadro repetido no fim) de tela em 1080 px de largura.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)/screensRecordings"
SAIDA="$(cd "$(dirname "$0")/.." && pwd)/public/clips"
mkdir -p "$SAIDA"

preparar() {
  local arquivo="$1" nome="$2" inicio="$3" fim="$4" vel="$5" extra="${6:-}"
  local filtro="trim=start=${inicio}:end=${fim},setpts=(PTS-STARTPTS)/${vel},fps=30"
  if [ -n "$extra" ]; then
    filtro="trim=start=${inicio}:end=${fim},setpts=PTS-STARTPTS,${extra},setpts=PTS/${vel},fps=30"
  fi
  ffmpeg -v error -y -i "$RAIZ/$arquivo" \
    -filter_complex "[0:v]${filtro},crop=1080:2228:0:112,tpad=stop_mode=clone:stop_duration=1.5,format=yuv420p[v]" \
    -map "[v]" -an -c:v libx264 -crf 18 -preset medium -movflags +faststart "$SAIDA/$nome.mp4"
  echo "$nome ok"
}

BORRAR="split[a][b];[b]crop=1080:900:0:1440,boxblur=40:6[bl];[a][bl]overlay=0:1440:enable='between(t,1.4,2.7)'[o];[o]null"

preparar "ImportandoLasanha.mp4" importar 1.0 11.5 3.4 "$BORRAR"
preparar "Detalhes lasanha.mp4" detalhe 1.0 10.0 3.2
preparar "ColocarLasanhaNaPasta.mp4" pasta 5.0 8.8 1.5
preparar "LasanhaAdicionandoNoPlanejamento.mp4" planejar 0.6 9.6 2.1
preparar "listaCompraCerto.mp4" lista 0.8 11.0 2.9
preparar "modoCozinha.mp4" cozinha 0.8 11.8 2.4
