"""Boss build (ZONE 04): trace the score and wBossFlash each frame once the flash starts.
A repeat payout shows as the score rising by 2000 (200 score units) on several frames in a row."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce_boss.gb"); S = load_syms("galaforce_boss.gb"); m = pb.memory
def sc(): return int(bytes(m[S["wScore"]:S["wScore"] + 7]).hex())
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
last_flash = 0
prev = sc()
rises = []
for i in range(60000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    fl = m[S["wBossFlash"]]
    s = sc()
    if fl > last_flash:
        print("flash set at tick", i, "score", prev, "->", s, "wave", m[S["wWave"]])
        rises = []
        track = 40
    if m[S["wBossFlash"]] and s != prev:
        rises.append((i, s - prev))
    prev = s
    last_flash = fl
    if rises and len(rises) > 60:
        break
print("score rises during flash:", rises[:12], "total rises", len(rises))
