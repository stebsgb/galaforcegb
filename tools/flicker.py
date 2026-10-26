"""flicker.py ROM [level] : boss-stage flicker metric (God build). Simulates the 10-objects-per-line cut on the real OAM
and reports, per alien, how long it stays hidden (consecutive frames) and the share of hidden alien-frames."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = sys.argv[1]; lvl = int(sys.argv[2]) if len(sys.argv) > 2 else 4
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
S = load_syms(rom); pb = make(rom); m = pb.memory
while m[S["wFrame"]] < 20: pb.tick(1, False)
def tap(b, n=6):
    pb.button_press(b); pb.tick(2, False); pb.button_release(b)
    for _ in range(n): pb.tick(1, False)
for _ in range(40): pb.tick(1, False)
tap("down"); tap("a", 90)
for k in ("up", "up", "down", "down", "select"): tap(k)
tap("up"); tap("up"); tap("down"); tap("down")
while m[S["wMenuSel"]] != 2: tap("up" if m[S["wMenuSel"]] > 2 else "down")
tap("down")  # LEVEL row (index 3); BG row is 2
for _ in range(lvl - 1): tap("right")
tap("b", 100); tap("up"); tap("start", 5)
A = S["wAliens"]
t0 = None; run = {}; longest = 0; hid = 0; tot = 0; hist = {}
for t in range(7000):
    pb.tick(1, False)
    if t % 2 == 0: pb.button_press("a")
    else: pb.button_release("a")
    if t0 is None:
        if m[S["wWave"]] == lvl - 1 and m[S["wWaveOff"]] >= 8 and m[S["wState"]] == 2: t0 = t
        continue
    if t - t0 > 900: break
    objs = [(m[0xC000 + 4 * o], m[0xC001 + 4 * o]) for o in range(40)]
    rank = []; cnt = {}
    for y, x in objs:
        r = []
        if 0 < y < 160:
            for l in range(y - 16, y):
                r.append(cnt.get(l, 0)); cnt[l] = cnt.get(l, 0) + 1
        rank.append(max(r) if r else 0)
    seen = set()
    for i in range(14):
        b = A + 16 * i
        if m[b] != 0x80: run.pop(i, None); continue
        ax = m[b + 1] + 8
        cand = [k for k, (y, x) in enumerate(objs) if x == ax and 0 < y < 160]
        if not cand: continue
        tot += 1
        hidden = all(rank[k] >= 10 for k in cand) is False and any(rank[k] >= 10 for k in cand) or False
        if any(rank[k] >= 10 for k in cand):
            hid += 1; run[i] = run.get(i, 0) + 1; longest = max(longest, run[i])
        else:
            if i in run: hist[run[i]] = hist.get(run[i], 0) + 1
            run[i] = 0
print("alien-frames", tot, "partly/fully hidden", hid, "(%.1f%%)" % (100 * hid / max(tot, 1)), "longest hidden run", longest)
print("hidden-run lengths", dict(sorted(hist.items())))
