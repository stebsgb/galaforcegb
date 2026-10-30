"""Boss build: from the first frame a type-5 alien is dying, print its slot state, frame and timer,
and whether wBossFlash / the score change. Shows whether .bossfree is reached."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce_boss.gb"); S = load_syms("galaforce_boss.gb"); m = pb.memory
AL = S["wAliens"]
def sc(): return int(bytes(m[S["wScore"]:S["wScore"] + 7]).hex())
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
dying = None
for i in range(60000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    for c in range(0, 0xE0, 16):
        st = m[AL + c]
        if st == 0x81 and m[AL + c + 3] == 5:
            if dying is None:
                dying = c
                print("boss dying at tick", i, "slot", hex(c), "score", sc(), "state", m[S["wState"]])
            fr = m[AL + c + 9]
            if fr % 8 == 0:
                print("  tick", i, "frame", fr, "timer", m[AL + c + 15], "flash", m[S["wBossFlash"]], "score", sc())
    if dying is not None and m[AL + dying] == 0:
        print("boss slot freed at tick", i, "score", sc(), "flash", m[S["wBossFlash"]])
        break
