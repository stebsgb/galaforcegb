"""Play to the first wave, then after every frame check: if wScore > wHi (as digits), the high score
must equal the score the same frame. Reports each frame where the live score exceeds the high score."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def val(a): return int(bytes(m[S[a]:S[a] + 7]).hex())
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
# set the high score low so the live score will break it during play
for k in range(7): m[S["wHi"] + k] = 0
m[S["wHi"] + 5] = 1
bad = []
broke = 0
prev_hi = val("wHi")
for i in range(20000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    s, h = val("wScore"), val("wHi")
    if s > h:
        bad.append((i, s, h))
    if h != prev_hi:
        broke += 1
    prev_hi = h
print("frames where score > hi:", len(bad), " frames the hi-score changed:", broke)
for b in bad[:8]:
    print("tick", b[0], "score", b[1], "hi", b[2])
print("final score", val("wScore"), "hi", val("wHi"))
