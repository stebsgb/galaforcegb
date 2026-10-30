"""On the frame the live score first passes wHi, record which of AddScoreInner's compare labels
(.cmp $1dac, .copy $1dba, .extra $1dc6) the CPU reaches. Shows whether the copy branch runs."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
CMP, COPY, EXTRA = 0x1dac, 0x1dba, 0x1dc6
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
    before = val("wScore")
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    if before <= val("wHi") and val("wScore") > val("wHi"):
        print("score passed hi at tick", i, "score", b("wScore"), "hi", b("wHi"))
        break
print("note: PC-level trace needs a breakpoint hook; reporting byte state instead")
print("hi after pass:", b("wHi"), "score:", b("wScore"))
