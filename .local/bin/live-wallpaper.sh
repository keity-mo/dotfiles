#!/usr/bin/env bash
exec 9>/tmp/live-wallpaper.lock
flock -n 9 || exit 0

STATE="$HOME/.local/state/caelestia/wallpaper/path.txt"
CFG="$HOME/.config/caelestia/shell.json"
VIDEOS="$HOME/Vídeos"
MONITOR="eDP-1"

set_wallpaper_enabled() {
  python3 - "$CFG" "$1" <<'PY'
import json, sys
p, v = sys.argv[1], sys.argv[2] == "true"
d = json.load(open(p))
b = d.setdefault("background", {})
if b.get("wallpaperEnabled") != v:
    b["wallpaperEnabled"] = v
    json.dump(d, open(p, "w"), indent=4)
PY
}

last="__none__"
while true; do
  cur=$(basename "$(cat "$STATE" 2>/dev/null)")
  if [ "$cur" != "$last" ]; then
    last="$cur"
    if [[ "$cur" == *-live.png && -f "$VIDEOS/${cur%-live.png}.mp4" ]]; then
      video="$VIDEOS/${cur%-live.png}.mp4"
      if ! pgrep -f "mpvpaper .*$video" >/dev/null; then
        old=$(pgrep -x mpvpaper)
        setsid mpvpaper -o "no-audio --loop --hwdec=vaapi" "$MONITOR" "$video" >/dev/null 2>&1 9>&- &
        sleep 1.5 9>&-
        [ -n "$old" ] && kill $old 2>/dev/null
      fi
      set_wallpaper_enabled false
    else
      set_wallpaper_enabled true
      sleep 0.5 9>&-
      pkill -x mpvpaper
    fi
  fi
  sleep 0.5 9>&-
done
