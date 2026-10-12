#!/usr/bin/env bash
~/.local/bin/caelestia-rofi-colors.sh
acc=$(jq -r ".colours.primary // \"a0c4ff\"" "$HOME/.local/state/caelestia/scheme.json")
cache="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
font="$HOME/.local/share/fonts-rofi/MSR.ttf"
mkdir -p "$cache"
find "$cache" -name "[0-9]*.png" -mtime +7 -delete
tile() {
  f="$cache/g-$acc-$1.png"
  [ -s "$f" ] || magick -size 96x96 xc:none -fill "#${acc}33" -draw "roundrectangle 0,0 95,95 20,20" -font "$font" -fill "#$acc" -pointsize 50 -gravity center -annotate +0+0 "$(printf "$2")" "$f"
  printf "%s" "$f"
}
ic_text=$(tile text "\ue14d")
ic_link=$(tile link "\ue157")
ic_img=$(tile image "\ue3f4")
list=$(cliphist -preview-width 80 list)
sel=$(
  while IFS="$(printf "\t")" read -r id text; do
    if [[ "$text" == "[[ binary data"* ]]; then
      f="$cache/$id.png"
      [ -s "$f" ] || printf "%s\t\n" "$id" | cliphist decode | magick - -thumbnail 96x96^ -gravity center -extent 96x96 \( -size 96x96 xc:none -fill white -draw "roundrectangle 0,0 95,95 20,20" \) -compose DstIn -composite "$f"
      [ -s "$f" ] || f="$ic_img"
      label="Imagen · ${text:15:${#text}-18}"
    elif [[ "$text" == http* ]]; then
      f="$ic_link"; label="$text"
    else
      f="$ic_text"; label="$text"
    fi
    printf "%s\t%s\0icon\x1f%s\n" "$id" "$label" "$f"
  done <<< "$list" | rofi -dmenu -i -no-custom -show-icons -p "$(printf "\ue8b6")" -theme ~/.config/rofi/caelestia.rasi -display-columns 2 -display-column-separator "\t"
)
if [ -n "$sel" ]; then
  printf "%s" "$sel" | cliphist decode | wl-copy; sleep 0.1; wtype -M ctrl -k v -m ctrl
fi
