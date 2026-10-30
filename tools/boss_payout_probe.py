"""Count how many times the 2000 boss bonus is paid: watch wBossFlash being set and the score jumps."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def sc(): return bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
sets = 0
last_flash = 0
for i in range(120000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    fl = m[S["wBossFlash"]]
    if fl > last_flash:
        sets += 1
        print("tick", i, "wBossFlash set to", fl, "score", sc(), "wave", m[S["wWave"]])
        # trace the boss slots for 6 frames after the bonus
        for k in range(6):
            pb.tick(1, False)
            slots = [(c, m[0xC100 + c]) for c in range(0, 0xE0, 16) if m[0xC100 + c]]
            print("  +%d score %s flash %d live slots %s" % (k + 1, sc(), m[S["wBossFlash"]], slots))
        if sets >= 2:
            break
    last_flash = fl
print("bonus-set events seen:", sets)
