#!/usr/bin/env python3
"""bot.py ROM FRAMES [shotframes]: auto-plays (tracks nearest alien x, fires) and reports state."""
import sys, random; sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = sys.argv[1]; frames = int(sys.argv[2])
shots = [int(x) for x in sys.argv[3].split(",")] if len(sys.argv) > 3 else []
pb = make(rom); S = load_syms(rom); m = pb.memory
while m[S['wFrame']] < 20: pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
import os
CHEAT = os.environ.get('CHEAT') == '1'
rnd = random.Random(1); last = None; held = set(); stuck = 0; lastwave = -1
def hold(btns):
    global held
    for b in held - btns: pb.button_release(b)
    for b in btns - held: pb.button_press(b)
    held = btns
for f in range(frames):
    px = m[S["wPX"]]
    tgt = None; best = 999
    for i in range(14):
        a = S["wAliens"] + 16 * i
        if m[a] == 0x80:
            ax = m[a + 1]; d = abs(ax - px)
            if d < best: best, tgt = d, ax
    b = {"a"}
    if tgt is not None:
        if tgt > px + 3: b.add("right")
        elif tgt < px - 3: b.add("left")
    if f % 90 < 20: b.add("down")
    elif f % 90 < 40: b.add("up")
    hold(b)
    if CHEAT: m[S['wLives']] = 3
    pb.tick(1, f in shots)
    if f in shots: pb.screen.image.copy().resize((480, 432)).save(f"shots/bot_{f}.png")
    w = m[S["wWave"]]
    if w != lastwave:
        print("frame", f, "wave", w, "lives", m[S["wLives"]], "state", m[S["wState"]], "score", bytes(m[S["wScore"]:S["wScore"] + 7]).hex()); lastwave = w
print("end state", m[S["wState"]], "wave", m[S["wWave"]], "lives", m[S["wLives"]], "frame", m[S["wFrame"]])
print("PC", hex(pb.register_file.PC), "SP", hex(pb.register_file.SP), "IME?", pb.memory[0xFFFF])
for i in range(14):
    a = S["wAliens"] + 16 * i
    if m[a]:
        pl, ph = m[a+6], m[a+7]; p = pl | ph << 8
        print(i, [m[a+k] for k in range(16)], "path@", hex(p), [pb.memory[p+k] for k in range(24)] if p < 0x8000 else "")
