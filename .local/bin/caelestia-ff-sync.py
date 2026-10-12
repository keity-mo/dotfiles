#!/usr/bin/env python3
"""Genera caelestia-dynamic.css para Firefox a partir de scheme.json de Caelestia.

Uso:
  caelestia-ff-sync.py --print   muestra el CSS sin escribir nada
  caelestia-ff-sync.py           genera el archivo una vez
  caelestia-ff-sync.py --watch   vigila scheme.json y regenera al cambiar
"""
import json
import os
import shutil
import sys
import tempfile
import time

HOME = os.path.expanduser("~")
SRC = HOME + "/.local/state/caelestia/scheme.json"
OUT = HOME + "/.config/mozilla/firefox/4w2zdbit.default-release/chrome/caelestia-dynamic.css"
ALPHA = "cc"  # ~80 % de opacidad

MAP = [
    ("--toolbar-bgcolor", "surfaceContainer"),
    ("--toolbar-color", "onSurface"),
    ("--lwt-accent-color", "background"),
    ("--toolbarbutton-icon-fill", "onSurfaceVariant"),
    ("--lwt-toolbarbutton-icon-fill", "onSurfaceVariant"),
    ("--toolbarbutton-icon-fill-attention", "primary"),
    ("--lwt-toolbarbutton-icon-fill-attention", "primary"),
    ("--toolbarbutton-hover-background", "surfaceContainerHigh"),
    ("--toolbarbutton-active-background", "surfaceContainerHighest"),
    ("--toolbar-field-background-color", "background"),
    ("--toolbar-field-color", "onSurface"),
    ("--toolbar-field-focus-background-color", "surfaceContainer"),
    ("--toolbar-field-focus-color", "onSurface"),
    ("--toolbar-field-border-color", "outlineVariant"),
    ("--toolbar-field-focus-border-color", "primary"),
    ("--arrowpanel-background", "surfaceContainer"),
    ("--arrowpanel-color", "onSurface"),
    ("--arrowpanel-border-color", "outlineVariant"),
]

# (variable, clave de la paleta, porcentaje de opacidad)
TABS = [
    ("--tab-background-color-selected", "primaryContainer", 70),
    ("--tab-background-color-hover", "primary", 14),
]


def build():
    with open(SRC) as f:
        colours = json.load(f)["colours"]
    lines = []
    for var, key in MAP:
        if key in colours:
            lines.append("  %s: #%s !important;" % (var, colours[key]))
        else:
            sys.stderr.write("aviso: falta la clave %s, se omite %s\n" % (key, var))
    for var, key, pct in TABS:
        if key in colours:
            lines.append("  %s: color-mix(in srgb, #%s %d%%, transparent) !important;" % (var, colours[key], pct))
        else:
            sys.stderr.write("aviso: falta la clave %s, se omite %s\n" % (key, var))
    if "onPrimaryContainer" in colours:
        lines.append("  --tab-text-color-selected: #%s !important;" % colours["onPrimaryContainer"])
    surface = "#" + colours["surfaceContainer"] + ALPHA
    css = "/* Generado por caelestia-ff-sync.py, no editar a mano */\n"
    css += ":root:not([privatebrowsingmode=temporary]) {\n"
    css += "\n".join(lines) + "\n}\n"
    css += ":root[sidebar-expand-on-hover] #sidebar-container {\n"
    css += "  --sidebar-launcher-surface-color: %s !important;\n" % surface
    css += "  background-color: %s !important;\n" % surface
    css += "  backdrop-filter: blur(24px) !important;\n}\n"
    return css


def write(css):
    if os.path.exists(OUT):
        with open(OUT) as f:
            if f.read() == css:
                return False
        shutil.copy2(OUT, OUT + ".prev")
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(OUT))
    os.write(fd, css.encode())
    os.close(fd)
    os.chmod(tmp, 0o644)
    os.replace(tmp, OUT)
    return True


def main():
    if "--print" in sys.argv:
        print(build())
        return
    if "--watch" in sys.argv:
        last = None
        while True:
            try:
                mtime = os.stat(SRC).st_mtime
                if mtime != last:
                    last = mtime
                    if write(build()):
                        print("CSS actualizado")
            except Exception as e:
                sys.stderr.write("error: %s\n" % e)
            time.sleep(1)
    print("CSS actualizado" if write(build()) else "sin cambios")


main()
