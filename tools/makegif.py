"""Records docs/screenshots/demo.gif: the title screen (idle wait skipped after a few seconds) moving into the demo waves."""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from PIL import Image
from run_headless import make, load_syms
rom = "galaforce.gb"
if os.path.exists(rom + ".ram"): os.remove(rom + ".ram")
pb = make(rom); S = load_syms(rom); m = pb.memory
while m[S["wFrame"]] < 20: pb.tick(1, False)
STEP = 4
frames = []
def grab():
    pb.tick(1, True)
    frames.append(pb.screen.image.copy().convert("L").resize((320, 288), Image.NEAREST))
n = 0
while m[S["wDemo"]] == 0 and n < 3000:
    for i in range(STEP - 1): pb.tick(1, False)
    grab(); n += STEP
    if n == 240: m[S["wIdle"] + 1] = 2          # skip most of the ~13 s idle wait
start = len(frames)
for _ in range(60 * 14 // STEP):                 # about 14 s of demo play
    for i in range(STEP - 1): pb.tick(1, False)
    grab()
pal = frames[0].quantize(4) if False else None
q = [f.convert("P", palette=Image.ADAPTIVE, colors=4) for f in frames]
q[0].save("docs/screenshots/demo.gif", save_all=True, append_images=q[1:], duration=STEP * 1000 // 60, loop=0, optimize=True)
print(len(frames), "frames, demo starts at", start, os.path.getsize("docs/screenshots/demo.gif") // 1024, "KB")
