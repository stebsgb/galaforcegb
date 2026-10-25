"""Regenerates docs/screenshots/*.png (3x, DMG greys) from the built ROMs. Uses galaforce_god.gb for gameplay shots."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
OUT = "docs/screenshots"; os.makedirs(OUT, exist_ok=True)
def session(rom, bg):
    if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
    pb = make(rom); S = load_syms(rom); m = pb.memory
    while m[S["wFrame"]] < 20: pb.tick(1, False)
    m[S["wOptBg"]] = bg
    return pb, S, m
def run(pb, n):
    for _ in range(n): pb.tick(1, False)
def tap(pb, b, n=6):
    pb.button_press(b); pb.tick(2, False); pb.button_release(b); run(pb, n)
def shot(pb, name):
    pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save(f"{OUT}/{name}.png")
for bg, tag in ((1, "white"), (0, "black")):
    pb, S, m = session("galaforce.gb", bg)
    run(pb, 90); shot(pb, f"title_{tag}")
    tap(pb, "down"); tap(pb, "a", 90); shot(pb, f"options_{tag}")
    pb2, S, m = session("galaforce_god.gb", bg)
    tap(pb2, "start", 150)
    # play: fire, drift and wait for wave 1 to be underway
    pb2.button_press("a")
    for i in range(420):
        pb2.tick(1, False)
        if i % 120 < 60: pb2.button_press("left")
        else: pb2.button_release("left")
    shot(pb2, f"wave1_{tag}")
    m[S["wWave"]] = 4
    for _ in range(900): pb2.tick(1, False)
    shot(pb2, f"wave5_{tag}")
print("done")
