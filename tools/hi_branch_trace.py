"""Hook AddScoreInner's compare labels (bank 0) and record which ones execute on the frame the live
score first passes wHi. Shows whether the hi-score copy (.copy) runs."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
def b(a): return bytes(m[S[a]:S[a] + 7]).hex()
def val(a): return int(b(a))
hits = []
def mark(name):
    def cb(ctx):
        hits.append(name)
    return cb
pb.hook_register(0, S["AddScoreInner.cmp"] & 0x3FFF if False else 0x1dac, mark("cmp"), None)
pb.hook_register(0, 0x1dba, mark("copy"), None)
pb.hook_register(0, 0x1dc6, mark("extra"), None)
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
    if before <= val("wHi") and after > val("wHi"):
        print("passed hi at tick", i, "score", b("wScore"), "hi", b("wHi"))
        print("branches executed on that frame:", hits)
        break
    if i % 5 == 0 and hits:
        pass
print("hi after:", b("wHi"), "score:", b("wScore"))
