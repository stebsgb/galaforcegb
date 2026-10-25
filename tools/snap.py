#!/usr/bin/env python3
"""snap.py SCRIPT out_prefix frame,frame,... : run a button script and save screenshots at given frames."""
import sys; sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom, script, prefix, frames = sys.argv[1], sys.argv[2], sys.argv[3], [int(x) for x in sys.argv[4].split(",")]
pb = make(rom); syms = load_syms(rom)
f = 0
for item in script.split(","):
    n, b = item.split(":"); btns = [x.lower() for x in b.split("+") if x not in ("", "-")]
    for x in btns: pb.button_press(x)
    for _ in range(int(n)):
        pb.tick(1, True); f += 1
        if f in frames:
            pb.screen.image.copy().resize((480, 432)).save(f"{prefix}_{f}.png")
    for x in btns: pb.button_release(x)
print({k: pb.memory[syms[k]] for k in ("wState", "wWave", "wLives", "wFrame") if k in syms})
