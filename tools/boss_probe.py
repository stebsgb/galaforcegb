"""Watch for a boss (type 5) kill: report the sound id, whether the multiplier was paid for that pattern."""
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
boss_seen = False
for i in range(60000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wIsBossWave"]] and not boss_seen:
        boss_seen = True
        print("boss pattern detected at tick", i, "wave", m[S["wWave"]], "wWaveOff", m[S["wWaveOff"]])
    if boss_seen and m[S["wWaveOff"]] != 0 and m[S["wIsBossWave"]] == 0:
        print("left boss pattern; flag cleared")
        break
print("end: wave", m[S["wWave"]], "kind", m[S["wMultKind"]], "flash", m[S["wMultFlash"]], "bossflag", m[S["wIsBossWave"]])
