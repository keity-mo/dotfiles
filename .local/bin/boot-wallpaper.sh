#!/bin/bash
p=$(cat ~/.local/state/caelestia/wallpaper/path.txt 2>/dev/null)
[ -f "$p" ] || exit 0
case "$p" in *.mp4|*.mkv|*.webm) exit 0;; esac
swaybg -i "$p" -m fill &
pid=$!
for i in $(seq 1 40); do sleep 0.5; qs list --all 2>/dev/null | grep -q "caelestia/shell.qml" && break; done
sleep 6
kill $pid
