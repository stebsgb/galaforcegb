"""Find the frame where the live score passes wHi, then report the CPU's program counter at the tick
the score bytes change, to identify the routine that wrote wScore."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def b(a): return bytes(m[S[a]:S[a] + 7]).hex()
def val(a): return int(b(a))
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
    before = b("wScore")
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    after = b("wScore")
    if before != after:
        print("tick", i, "score", before, "->", after, "hi", b("wHi"), "wState", m[S["wState"]])
    if val("wScore") > val("wHi") and int(before) <= val("wHi") and i > 0:
        pass
    if i > 300:
        break
