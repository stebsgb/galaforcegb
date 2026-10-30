"""When a ×5 flash is on, read the HUD tiles at row 1 cols 8-11 and save a screenshot."""
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
done = False
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["wMultKind"]] == 5 and m[S["wMultFlash"]] and (m[S["wMultFlash"]] & 8):
        pb.tick(1, True)
        cols = [m[0x9800 + 32 + c] for c in range(8, 12)]
        print("kind 5 flash on; row1 cols 8-11 tiles", cols, "(43=X, 6+9? see T_FONT0=9: '5'=15, '3'=13)")
        pb.screen.image.copy().resize((480, 432)).save("shots/x5_screen.png")
        done = True
        break
if not done:
    print("no x5 flash seen")
