"""Targeting-bomb check for ZONE 13 (GOD build, make god).
Forces the AimedBomb idle condition (wStill = 255) every frame and parks the ship under a live alien:
  - flagged alien (wNoBomb = 1, patterns 8/9) when one is alive, so no targeting bomb may be created;
  - otherwise a normal alien (control), which must create targeting bombs.
Counts AimedBomb calls that found a target and bombs created (InitBomb.got), split by flagged/normal.
PASS: flagged bombs created = 0, flagged-target frames > 0, normal bombs created > 0."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms

ROM = "galaforce_god.gb"
pb = make(ROM); S = load_syms(ROM); m = pb.memory
NB = S["wNoBomb"]; AL = S["wAliens"]
made = {"flagged": 0, "normal": 0}
frames_under = {"flagged": 0, "normal": 0}

def on_made(ctx):
    made["flagged" if m[NB + pb.register_file.C] else "normal"] += 1

pb.hook_register(1, S["InitBomb.got"], on_made, None)

for _ in range(400): pb.tick(1, False)
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
m[S["wStartLvl"]] = 13
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)

# Reach ZONE 13 patterns 8/9 first: sweep + fire at normal aliens until a flagged alien is live
held = set()
def hold(btns):
    global held
    for b in held - btns: pb.button_release(b)
    for b in btns - held: pb.button_press(b)
    held = btns
for k in range(30000):
    px = m[S["wPX"]]; tgt = None; best = 999
    for i in range(14):
        a = AL + 16 * i
        if m[a] == 0x80 and not m[NB + 16 * i]:
            d = abs(m[a + 1] - px)
            if d < best: best, tgt = d, m[a + 1]
    btns = {"a"}
    if tgt is not None:
        if tgt > px + 3: btns.add("right")
        elif tgt < px - 3: btns.add("left")
    hold(btns); pb.tick(1, False)
    if any(m[AL + 16 * i] == 0x80 and m[NB + 16 * i] for i in range(14)):
        break
hold(set())

# Targeting phase: force the idle condition and park under a live target every frame
for k in range(4000):
    flagged = [i for i in range(14) if m[AL + 16 * i] == 0x80 and m[NB + 16 * i]]
    normal = [i for i in range(14) if m[AL + 16 * i] == 0x80 and not m[NB + 16 * i]]
    if flagged:
        m[S["wPX"]] = m[AL + 16 * flagged[0] + 1]; frames_under["flagged"] += 1
    elif normal:
        m[S["wPX"]] = m[AL + 16 * normal[0] + 1]; frames_under["normal"] += 1
    m[S["wStill"]] = 255               # AimedBomb needs wStill >= 240
    pb.tick(1, False)

print("wave", m[S["wWave"]], "| frames parked under flagged:", frames_under["flagged"], "| under normal:", frames_under["normal"])
print("bombs created: flagged", made["flagged"], "| normal", made["normal"])
print("RESULT:", "PASS" if made["flagged"] == 0 and frames_under["flagged"] > 0 and made["normal"] > 0 else "FAIL/INCONCLUSIVE")
