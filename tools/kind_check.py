"""Log wMultKind and the HUD tiles while the bonus flash is on, for the 100%-kill pattern."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
w0 = m[S["wWave"]]
last_flash = 0
seen = set()
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    fl = m[S["wMultFlash"]]
    if fl and fl > last_flash:
        seen.add(m[S["wMultKind"]])
        print("flash start: kind", m[S["wMultKind"]], "wave", m[S["wWave"]], "kills", m[S["wWaveKills"]], "total", m[S["wWaveTotalAliens"]])
    last_flash = fl
    if m[S["wWave"]] != w0:
        break
print("kinds seen", sorted(seen))
