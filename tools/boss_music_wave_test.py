"""Boss music on the real boss wave (no pre-placed aliens). Run on galaforce_boss.gb (make boss).
Plays from the title into ZONE 04 (pattern 45), presses A every few frames to shoot, and records the first
frame the boss tune starts (aMute becomes 1). At that frame the boss must be alive, at most two standard
aliens may be alive, and no spawn record may still be pending (the pattern must have fully spawned)."""
import sys, warnings, os
warnings.filterwarnings("ignore")
os.chdir("/Users/sbickham/vscode_sgbfun/galaforcegb")
sys.path.insert(0, "tools")
from run_headless import make, load_syms

# GOD + BOSSTEST build (build/godboss_probe.gb, see the Makefile note in the session): the ship cannot die, so the
# wave reaches the boss pattern. Plain galaforce_boss.gb has no GOD define and the ship dies before the boss.
ROM = "build/godboss_probe.gb"
pb = make(ROM); S = load_syms(ROM); m = pb.memory
AL = S["wAliens"]
MAX_FRAMES = 6000

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

def census():
    boss = std = 0
    for i in range(14):
        b = AL + i * 16
        if m[b] == 0x80:
            if m[b + 3] == 5:
                boss += 1
            else:
                std += 1
    pending = sum(1 for i in range(4) if m[S["wInits"] + i * 16])
    return boss, std, pending

start_frame = None
for k in range(MAX_FRAMES):
    if k % 6 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if m[S["aMute"]] == 1 and m[S["aTune"]] == 6:
        start_frame = k
        break

boss, std, pending = census()
print("boss tune started at frame", start_frame)
print("at start: boss alive", boss, "standard alive", std, "pending spawn records", pending, "wBossWait", m[S["wBossWait"]])
ok = start_frame is not None and boss == 1 and std <= 2 and pending == 0
print("PASS" if ok else "FAIL: boss tune must start only with the boss alive, <=2 standard aliens and no pending spawns")
pb.stop()
sys.exit(0 if ok else 1)
