#!/usr/bin/env bash
f="$HOME/.local/state/caelestia/scheme.json"
out="$HOME/.config/rofi/caelestia-colors.rasi"
c() { jq -r ".colours.$1 // \"$2\"" "$f"; }
cat > "$out" <<EOF
* {
    bg:      #$(c surfaceContainerHighest 363648)66;
    field:   #$(c surfaceContainerHigh 2a2a3c)B3;
    sel:     #$(c secondaryContainer 3a3a55)CC;
    fg:      #$(c onSurfaceVariant b0b0c0)F2;
    fgvar:   #$(c onSurfaceVariant b0b0c0)99;
    accent:  #$(c primary a0c4ff);
    selfg:   #$(c onSecondaryContainer e0e0f0);
    selborder: #$(c primary a0c4ff)4D;
    outline: #$(c outlineVariant 50506a)99;
}
EOF
