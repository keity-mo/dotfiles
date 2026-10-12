#!/usr/bin/env bash
pgrep -x rofi >/dev/null || exit 0
L=$(hyprctl layers -j)
get() { printf "%s" "$L" | jq -r "[.. | objects | select(.namespace? == \"rofi\")][0] | .$1"; }
lx=$(get x); ly=$(get y); lw=$(get w); lh=$(get h)
[ -z "$lx" ] || [ "$lx" = "null" ] && exit 0
cx=$(hyprctl cursorpos -j | jq -r ".x | floor")
cy=$(hyprctl cursorpos -j | jq -r ".y | floor")
echo "$(date +%T) click cx=$cx cy=$cy capa=$lx,$ly,$lw,$lh" >> /tmp/rofi-click.log
if [ "$cx" -lt "$lx" ] || [ "$cx" -gt $((lx+lw)) ] || [ "$cy" -lt "$ly" ] || [ "$cy" -gt $((ly+lh)) ]; then
  pkill -x rofi
fi
