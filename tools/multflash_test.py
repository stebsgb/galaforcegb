"""Checks the HUD X2/X5 flash: after a >80% wave multiplier, HUD row 1 cols 9-10 show the text."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = "galaforce.gb"
pb = make(rom); S = load_syms(rom); m = pb.memory
VRAM = 0x9800
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
seen = None
for i in range(4000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wMultFlash"]] and seen is None:
        seen = i
        print("multiplier flash started at frame", i, "kind", m[S["wMultKind"]])
    if seen is not None and i - seen in (4, 12, 40):
        pb.tick(1, True)
        cols = [m[VRAM + 32 + c] for c in (8, 9, 10, 11)]
        print("HUD tiles cols 8-11:", cols, "flash left", m[S["wMultFlash"]], "hSplit", m[0xFF00 + 0] if False else "?", "state", m[S["wState"]])
        pb.screen.image.copy().resize((480, 432)).save("shots/multflash%d.png" % (i - seen))
    if seen is not None and i - seen > 130:
        break
print("done, wave", m[S["wWave"]], "score", bytes(m[S["wScore"]:S["wScore"]+7]).hex())
