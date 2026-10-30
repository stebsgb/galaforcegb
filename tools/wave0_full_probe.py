"""Run wave 0 (first pattern run) to completion; log each kill's score delta and the wave-end bonus."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def sc(): return bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
def val(a): return m[S[a]] + 256 * m[S[a] + 1]
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
start_wave = m[S["wWave"]]
last_k = m[S["wWaveKills"]]; last = sc(); kills = []
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    k = m[S["wWaveKills"]]
    if k != last_k:
        kills.append((k, last, sc()))
        last_k = k; last = sc()
    if m[S["wWave"]] != start_wave:
        before = last
        pb.tick(1, False)
        print("wave ended at tick", i, "score before end-of-wave", before, "after", sc())
        print("kind", m[S["wMultKind"]], "flash", m[S["wMultFlash"]], "wavePts", val("wWavePoints"))
        break
    if m[S["wState"]] == 4:  # not in play anymore
        print("left play at tick", i, "state", m[S["wState"]])
        break
for k, a, b in kills:
    print("kill", k, a, "->", b)
print("total kills logged", len(kills), "final score", sc(), "wave", m[S["wWave"]], "state", m[S["wState"]])
