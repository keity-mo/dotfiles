#!/usr/bin/env bash
set -e
src="$1"; name="$2"
if [ ! -f "$src" ] || [ -z "$name" ]; then
  echo "Uso: add-live-wallpaper.sh /ruta/video.mp4 nombre"; exit 1
fi
case "$name" in *[!a-z0-9_-]*) echo "El nombre solo admite minúsculas, números, - y _"; exit 1;; esac
dest="$HOME/Vídeos/$name.mp4"
thumb="$HOME/Imágenes/Wallpapers/$name-live.png"
if [ -e "$dest" ]; then echo "Ya existe $dest, elige otro nombre"; exit 1; fi
ffmpeg -y -i "$src" -vf "scale='min(1920,iw)':-2,fps=30,format=yuv420p" \
  -c:v libx264 -crf 20 -preset slow -an -movflags +faststart "$dest"
ffmpeg -y -ss 0 -i "$dest" -frames:v 1 -update 1 -vf scale=1920:-2 "$thumb"
echo "Listo: elige $name-live.png en el selector (>wallpaper)"
