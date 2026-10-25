#!/usr/bin/env python3
"""Recreate the Galaforce graphics for the DMG: 16x16 sprites (hand-mapped from the original 12x16
Mode-2 art), 5x7 font, stars, title letters and HUD icons. Writes build/gfx_obj.bin, build/gfx_bg.bin,
build/gfx.inc and preview PNGs."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from bbc import read_graphic, ROOT
from font5x7 import G, CHARS
from PIL import Image

sp = read_graphic()          # 0-5 explosion, 6-15 aliens, 16 player
STRETCH = [0,1,1,2,3,4,4,5,6,7,7,8,9,10,10,11]   # 12 -> 16 columns, mirror-symmetric (dst x <-> 15-x maps src s <-> 11-s)

# BBC colour luminance (for ranking)
LUM = {7:7, 6:6, 3:5, 2:4, 5:3, 4:2, 1:1}
ALIEN_PAL = [0,1,0,1,0,1,0,1,0,1]     # OBP select per art: alternate so neighbours differ
from collections import Counter
def auto_map(art):
    """Body colour -> shade 2, lighter colours -> 1, darker -> 3 (before the OBP palette is applied)."""
    cnt = Counter(c & 7 for row in art for c in row if c & 7)
    body = cnt.most_common(1)[0][0]
    m = {body: 2}
    for c in cnt:
        if c != body:
            m[c] = 1 if LUM[c] > LUM[body] else 3
    return m

LEFT = [0,1,1,2,3,4,4,5]

def axis_of(art):
    best = min(((sum(bool(r[x] & 7) != bool(r[a - x] & 7) if 0 <= a - x < 12 else bool(r[x] & 7)
                     for r in art for x in range(12)), a) for a in (10, 11)))
    return best

def conv(art, mapping, sym=False):
    out = []
    bad, a = axis_of(art)
    sym = sym and bad == 0
    for row in art:
        r = []
        for x in range(16):
            if sym:
                sx = LEFT[x] if x < 8 else a - LEFT[15 - x]
            else:
                sx = STRETCH[x]
            c = row[sx] & 7
            r.append(0 if c == 0 else mapping.get(c, 1))
        out.append(r)
    return out

def tiles_from_16(px):
    """16x16 pixel grid -> 4 tiles in 8x16 object order: L-top, L-bottom, R-top, R-bottom (as raw 2bpp)."""
    def tile(x0, y0):
        b = bytearray()
        for y in range(8):
            lo = hi = 0
            for x in range(8):
                v = px[y0 + y][x0 + x]
                lo = (lo << 1) | (v & 1); hi = (hi << 1) | ((v >> 1) & 1)
            b += bytes([lo, hi])
        return bytes(b)
    return tile(0, 0) + tile(0, 8) + tile(8, 0) + tile(8, 8)

def tile8(px):
    b = bytearray()
    for y in range(8):
        lo = hi = 0
        for x in range(8):
            v = px[y][x]
            lo = (lo << 1) | (v & 1); hi = (hi << 1) | ((v >> 1) & 1)
        b += bytes([lo, hi])
    return bytes(b)

def blank(): return bytes(16)

arts = {}   # name -> 16x16 pixel idx grid
obj = bytearray()
syms = []
def add_sprite(name, px):
    arts[name] = px
    syms.append((name, len(obj) // 16))
    obj.extend(tiles_from_16(px))

# player (sp16)
add_sprite("SPR_PLAYER", conv(sp[16], auto_map(sp[16]), True)[::-1])  # source art is stored nose-down
# explosion frames
for i in range(6):
    add_sprite("SPR_EXPL%d" % i, conv(sp[i], {7:1, 3:1, 1:2, 6:1, 4:3})[::-1])
# aliens
alien_pal = []
for k in range(10):
    add_sprite("SPR_ALIEN%d" % k, conv(sp[6 + k], auto_map(sp[6 + k]), True)[::-1])
    alien_pal.append(ALIEN_PAL[k])

# bullet (8x16 object): 2px wide bar with bright tip
bul = [[0]*8 for _ in range(16)]
for y in range(0, 8):
    for x in (3, 4): bul[y][x] = 1 if y < 3 else 2
syms.append(("SPR_BULLET", len(obj) // 16))
obj.extend(tile8(bul[0:8]) + tile8(bul[8:16]))
# alien bomb: diamond/drop, 4 wide
bomb = [[0]*8 for _ in range(16)]
shape = [".##.", ".##.", ".##.", "####", "####", ".##."]   # falls downwards: round head at the bottom
for y, row in enumerate(shape):
    for x, ch in enumerate(row):
        if ch == "#": bomb[y][2 + x] = 2 if (x in (0, 3)) or y < 3 else 1
syms.append(("SPR_BOMB", len(obj) // 16))
obj.extend(tile8(bomb[0:8]) + tile8(bomb[8:16]))
FONTOBJ0 = len(obj) // 16
for ch in CHARS:
    px = [[0]*8 for _ in range(8)]
    for y, r in enumerate(G[ch]):
        for x, c in enumerate(r):
            if c == "#": px[y][x] = 1
    obj.extend(tile8(px) + blank())
OBJ_TILES = len(obj) // 16

# ---------------- BG tiles ($8800 = tile 128 ..)
bg = bytearray()
def bg_add(t): bg.extend(t)
BG0 = 0
bg_add(blank())                                 # 128 blank
STAR0 = BG0 + 1
for i, (x, y, c) in enumerate([(1,2,1),(5,6,2),(3,0,3),(6,3,1),(2,5,2),(7,1,1),(4,4,3),(0,7,2)]):
    px = [[0]*8 for _ in range(8)]; px[y][x] = c
    bg_add(tile8(px))
FONT0 = BG0 + len(bg) // 16
for ch in CHARS:
    rows = G[ch]
    px = [[0]*8 for _ in range(8)]
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            if c == "#": px[y][x] = 3
    bg_add(tile8(px))
# big title letters (3x wide, 2x tall 5x7 -> 15x14 in a 16x16 cell, as the wide BBC title, with shadow)
BIGSET = "GALAFORCE"
while len(bg) // 16 < 64 - BG0: bg_add(blank())
BIG0 = BG0 + len(bg) // 16
for ch in BIGSET:
    big = [[0]*16 for _ in range(16)]
    pts = [(1 + y*2 + dy, x*3 + dx) for y, r in enumerate(G[ch]) for x, c in enumerate(r) if c == "#" for dy in range(2) for dx in range(3)]
    for yy, xx in pts:
        if yy + 1 < 16: big[yy+1][xx] = 1
    for yy, xx in pts: big[yy][xx] = 3
    bg_add(tile8([r[0:8] for r in big[0:8]])); bg_add(tile8([r[8:16] for r in big[0:8]]))
    bg_add(tile8([r[0:8] for r in big[8:16]])); bg_add(tile8([r[8:16] for r in big[8:16]]))
while len(bg) // 16 < 100 - BG0: bg_add(blank())
ICON0 = BG0 + len(bg) // 16
life = ["...##...", "...##...", "..####..", "..####..", ".######.", "########", "##.##.##", "#..##..#"]
flag = ["#####...", "######..", "#####...", "#.......", "#.......", "#.......", "#.......", "#......."]
for icon in (life, flag):
    px = [[3 if ch == "#" else 0 for ch in r] for r in icon]
    bg_add(tile8(px))
BG_TILES = len(bg) // 16
assert BG0 + BG_TILES <= 128

import random
rng = random.Random(1986)
star_map = bytearray(512)         # 16 rows x 32 cols, period 128px
for i in range(512):
    if rng.random() < 0.085: star_map[i] = STAR0 + rng.randrange(8)
open(os.path.join(ROOT, "build/starmap.bin"), "wb").write(star_map)
os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
open(os.path.join(ROOT, "build/gfx_obj.bin"), "wb").write(obj)
open(os.path.join(ROOT, "build/gfx_bg.bin"), "wb").write(bg)

L = ["; generated by tools/gen_art.py - do not edit"]
for n, t in syms: L.append("DEF %s EQU %d" % (n, t))
L.append("DEF OBJ_TILES EQU %d" % OBJ_TILES)
L.append("DEF T_OFONT0 EQU %d" % FONTOBJ0)
L.append("DEF BG_FIRST EQU %d" % BG0)
L.append("DEF BG_TILES EQU %d" % BG_TILES)
L.append("DEF T_BLANK EQU %d" % BG0)
L.append("DEF T_STAR0 EQU %d" % STAR0)
L.append("DEF T_FONT0 EQU %d" % FONT0)
L.append("DEF T_BIG0 EQU %d" % BIG0)
L.append("DEF T_LIFE EQU %d" % ICON0)
L.append("DEF T_FLAG EQU %d" % (ICON0 + 1))
for ch in "0123456789":
    pass
L.append('; font char order: %r' % CHARS)
L.append('SECTION "gfxdata", ROM0')
L.append('gfx_obj: INCBIN "build/gfx_obj.bin"')
L.append('gfx_bg:  INCBIN "build/gfx_bg.bin"')
L.append('starmap: INCBIN "build/starmap.bin"')
L.append('DEF GFX_BG_SIZE EQU %d' % len(bg))
L.append('DEF GFX_OBJ_SIZE EQU %d' % len(obj))
L.append("alien_pal: db %s     ; OBP select per art" % ",".join(str(p) for p in alien_pal))
open(os.path.join(ROOT, "build/gfx.inc"), "w").write("\n".join(L) + "\n")
print("obj tiles", OBJ_TILES, "bg tiles", BG_TILES, "font0", FONT0, "big0", BIG0)

# ------------ preview (DMG green + grey, OBP0/OBP1 approximations)
GREEN = [(0x9B,0xBC,0x0F), (0x8B,0xAC,0x0F), (0x30,0x62,0x30), (0x0F,0x38,0x0F)]
def shade_for(pal, idx):
    # OBP0: 1->white(0) 2->light(1) 3->dark(2); OBP1: 1->light(1) 2->white(0) 3->dark(2)
    if idx == 0: return 3
    if pal == 0: return {1:0, 2:1, 3:2}[idx]
    return {1:1, 2:0, 3:2}[idx]
Z = 4
names = ["SPR_PLAYER"] + ["SPR_EXPL%d" % i for i in range(6)] + ["SPR_ALIEN%d" % k for k in range(10)]
img = Image.new("RGB", (len(names) * (16*Z + 6) + 6, 16*Z + 12), GREEN[3])
for n, nm in enumerate(names):
    pal = alien_pal[int(nm[9:])] if nm.startswith("SPR_ALIEN") else 0
    for y in range(16):
        for x in range(16):
            s = shade_for(pal, arts[nm][y][x])
            for dy in range(Z):
                for dx in range(Z):
                    img.putpixel((6 + n*(16*Z+6) + x*Z + dx, 6 + y*Z + dy), GREEN[s])
img.save(os.path.join(ROOT, "assets/dmg_sprites_preview.png"))
grey = [(255,255,255),(170,170,170),(85,85,85),(0,0,0)]
img2 = img.copy()
for y in range(img.height):
    for x in range(img.width):
        p = img.getpixel((x, y))
        img2.putpixel((x, y), grey[GREEN.index(p)])
img2.save(os.path.join(ROOT, "assets/dmg_sprites_preview_grey.png"))
