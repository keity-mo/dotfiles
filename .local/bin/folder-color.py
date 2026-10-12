#!/usr/bin/env python3
import json, subprocess, os
p = os.path.expanduser("~/.local/state/caelestia/scheme.json")
h = json.load(open(p))["colours"]["primary"].lstrip("#")
rgb = tuple(int(h[i:i+2], 16) for i in (0, 2, 4))
C = {"blue":(82,148,226),"red":(229,57,53),"violet":(126,87,194),"teal":(0,150,136),"pink":(236,64,122),"orange":(251,140,0),"yellow":(253,216,53),"green":(102,187,106),"cyan":(0,188,212),"indigo":(63,81,181),"magenta":(171,71,188),"brown":(121,85,72),"carmine":(173,20,87),"deeporange":(255,87,34),"paleorange":(255,183,77),"bluegrey":(96,125,139)}
n = min(C, key=lambda k: sum((a-b)**2 for a, b in zip(C[k], rgb)))
subprocess.run(["papirus-folders", "-t", "Papirus-Caelestia", "-C", n], check=False)
subprocess.run(["gtk-update-icon-cache", "-f", os.path.expanduser("~/.local/share/icons/Papirus-Caelestia")], check=False)
print("carpetas ->", n)
