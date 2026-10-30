"""Check the wave-end bonus: score and wave points one tick before the wave changes."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def sc(): return bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
def bcd(h): return int(h)
def wp(): return m[S["wWavePoints"]] + 256 * m[S["wWavePoints"] + 1]
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
w0 = m[S["wWave"]]
prev_sc, prev_wp = sc(), wp()
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wWave"]] != w0:
        print("before wave end: score", prev_sc, "wavePts", prev_wp, "kind", m[S["wMultKind"]])
        print("after  wave end: score", sc(), "kind", m[S["wMultKind"]], "flash", m[S["wMultFlash"]])
        print("score delta (BCD string as digits):", bcd(sc()) - bcd(prev_sc))
        break
    prev_sc, prev_wp = sc(), wp()
