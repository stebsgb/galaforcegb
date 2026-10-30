"""Boss build, normal play, no forced aliens: count every slot that becomes a live type-5 alien ($80)
and every type-5 slot that finishes dying (freed). Shows whether the boss death repeats because the
spawner keeps creating type-5 aliens."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
pb = make("galaforce_boss.gb"); S = load_syms("galaforce_boss.gb"); m = pb.memory
AL = S["wAliens"]
def sc(): return int(bytes(m[S["wScore"]:S["wScore"] + 7]).hex())
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(200): pb.tick(1, False)
prev = {c: (m[AL + c], m[AL + c + 3]) for c in range(0, 0xE0, 16)}
born = []; died = []
for i in range(40000):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
    cur = {c: (m[AL + c], m[AL + c + 3]) for c in range(0, 0xE0, 16)}
    for c in cur:
        st, ty = cur[c]
        pst, pty = prev[c]
        if st == 0x80 and (pst == 0 or pty != ty) and ty == 5:
            born.append((i, c, sc()))
        if pst == 0x81 and ty == 5 and st == 0:
            died.append((i, c, sc()))
    prev = cur
print("type-5 births:", len(born), born[:10])
print("type-5 deaths finished:", len(died), died[:10])
print("final score", sc(), "wave", m[S["wWave"]], "wBossFlash", m[S["wBossFlash"]])
