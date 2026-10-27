"""Options menu: navigate, set lives 5 + white background, persist across reboot, start game, screenshots."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = "galaforce.gb"
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
S = load_syms(rom)
def boot():
    pb = make(rom); 
    while pb.memory[S["wFrame"]] < 20: pb.tick(1, False)
    return pb
def tap(pb, b, n=6):
    pb.button_press(b); pb.tick(2, False); pb.button_release(b)
    for _ in range(n): pb.tick(1, False)
def shot(pb, name):
    pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save("shots/" + name)
pb = boot(); m = pb.memory
for _ in range(60): pb.tick(1, False)
shot(pb, "opt_title.png")
tap(pb, "down"); shot(pb, "opt_title2.png")
tap(pb, "a", 90)
assert m[S["wState"]] == 5, m[S["wState"]]
shot(pb, "opt_screen_black.png")
tap(pb, "right"); tap(pb, "right"); tap(pb, "right"); assert m[S["wOptLives"]] == 5
assert m[S["wOptBg"]] == 1  # default is white
assert m[S["wOptCont"]] == 1  # default 1, no cheat needed
tap(pb, "down"); assert m[S["wMenuSel"]] == 1
for _ in range(5): tap(pb, "right")
assert m[S["wOptCont"]] == 3
tap(pb, "left"); tap(pb, "left"); assert m[S["wOptCont"]] == 1
tap(pb, "down"); tap(pb, "right"); assert m[S["wOptBg"]] == 0
tap(pb, "right"); assert m[S["wOptBg"]] == 1
print("BGP", hex(m[0xFF47]))
for _ in range(10): pb.tick(1, False)
shot(pb, "opt_screen_white.png")
tap(pb, "b", 100)
assert m[S["wState"]] == 0 and m[S["wMenuSel"]] == 1
tap(pb, "up"); shot(pb, "opt_title_white.png")
tap(pb, "start", 5)
for _ in range(200): pb.tick(1, False)
print("lives", m[S["wLives"]], "state", m[S["wState"]])
assert m[S["wLives"]] == 4  # spares: setting 5 = 5 ships total (4 spare + 1 in play)
shot(pb, "opt_game_white.png")
pb.stop(save=True) if hasattr(pb, "stop") else None
pb2 = boot(); m = pb2.memory
print("reboot opts", m[S["wOptLives"]], m[S["wOptBg"]])
assert (m[S["wOptLives"]], m[S["wOptBg"]]) == (5, 1)
print("OK")
