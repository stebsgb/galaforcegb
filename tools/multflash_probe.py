"""Probe: after a wave multiplier fires, does the game keep running? Prints PC and frame counters."""
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
for i in range(4000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wMultFlash"]]:
        break
print("flash set at tick", i, "wFrame", m[S["wFrame"]], "state", m[S["wState"]])
for k in range(6):
    pb.tick(1, False)
    print("tick", k, "wFrame", m[S["wFrame"]], "flash", m[S["wMultFlash"]], "kills", m[S["wWaveKills"]], "state", m[S["wState"]])
