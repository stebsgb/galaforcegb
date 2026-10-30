"""Find the first frame where the live score passes the high score, print both values' bytes,
then the next 3 frames, to see whether the hi-score copy ever runs."""
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
found = None
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if val("wScore") > val("wHi"):
        found = i
        break
print("passed at tick", found, "score", b("wScore"), "hi", b("wHi"))
for k in range(3):
    pb.tick(1, False)
    print("+%d score %s hi %s" % (k + 1, b("wScore"), b("wHi")))
