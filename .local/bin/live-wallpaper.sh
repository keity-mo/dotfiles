#!/usr/bin/env bash
exec 9>/tmp/live-wallpaper.lock
flock -n 9 || exit 0

STATEDIR="$HOME/.local/state/caelestia/wallpaper"
STATE="$STATEDIR/path.txt"
FLAG="$STATEDIR/live-active"   # nombre de la miniatura *-live.png que mpvpaper muestra ("" = ninguna)
CFG="$HOME/.config/caelestia/shell.json"
VIDEOS="$HOME/Vídeos"
MONITOR="eDP-1"

# Al volver a un fondo estático, tiempo antes de cerrar mpvpaper (el estático ya lo cubre).
POST_DELAY=0.8

set_flag() {
  mkdir -p "$STATEDIR"
  printf '%s' "$1" > "$FLAG"
}

# Garantiza wallpaperEnabled=true (solo escribe si hace falta)
ensure_wallpaper_enabled() {
  python3 - "$CFG" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
b = d.setdefault("background", {})
if b.get("wallpaperEnabled") is not True:
    b["wallpaperEnabled"] = True
    json.dump(d, open(p, "w"), indent=4)
PY
}

# Envía un comando JSON al socket IPC de mpv y imprime el campo "data" de la respuesta
mpv_ipc() {
  python3 - "$1" "$2" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX)
s.settimeout(1.0)
try:
    s.connect(sys.argv[1])
    s.sendall((sys.argv[2] + "\n").encode())
    buf = b""
    while True:
        while b"\n" not in buf:
            d = s.recv(4096)
            if not d:
                sys.exit(0)
            buf += d
        line, buf = buf.split(b"\n", 1)
        try:
            m = json.loads(line)
        except Exception:
            continue
        if "error" in m:
            print(json.dumps(m.get("data")))
            break
except Exception:
    sys.exit(1)
PY
}

# Espera a que mpv tenga el primer fotograma listo (máx. ~6 s)
wait_ready() {
  local i
  for i in $(seq 1 60); do
    [ "$(mpv_ipc "$1" '{"command":["get_property","vo-configured"]}' 2>/dev/null)" = "true" ] && return 0
    sleep 0.1 9>&-
  done
  return 1
}

# Espera un cambio en la carpeta de estado (inotify = 0 consumo en reposo).
# Si inotify-tools no está instalado, cae a sondeo cada 0.5 s.
if command -v inotifywait >/dev/null 2>&1; then
  wait_change() { inotifywait -qq -t 30 -e close_write,moved_to,create "$STATEDIR" 9>&- 2>/dev/null; }
else
  wait_change() { sleep 0.5 9>&-; }
fi

ensure_wallpaper_enabled
set_flag ""

last="__none__"
while true; do
  cur=$(basename "$(cat "$STATE" 2>/dev/null)")
  if [ "$cur" != "$last" ]; then
    last="$cur"
    if [[ "$cur" == *-live.png && -f "$VIDEOS/${cur%-live.png}.mp4" ]]; then
      video="$VIDEOS/${cur%-live.png}.mp4"
      if pgrep -f "mpvpaper .*$video" >/dev/null; then
        # Ya se está reproduciendo ese video
        set_flag "$cur"
      else
        old=$(pgrep -x mpvpaper)

        sock="/tmp/mpvpaper-live-$$-$RANDOM.sock"
        rm -f "$sock"
        # Arranca PAUSADO en el primer fotograma (idéntico a la miniatura), debajo del fondo estático
        setsid mpvpaper -o "no-audio --loop --hwdec=vaapi --panscan=1.0 --pause --input-ipc-server=$sock" "$MONITOR" "$video" >/dev/null 2>&1 9>&- &
        wait_ready "$sock"
        sleep 0.15 9>&-

        # El anterior ya no se ve (el fondo estático lo cubre): cerrarlo
        [ -n "$old" ] && kill $old 2>/dev/null

        # Relevo: Caelestia oculta su fondo estático y queda al descubierto el primer fotograma
        set_flag "$cur"
        sleep 0.25 9>&-

        # Ahora sí, reproducir
        mpv_ipc "$sock" '{"command":["set_property","pause",false]}' >/dev/null 2>&1
      fi
    else
      # Fondo estático: Caelestia lo muestra de inmediato; luego se cierra mpvpaper
      set_flag ""
      sleep "$POST_DELAY" 9>&-
      pkill -x mpvpaper
    fi
    continue
  fi
  wait_change
done
