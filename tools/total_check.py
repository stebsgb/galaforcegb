"""At each pattern boundary of zone 0, print kills vs. total aliens spawned (children included)."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def w16(a): return m[S[a]] + 256 * m[S[a] + 1]
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
w0 = m[S["wWave"]]
last_off = m[S["wWaveOff"]]
prev = (0, 0)
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wWaveOff"]] != last_off and m[S["wWave"]] == w0:
        print("pattern", last_off, "kills", prev[0], "total", prev[1], "ok" if prev[0] == prev[1] else "MISMATCH")
        last_off = m[S["wWaveOff"]]
    if m[S["wWave"]] != w0:
        print("zone end: kills", prev[0], "total", prev[1], "ok" if prev[0] == prev[1] else "MISMATCH")
        break
    prev = (w16("wWaveKills"), w16("wWaveTotalAliens"))
