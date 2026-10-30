"""Probe: print the score delta and wave-kill count each time a kill happens during play."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def sc(): return bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
last_k = m[S["wWaveKills"]]; last = sc(); n = 0
for i in range(3000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    k = m[S["wWaveKills"]]
    if k != last_k:
        print("kill", k, "score", last, "->", sc(), "wavePts", m[S["wWavePoints"]] + 256 * m[S["wWavePoints"] + 1])
        last_k = k; last = sc(); n += 1
        if n >= 8: break
print("end wave", m[S["wWave"]], "flash", m[S["wMultFlash"]], "kind", m[S["wMultKind"]])
