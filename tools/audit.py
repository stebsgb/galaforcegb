"""Audit a god-mode bot run: dropped frames (wFrame vs ticks) and max sprites per scanline in OAM."""
import sys, warnings, os
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = sys.argv[1]; frames = int(sys.argv[2])
pb = make(rom); S = load_syms(rom); m = pb.memory
while m[S['wFrame']] < 20: pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
prev = m[S['wFrame']]; drops = 0; worst = 0; over10 = 0; held = set()
for f in range(frames):
    px = m[S["wPX"]]; tgt = None; best = 999
    for i in range(14):
        a = S["wAliens"] + 16 * i
        if m[a] == 0x80 and abs(m[a + 1] - px) < best: best, tgt = abs(m[a + 1] - px), m[a + 1]
    b = {"a"}
    if tgt is not None:
        if tgt > px + 3: b.add("right")
        elif tgt < px - 3: b.add("left")
    for x in held - b: pb.button_release(x)
    for x in b - held: pb.button_press(x)
    held = b
    pb.tick(1, False)
    cur = m[S["wFrame"]]
    if (cur - prev) & 255 != 1: drops += 1
    prev = cur
    cnt = [0] * 160
    for o in range(40):
        y = m[0xC000 + 4 * o]
        if 0 < y < 160:
            for l in range(y - 16, y):
                if 0 <= l < 144: cnt[l] += 1
    mx = max(cnt); worst = max(worst, mx)
    if mx > 10: over10 += 1
print(f"frames {frames} dropped {drops} max sprites/line {worst} frames-with-overflow {over10}")
