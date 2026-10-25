"""Hi-score persistence: play, beat the hi-score, die to game over, then reboot with the same save RAM."""
import sys, io, warnings, random
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import load_syms
from pyboy import PyBoy
rom = "galaforce.gb"; S = load_syms(rom)
import os
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
pb = PyBoy(rom, window="null", sound_emulated=False, cgb=False); m = pb.memory
calls = []
pb.hook_register(0, S['SaveHi'], lambda c: calls.append(1), None)
while m[S["wFrame"]] < 20: pb.tick(1, False)
m[S["wOptCont"]] = 0           # no continue prompt, so game over ends the game
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for f in range(200): pb.tick(1, False)
m[S["wScore"] + 2] = 5          # 0050000 so the next kill beats 30000
pb.button_press("a")
died = False
for f in range(20000):
    pb.tick(1, False)
    if f > 400: m[S["wPX"]] = 76 if (f // 40) % 2 else 40   # sit in the line of fire
    if m[S["wState"]] == 4: died = True
    if died and m[S["wState"]] == 0: break
print("game over reached:", died, "hi now", bytes(m[S["wHi"]:S["wHi"] + 7]).hex())
m[0x0000] = 0x0A
print("SaveHi calls", len(calls), "A000 raw", m[0xA000:0xA004])
pb.stop(save=True)
print("save header:", open(rom + ".ram", "rb").read()[:12].hex())
pb2 = PyBoy(rom, window="null", sound_emulated=False, cgb=False); m2 = pb2.memory
while m2[S['wFrame']] < 20: pb2.tick(1, False)
print("after reboot hi:", bytes(m2[S["wHi"]:S["wHi"] + 7]).hex())
