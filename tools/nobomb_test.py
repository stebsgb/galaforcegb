"""ZONE 13 no-bomb check (GOD build, make god). Starts on ZONE 13 (wStartLvl 13 = wave index 12) and sweeps
and fires like tools/bot.py. Counts bombs actually created (InitBomb.got: a free bomb slot was found)
for aliens with the no-bomb flag (wNoBomb = 1: patterns 8 and 9) and for normal aliens (control).
PASS: flagged bombs created = 0 and normal bombs created > 0."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms

ROM = "galaforce_god.gb"
pb = make(ROM); S = load_syms(ROM); m = pb.memory
NB = S["wNoBomb"]; AL = S["wAliens"]
GOT = S["InitBomb.got"]                 # reached only when a free bomb slot exists: a bomb is created
created = {"flagged": 0, "normal": 0}

def on_got(ctx):
    c = pb.register_file.C              # alien slot offset, preserved by InitBomb
    created["flagged" if m[NB + c] else "normal"] += 1

pb.hook_register(1, GOT, on_got, None)  # InitBomb.got is in ROM bank 1

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

held = set()
def hold(btns):
    global held
    for b in held - btns: pb.button_release(b)
    for b in btns - held: pb.button_press(b)
    held = btns
flagged_seen = 0
for k in range(30000):
    px = m[S["wPX"]]
    tgt = None; best = 999
    for i in range(14):
        a = AL + 16 * i
        if m[a] == 0x80:
            d = abs(m[a + 1] - px)
            if d < best: best, tgt = d, m[a + 1]
    btns = {"a"}
    if tgt is not None:
        if tgt > px + 3: btns.add("right")
        elif tgt < px - 3: btns.add("left")
    hold(btns)
    pb.tick(1, False)
    flagged_seen += sum(1 for i in range(14) if m[AL + 16 * i] == 0x80 and m[NB + 16 * i] == 1)
    if m[S["wWave"]] > 12:
        break
print("wave reached", m[S["wWave"]], "| frames with a live flagged alien:", flagged_seen)
print("bombs created by flagged aliens:", created["flagged"])
print("bombs created by normal aliens (control):", created["normal"])
print("RESULT:", "PASS" if created["flagged"] == 0 and created["normal"] > 0 else "FAIL")
