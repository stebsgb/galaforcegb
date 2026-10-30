"""Play to the first wave, then save a crop of the top-left HUD area for inspection."""
import sys, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from run_headless import make, load_syms
from PIL import Image
pb = make("galaforce.gb"); S = load_syms("galaforce.gb"); m = pb.memory
f = 0
while f < 2000 and not m[S["wDemo"]]:
    pb.tick(1, False); f += 1
for _ in range(400): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(80): pb.tick(1, False)
pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
for _ in range(600):
    pb.tick(1, False)
    if m[S["wState"]] == 2: break
for i in range(300):
    if i % 5 == 0:
        pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
    else:
        pb.tick(1, False)
pb.tick(1, True)
im = pb.screen.image.copy().convert("RGB")
im.crop((0, 0, 160, 40)).resize((960, 240), Image.NEAREST).save("shots/hud_garbage.png")
print("saved; wState", m[S["wState"]], "score", bytes(m[S["wScore"]:S["wScore"]+7]).hex())
