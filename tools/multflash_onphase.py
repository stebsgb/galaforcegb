"""Capture the HUD during the ON phase of the X2/X5 blink and check the tiles."""
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
for k in range(40):
    pb.tick(1, True)
    if m[S["wMultFlash"]] and (m[S["wMultFlash"]] & 8):
        cols = [m[0x9800 + 32 + c] for c in (8, 9, 10, 11)]
        print("ON phase flash", m[S["wMultFlash"]], "cols 8-11", cols)
        pb.screen.image.copy().resize((480, 432)).save("shots/multflash_on.png")
        break
print("score", bytes(m[S["wScore"]:S["wScore"] + 7]).hex(), "kind", m[S["wMultKind"]])
