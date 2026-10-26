"""Diagnostic: reach the secret screen, dump the BG map rows 13-17 and save a full-size frame."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = "galaforce.gb"
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
S = load_syms(rom); pb = make(rom); m = pb.memory
while m[S["wFrame"]] < 20: pb.tick(1, False)
def tap(b, n=6):
    pb.button_press(b); pb.tick(2, False); pb.button_release(b)
    for _ in range(n): pb.tick(1, False)
for _ in range(40): pb.tick(1, False)
tap("down"); tap("a", 90)
for k in ("down", "down", "up", "up", "select"): tap(k)
for _ in range(150): pb.tick(1, False)
for r in range(13, 18):
    print("row", r, [m[0x9800 + 32 * r + c] for c in range(12, 20)])
print("LCDC", hex(m[0xFF40]), "WX", m[0xFF4B], "WY", m[0xFF4A], "BGP", hex(m[0xFF47]))
pb.tick(1, True)
pb.screen.image.save("shots/secret_full.png")
