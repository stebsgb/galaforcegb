"""Title idle -> demo (fade), demo plays itself, Start returns to the title; hi-score unchanged; Start then plays normally."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = sys.argv[1] if len(sys.argv) > 1 else "galaforce.gb"
pb = make(rom); S = load_syms(rom); m = pb.memory
def hi(): return bytes(m[S["wHi"]:S["wHi"] + 7]).hex()
while m[S["wFrame"]] < 20: pb.tick(1, False)
h0 = hi(); print("hi at boot", h0)
shots = {}; f = 0; seen = []
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
    if f in (3, 30): shots[f] = 1
print("demo started after", f, "frames; state", m[S["wState"]], "fade", m[S["wFade"]])
for _ in range(400): pb.tick(1, False)
pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save("shots/demo1.png")
sc = bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
print("after 400 frames: state", m[S["wState"]], "wave", m[S["wWave"]], "score", sc, "lives", m[S["wLives"]], "fade", m[S["wFade"]])
for _ in range(1200): pb.tick(1, False)
print("after 1600: wave", m[S["wWave"]], "score", bytes(m[S["wScore"]:S["wScore"] + 7]).hex(), "lives", m[S["wLives"]], "demo", m[S["wDemo"]])
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
print("after Start: demo", m[S["wDemo"]], "state", m[S["wState"]], "hi", hi() == h0, "fade", m[S["wFade"]])
pb.tick(1, True); pb.screen.image.copy().resize((480, 432)).save("shots/demo2.png")
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
print("real game: demo", m[S["wDemo"]], "state", m[S["wState"]], "lives", m[S["wLives"]], "fade", m[S["wFade"]])
# natural demo end: wait for timeout without pressing
