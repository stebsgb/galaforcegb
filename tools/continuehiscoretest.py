"""Continue then hi-score: after a continue is used, a higher score still saves to that setting's SRAM slot."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
rom = "galaforce.gb"
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
S = load_syms(rom); pb = make(rom); m = pb.memory
calls = []
pb.hook_register(0, S["SaveHi"], lambda c: calls.append(1), None)
while m[S["wFrame"]] < 20: pb.tick(1, False)
def tap(b, n=6):
    pb.button_press(b); pb.tick(2, False); pb.button_release(b)
for _ in range(40): pb.tick(1, False)
m[S["wOptCont"]] = 1                 # 1 continue: hi-score slot 1, default 1000
tap("start", 5)
for _ in range(300): pb.tick(1, False)
assert m[S["wConts"]] == 1
# first death: CONTINUE? prompt, cursor to YES, confirm -> continue used
m[S["wLives"]] = 0; m[S["wState"]] = 3; m[S["wPExpT"]] = 0; m[S["wPExp"]] = 0; m[S["wTimer"]] = 0; m[S["wPAlive"]] = 0
for _ in range(200): pb.tick(1, False)
assert m[S["wState"]] == 4 and m[S["wAsk"]] == 1
tap("right"); pb.tick(10, False); assert m[S["wContSel"]] == 1
tap("right"); pb.tick(10, False)
tap("a", 5)
for _ in range(100): pb.tick(1, False)
assert m[S["wState"]] in (1, 2) and m[S["wConts"]] == 0
print("continue used: wHiOK", m[S["wHiOK"]], "(must stay 1)")
assert m[S["wHiOK"]] == 1
# score well above the 1000 default, then die on the last life with no continues left
# (UpdateHiScore only runs from AddScoreInner; mirror its result here since the score is poked)
m[S["wScore"] + 2] = 5               # 0050000
m[S["wHi"]:S["wHi"] + 7] = m[S["wScore"]:S["wScore"] + 7]
for _ in range(60): pb.tick(1, False)
m[S["wLives"]] = 0; m[S["wState"]] = 3; m[S["wPExpT"]] = 0; m[S["wPExp"]] = 0; m[S["wTimer"]] = 0; m[S["wPAlive"]] = 0
for _ in range(200): pb.tick(1, False)
assert m[S["wState"]] == 4 and m[S["wAsk"]] == 0
m[0x0000] = 0x0A
slot = bytes(m[0xA020:0xA029]); hi = bytes(m[S["wHi"]:S["wHi"] + 7]); score = bytes(m[S["wScore"]:S["wScore"] + 7])
print("SaveHi calls", len(calls), "wHi", hi.hex(), "wScore", score.hex(), "slot1", slot.hex())
m[0x0000] = 0x00
assert len(calls) == 1, "SaveHi was not called after the continue was used"
assert slot[0:2] == b"GF" and slot[2:9] == hi, "slot 1 SRAM does not hold the new hi-score"
assert hi == score, "saved hi-score should equal the 50000 score"
print("OK")
