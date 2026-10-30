"""Hook AddDigitCol ($1a69, writes wScore without the hi-score compare) and AddScoreInner ($1d93).
Report which one runs on the frame the score jumps past wHi."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def b(a): return bytes(m[S[a]:S[a] + 7]).hex()
def val(a): return int(b(a))
hits = []
pb.hook_register(0, 0x1a69, lambda c: hits.append("AddDigitCol"), None)
pb.hook_register(0, 0x1d93, lambda c: hits.append("AddScoreInner"), None)
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
for k in range(7): m[S["wHi"] + k] = 0
m[S["wHi"] + 5] = 1
for i in range(20000):
    before = val("wScore")
    hits.clear()
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    after = val("wScore")
    if after != before and (after - before) > 10000 and before > 10000:
        print("big jump at tick", i, "score", b("wScore"), "hi", b("wHi"), "routines:", sorted(set(hits)))
        break
