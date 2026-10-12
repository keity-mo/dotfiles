#!/usr/bin/env python3
import json, os, re, glob, shutil, colorsys, subprocess
home = os.path.expanduser("~")
src = "/usr/share/icons/Papirus-Dark"
dst = home + "/.local/share/icons/Papirus-Caelestia"
h = json.load(open(home + "/.local/state/caelestia/scheme.json"))["colours"]["primary"].lstrip("#")
th, ts, tv = colorsys.rgb_to_hsv(*[int(h[i:i+2], 16) / 255 for i in (0, 2, 4)])
pat = re.compile(r"#([0-9a-fA-F]{6})\b")
def recolor(text, min_s):
    def fix(m):
        c = m.group(1)
        hh, s, v = colorsys.rgb_to_hsv(*[int(c[i:i+2], 16) / 255 for i in (0, 2, 4)])
        if s < min_s:
            return m.group(0)
        r, g, b = colorsys.hsv_to_rgb(th, min(1.0, s * ts / 0.637), min(1.0, v * tv / 0.886))
        return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))
    return pat.sub(fix, text)
n = 0
for d in glob.glob(src + "/*/mimetypes"):
    out = os.path.join(dst, os.path.relpath(d, src))
    shutil.rmtree(out, ignore_errors=True)
    shutil.copytree(d, out, symlinks=False)
    for f in glob.glob(out + "/*.svg"):
        t = open(f).read()
        t2 = recolor(t, 0.3)
        if t2 != t:
            open(f, "w").write(t2)
            n += 1
for d in glob.glob(src + "/*/places"):
    for f in glob.glob(d + "/folder-blue*.svg"):
        out = os.path.join(dst, os.path.relpath(f, src))
        os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, "w").write(recolor(open(f).read(), 0.15))
        n += 1
subprocess.run(["papirus-folders", "-t", "Papirus-Caelestia", "-C", "blue"], check=False)
subprocess.run(["gtk-update-icon-cache", "-f", dst], check=False)
print("iconos recoloreados:", n)
