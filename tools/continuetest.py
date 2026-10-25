"""Continues: game over asks CONTINUE?; YES refills lives and replays the wave, NO ends."""
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
for _ in range(40): pb.tick(1, False)
m[S["wOptCont"]] = 1
tap("start", 5)
for _ in range(300): pb.tick(1, False)
print("state", m[S["wState"]], "conts", m[S["wConts"]])
assert m[S["wConts"]] == 1
m[S["wLives"]] = 0; m[S["wState"]] = 3; m[S["wPExpT"]] = 0; m[S["wPExp"]] = 0; m[S["wTimer"]] = 0; m[S["wPAlive"]] = 0
for _ in range(200): pb.tick(1, False)
print("state", m[S["wState"]], "ask", m[S["wAsk"]])
assert m[S["wState"]] == 4 and m[S["wAsk"]] == 1
pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save("shots/ask.png")
tap("right"); pb.tick(10, False); assert m[S["wContSel"]] == 1
tap("right"); pb.tick(10, False)
tap("a", 5)
for _ in range(100): pb.tick(1, False)
print("state", m[S["wState"]], "lives", m[S["wLives"]], "conts", m[S["wConts"]])
assert m[S["wState"]] in (1, 2) and m[S["wLives"]] == 3 and m[S["wConts"]] == 0
m[S["wLives"]] = 0; m[S["wState"]] = 3; m[S["wPExpT"]] = 0; m[S["wPExp"]] = 0; m[S["wPAlive"]] = 0
for _ in range(200): pb.tick(1, False)
print("state", m[S["wState"]], "ask", m[S["wAsk"]])
assert m[S["wState"]] == 4 and m[S["wAsk"]] == 0
print("OK")
