"""Options cheat: UP UP DOWN DOWN SELECT reveals LEVEL; set start level, game starts on that wave; demo stays wave 0."""
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
assert m[S["wState"]] == 5
for k in ("down", "down", "right"): tap(k)       # wrong sequence: nothing
assert m[S["wCheat"]] == 0
tap("down"); tap("down")                          # sel -> back (3 rows without cheat)
assert m[S["wMenuSel"]] == 3 - 1 or m[S["wMenuSel"]] == 3
for k in ("up", "up", "down", "down", "select"): tap(k)
assert m[S["wCheat"]] == 1, "cheat not unlocked"
tap("up"); tap("up"); tap("down"); tap("down")
print("sel", m[S["wMenuSel"]])
while m[S["wMenuSel"]] != 2:
    tap("up" if m[S["wMenuSel"]] > 2 else "down")
for _ in range(7): tap("right")
assert m[S["wStartLvl"]] == 8, m[S["wStartLvl"]]
shot("cheat_menu.png")
for _ in range(10): tap("right")
assert m[S["wStartLvl"]] == 16
for _ in range(8): tap("left")
assert m[S["wStartLvl"]] == 8
tap("b", 100)
assert m[S["wState"]] == 0
tap("up"); tap("start", 5)
for _ in range(200): pb.tick(1, False)
print("wave", m[S["wWave"]], "state", m[S["wState"]])
assert m[S["wWave"]] == 7
shot("cheat_game.png")
print("OK")
