#!/usr/bin/env bash
VIDEOS="$HOME/Vídeos"
WALLS="$HOME/Imágenes/Wallpapers"
shopt -s nullglob nocaseglob
n=0
for v in "$VIDEOS"/*.mp4; do
  name=$(basename "${v%.*}")
  out="$WALLS/${name}-live.png"
  if [ ! -f "$out" ] || [ "$v" -nt "$out" ]; then
    ffmpeg -y -loglevel error -i "$v" -frames:v 1 "$out" && n=$((n+1))
  fi
done
notify-send "Wallpapers animados" "Miniaturas generadas: $n" 2>/dev/null
