"""Records colour GIFs of the intro (title screen from power-on) and the attract-mode demo, 10 s each, for both backgrounds.

Output: docs/screenshots/colour/{intro,demo}_{dark,white}.gif
The ROM is unchanged (DMG, 4 shades). Colour comes from mapping each of the four DMG shades to a palette entry here.
usage: python tools/makecolourgif.py            (run `make` first)
"""
import sys, os, warnings
warnings.filterwarnings("ignore")
sys.path.insert(0, "tools")
from PIL import Image
from run_headless import make, load_syms

ROM = "galaforce.gb"
OUT_DIR = "docs/screenshots/colour"
SECONDS = 10
STEP = 3                              # emulated frames per GIF frame: 20 fps, 50 ms per GIF frame
W, H = 320, 288                       # 2x the 160x144 screen, as in makegif.py
LEVELS = (0, 85, 153, 255)            # the four DMG shades PyBoy outputs, darkest to lightest
# shade index -> RGB, one palette per background mode (wOptBg: 0 = dark, 1 = white)
PALETTES = {
    0: [(0x0A, 0x0A, 0x2A), (0x2E, 0x5C, 0xB8), (0xF2, 0xA9, 0x3B), (0xFF, 0xF6, 0xC8)],  # dark: navy, blue, orange, cream
    1: [(0x0E, 0x0B, 0x2E), (0x2E, 0x6F, 0xD0), (0xE8, 0x6A, 0x2E), (0xFF, 0xF4, 0xD6)],  # white: ink, blue, orange, cream
}
TAGS = {0: "dark", 1: "white"}
# grey level (0-255) -> nearest shade index (0-3)
LUT = [min(range(4), key=lambda i: abs(v - LEVELS[i])) for v in range(256)]

def to_index(frame_l):
    """160x144 greyscale screen -> 320x288 image whose pixel values are shade indices 0-3."""
    return frame_l.resize((W, H), Image.NEAREST).point(LUT)

def record(bg, scene):
    if os.path.exists(ROM + ".ram"): os.remove(ROM + ".ram")
    pb = make(ROM); S = load_syms(ROM); m = pb.memory
    while m[S["wFrame"]] < 20: pb.tick(1, False)
    m[S["wOptBg"]] = bg
    # ApplyPalettes only runs on fades, so set the DMG palette registers now from the ROM tables.
    # Each table has 8 rows: 0-3 black background, 4-7 white background.
    base = bg * 4
    m[0xFF47] = m[S["fadeBGP"] + base]      # rBGP
    m[0xFF48] = m[S["fadeOBP0"] + base]     # rOBP0
    m[0xFF49] = m[S["fadeOBP1"] + base]     # rOBP1
    if scene == "demo":
        m[S["wIdle"] + 1] = 2                    # skip the ~13 s idle wait, as makegif.py does
        n = 0
        while m[S["wDemo"]] == 0 and n < 60 * 30:  # wait for the demo to start (capped)
            pb.tick(1, False); n += 1
        if not m[S["wDemo"]]: raise SystemExit("demo did not start")
    frames = []
    for _ in range(SECONDS * 60 // STEP):          # 10 s of emulated time, one GIF frame per STEP emulated frames
        for _ in range(STEP - 1): pb.tick(1, False)
        pb.tick(1, True)
        frames.append(to_index(pb.screen.image.convert("L")))
    pb.stop(save=False)
    # every frame is a 'P' image using the same 4-entry palette for this background mode
    flat = [c for rgb in PALETTES[bg] for c in rgb]
    imgs = []
    for f in frames:
        p = Image.frombytes("P", (W, H), f.tobytes())
        p.putpalette(flat)
        imgs.append(p)
    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, f"{scene}_{TAGS[bg]}.gif")
    imgs[0].save(out, save_all=True, append_images=imgs[1:], duration=50, loop=0, optimize=True)
    print(out, len(imgs), "frames", os.path.getsize(out) // 1024, "KB")

if __name__ == "__main__":
    for scene in ("intro", "demo"):
        for bg in (0, 1):
            record(bg, scene)
