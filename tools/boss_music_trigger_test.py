"""Boss music trigger: the boss tune starts only when the boss is alive and at most two standard aliens are left.
Run on galaforce_boss.gb (make boss). Places a live boss and 3 standard aliens, checks the tune is still silent,
then removes one standard alien and checks the boss tune (MUS_BOSS = 6) starts on the wave channel (aMute = 1)."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms

pb = make("galaforce_boss.gb"); S = load_syms("galaforce_boss.gb"); m = pb.memory
AL = S["wAliens"]
MUS_BOSS = 6

def tick(n):
    for _ in range(n):
        pb.tick(1, False)

f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
tick(400)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
tick(80)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
tick(200)

# clear the field and the pattern spawn records (wInits), so the game does not refill the field
for c in range(0, 16 * 14, 16):
    m[AL + c] = 0
for c in range(0, 16 * 4):
    m[S["wInits"] + c] = 0

# place a live boss (type 5) and 3 standard aliens (type 0 = plain, 1 hit)
px = m[S["wPX"]]
def place(slot, typ, x, y, hits):
    b = AL + slot * 16
    m[b + 0] = 0x80; m[b + 1] = x; m[b + 2] = y; m[b + 3] = typ
    m[b + 4] = 0; m[b + 5] = hits; m[b + 14] = 0
place(0, 5, (px + 60) % 150 + 4, 40, 20)     # boss, far from the ship
place(1, 0, 10, 60, 2)
place(2, 0, 30, 60, 2)
place(3, 0, 50, 60, 2)

m[S["wBossWait"]] = 1                        # the boss pattern armed the wait (as StartPattern does)
tick(60)
print("3 standard + boss: wBossWait", m[S["wBossWait"]], "aMute", m[S["aMute"]], "aTune", m[S["aTune"]])
assert m[S["wBossWait"]] == 1 and m[S["aMute"]] == 0, "music started too early (3 standard aliens)"

m[AL + 1 * 16 + 0] = 0                       # one standard alien gone: 2 left
tick(5)
print("2 standard + boss: wBossWait", m[S["wBossWait"]], "aMute", m[S["aMute"]], "aTune", m[S["aTune"]], "aLoop", m[S["aLoop"]])
assert m[S["wBossWait"]] == 0 and m[S["aMute"]] == 1 and m[S["aLoop"]] == 1 and m[S["aTune"]] == MUS_BOSS, "boss tune did not start"

print("PASS: boss tune starts only once the boss is alone with at most 2 standard aliens")
pb.stop()
