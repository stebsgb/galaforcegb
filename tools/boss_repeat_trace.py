"""Boss build, normal play (player alive): place a 1-hit boss away from the ship, shoot it, and print
every frame the boss slot / wState / score / flash change, for the whole death, to find what re-triggers it."""
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
for c in range(0, 0xE0, 16):
    m[AL + c] = 0
boss = 0
m[AL + 0] = 0x80; m[AL + 1] = (m[S["wPX"]] + 60) % 150 + 4; m[AL + 2] = 40
m[AL + 3] = 5; m[AL + 4] = 0; m[AL + 5] = 1; m[AL + 14] = 0
prev_sc = sc(); prev_row = None
dead_at = None
for k in range(3000):
    if k % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    slot = [m[AL + c] for c in range(0, 0xE0, 16)]
    row = (m[AL], m[AL + 4], m[AL + 14], m[S["wState"]], m[S["wHfxT"]], m[S["wHfxN"]],
           m[S["wPAlive"]], m[S["wPX"]])
    s = sc()
    if row != prev_row or s != prev_sc:
        print("k=%d boss=%02x frame=%d tmr=%d wState=%d flash=%d bombs=%d alive=%d px=%d score+%d live_slots=%d"
              % (k, row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7], s - prev_sc,
                 sum(1 for v in slot if v)))
    prev_row, prev_sc = row, s
    if m[AL] == 0 and k > 20 and dead_at is None:
        dead_at = k
    if dead_at is not None and k > dead_at + 150:
        break
