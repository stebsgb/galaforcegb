"""Boss build: after the first wave starts, write a live type-5 alien (1 hit) into a free slot near the
ship's column, let the player shoot it, then trace each frame: score, boss slot state/frame/timer,
wBossFlash, and the number of OAM entries used. Shows the real death sequence."""
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
# clear all aliens, then place one boss (type 5) directly above the ship with 1 hit, live state $80
for c in range(0, 0xE0, 16):
    m[AL + c] = 0
px = m[S["wPX"]]
boss = 0
m[AL + boss + 0] = 0x80          # AL_ST live
m[AL + boss + 1] = (px + 60) % 150 + 4   # AL_X: away from the ship so the player stays alive
m[AL + boss + 2] = 40            # AL_Y (original y, field y = y>>1 = 20)
m[AL + boss + 3] = 5             # AL_TYPE boss
m[AL + boss + 4] = 0             # AL_FRAME
m[AL + boss + 5] = 1             # AL_HITS: next hit kills it
m[AL + boss + 14] = 0            # AL_TMR
print("placed boss at X", m[AL + boss + 1], "ship X", px)
prev = sc()
rows = []
for k in range(4000):
    if k % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    st = m[AL + boss]
    s = sc()
    oam = m[S["wOamLo"]]
    rows.append((k, st, m[AL + boss + 4], m[AL + boss + 14], s - prev, m[S["wBossFlash"]], oam))
    if st == 0x81 and k < 90: print("dying k", k, "type", m[AL+boss+3], "frame", m[AL+boss+4], "wState", m[S["wState"]])
    prev = s
    if st == 0 and k > 5:
        break
# print the transitions and every 8th frame of the death
last = None
for r in rows:
    key = (r[1], r[2] // 4, r[4] != 0, r[5] != 0)
    if key != last or r[4] or r[0] % 16 == 0:
        print("k=%d state=%02x frame=%d timer=%d scoreD=%d flash=%d oam=%d" % r)
    last = key
print("end: boss state", hex(m[AL + boss]), "final score", sc())
