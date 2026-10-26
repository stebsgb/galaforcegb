"""Secret screen: on the options screen DOWN DOWN UP UP SELECT shows a flashing screen, a heart and
"FOR MAYA" fading in. Checks the heart and text reach the map, screenshots the stages, and that B returns to options."""
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
def shot(name):
    pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save("shots/" + name)
for _ in range(40): pb.tick(1, False)
tap("down"); tap("a", 90)
assert m[S["wState"]] == 5, "not on options"
for k in ("down", "down", "up", "up", "select"): tap(k)
assert m[S["wState"]] == 6, "secret screen not entered"
shot("secret_flash.png")
for _ in range(45): pb.tick(1, False)
shot("secret_heart_grow.png")
for _ in range(60): pb.tick(1, False)
HEART0 = None
for line in open("build/gfx.inc"):
    if line.startswith("DEF HEART0"): HEART0 = int(line.split()[-1])
assert HEART0 is not None
assert m[0x9800 + 32 * 4 + 8] == HEART0, "heart missing"
assert m[0x9800 + 32 * 10 + 6] != 0, "FOR MAYA missing"
shot("secret_final.png")
tap("b", 100)
assert m[S["wState"]] == 5, "B did not return to options"
print("OK secret screen")
