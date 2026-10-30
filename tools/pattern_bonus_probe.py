"""Log each pattern boundary in zone 0: wWaveOff changes, the bonus kind/flash, and the score."""
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
w0 = m[S["wWave"]]
last_off = m[S["wWaveOff"]]
last_flash = 0
prev_kind = m[S["wMultKind"]]
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    off = m[S["wWaveOff"]]
    if off != last_off and m[S["wWave"]] == w0:
        print("pattern boundary: wWaveOff", last_off, "->", off, "score", sc(), "wavePts", m[S["wWavePoints"]], "kills", m[S["wWaveKills"]])
        last_off = off
    if m[S["wWave"]] != w0:
        print("zone end: wave", w0, "->", m[S["wWave"]], "score", sc())
        break
    if m[S["wMultFlash"]] and m[S["wMultFlash"]] > last_flash:
        print("bonus flash started, kind", m[S["wMultKind"]], "score", sc())
    last_flash = m[S["wMultFlash"]]
