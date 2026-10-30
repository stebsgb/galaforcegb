"""Boss build: force the boss to 1 hit, shoot it, and trace the score, wBossFlash and the boss slot
for the frames after it dies. Shows whether the 2000 bonus repeats and whether the boss explosion restarts."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce_boss.gb"); S = load_syms("galaforce_boss.gb"); m = pb.memory
AL = S["wAliens"]
def sc(): return int(bytes(m[S["wScore"]:S["wScore"] + 7]).hex())
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
boss = None
for i in range(60000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    for c in range(0, 0xE0, 16):
        if m[AL + c] == 0x80 and m[AL + c + 3] == 5:
            boss = c
            break
    if boss is not None:
        m[AL + boss + 5] = 1     # AL_HITS: next hit kills it
        break
print("boss slot", hex(boss) if boss is not None else None, "score", sc())
trace = []
prev = sc()
for k in range(3000):
    if k % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    s = sc()
    st = m[AL + boss]
    if s != prev or st != 0x81 or m[S["wBossFlash"]]:
        trace.append((k, hex(st), s - prev, m[S["wBossFlash"]]))
    prev = s
    if st == 0 and k > 10:
        break
for t in trace[:40]:
    print("k", t[0], "state", t[1], "score delta", t[2], "flash", t[3])
print("bonus-like score jumps:", sum(1 for t in trace if t[2] >= 200), "end state", hex(m[AL + boss]))
