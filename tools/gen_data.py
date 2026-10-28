#!/usr/bin/env python3
"""Parse the original 6502 pattern / wave / direction tables into RGBDS data (build/data.inc)
and a JSON dump (assets/ref/waves.json) for inspection."""
import os, re, json, sys
sys.path.insert(0, os.path.dirname(__file__))
from bbc import REF, ROOT

def read_blocks(path):
    """Return {label: [bytes]} for files made of EQUB lines."""
    blocks, cur = {}, None
    for line in open(os.path.join(REF, "src", path), encoding="latin1"):
        line = line.rstrip("\n")
        # strip BBC comments: backslash to end of line
        line = re.split(r"\\", line)[0]
        if not line.strip():
            continue
        m = re.match(r"\s*\.(\w+)\s*$", line)
        if m:
            cur = m.group(1); blocks[cur] = []; continue
        for stmt in line.split(":"):
            stmt = stmt.strip()
            if not stmt.upper().startswith("EQUB"):
                continue
            expr = stmt[4:].strip().replace("&", "0x")
            v = eval(expr, {"__builtins__": {}}, {"xstep": 1, "ystep": 4})
            blocks[cur].append(v & 0xFF)
    return blocks

patt = read_blocks("PATT.asm")
patdat = read_blocks("PATDAT.asm")
wave = read_blocks("WAVE.asm")

def idx_key(prefix, d):
    return sorted((int(k[len(prefix):]), k) for k in d if k.startswith(prefix))

patts = [patt[k] for _, k in idx_key("patt", patt)]
pdats = [patdat[k] for _, k in idx_key("patdat", patdat)]
waves = [wave[k] for _, k in idx_key("wave", wave)]
assert len(patts) == 46 and len(pdats) == 30 and len(waves) == 16, (len(patts), len(pdats), len(waves))
# =====================================================================================
# BOSS PATH TUNING  (waves 4, 8, 12, 16 use pattern 45)
# =====================================================================================
# Where this sits in the pipeline
#   ref/src/PATDAT.asm  -> read_blocks() -> pdats[]        original BBC path scripts (read-only)
#   this section        -> pdats[27], pdats[28], pdats[30] overridden / added here
#   build/data.inc      -> patdat27, patdat28, patdat30 emitted as db lists
#   src/aliens.asm      -> AlienStep / AlienFetch / ReadPat interpret the bytes at runtime
#
# Path script byte format (interpreted by AlienFetch in src/aliens.asm)
#   byte >= 128 : move. steps = byte - 128. The next byte is a direction index.
#                 direction index selects dir_dx[] and dir_dy[] (both emitted above).
#   byte 2      : switch path. The next byte is the new path number (patdat_ptrs).
#   byte 4      : spawn child alien (.newalien)        (not used here)
#   byte 6      : end / die (.die)                      (not used here)
#   byte 14     : reset. .mve sets X = 0, Y = 72 (the entry point), then continues.
#   Other values fall through to .mve, which is why 14 is the reset.
#
# Direction indices used in these paths (from dir_dx/dir_dy in build/data.inc)
#   9 = right (dx +2, dy 0)   10 = down (dx 0, dy +4)   11 = left (dx -2, dy 0)
#
# Safety: the original bytes are asserted before overwriting. If ref/src/PATDAT.asm is changed,
# the build stops here rather than silently replacing the wrong data.
# -------------------------------------------------------------------------------------
# Path 27  (original: drop 4, right 36, then 4-step drop, left 36 ... see PATDAT.asm .patdat27)
# -------------------------------------------------------------------------------------
assert pdats[27] == [164, 9, 131, 10, 164, 11], pdats[27]
pdats[27] = [132, 10, 164, 9, 2, 30]
# Result: drop 4 steps down, sweep right 36, then hand off to path 30 (reset).
#
# -------------------------------------------------------------------------------------
# Path 28  (original: see PATDAT.asm .patdat28)
# -------------------------------------------------------------------------------------
assert pdats[28] == [131, 10, 164, 9, 131, 10, 164, 11, 14, 2, 27], pdats[28]
pdats[28] = [164, 9, 136, 10, 162, 11, 2, 27]
# Result: sweep right 36, drop 8, sweep left 34, then hand off to path 27.
#
# -------------------------------------------------------------------------------------
# Path 30  (NEW: not in PATDAT.asm; appended as index 30)
# -------------------------------------------------------------------------------------
pdats.append([14, 130, 10, 2, 28])
# Result: reset to the entry point, drop 2 steps, then hand off to path 28.
# This is the only place the re-entry height is set.
# =====================================================================================


# validate patt layout
for i, p in enumerate(patts):
    n = p[0]
    assert len(p) == 1 + 8 * n, (i, len(p))

# direction tables (px per frame at K=2 frames per original step)
def s8(v): return v - 256 if v > 127 else v
rout1 = open(os.path.join(REF, "src", "ROUT1.asm"), encoding="latin1").read()
def table(name):
    seg = rout1.split("." + name)[1]
    vals = []
    for line in seg.splitlines()[1:]:
        line = line.split("\\")[0]
        if not line.strip(): continue
        if line.strip().startswith("."): break
        for stmt in line.split(":"):
            stmt = stmt.strip()
            if stmt.startswith("EQUB"):
                vals.append(eval(stmt[4:].replace("&", "0x"), {"__builtins__": {}}, {"xstep": 1, "ystep": 4}))
    return vals
ax, ay = table("addrelx"), table("addrely")
assert len(ax) == 56 and len(ay) == 56, (len(ax), len(ay))
dx = [a for a in ax]                 # px per frame (2 px per unit, 2 frames per step)
dy = [a // 2 for a in ay]            # original y units per frame
assert all(a % 2 == 0 for a in ay)

L = ["; generated by tools/gen_data.py - do not edit", 'SECTION "gamedata", ROM0', ""]
L.append("dir_dx:\n" + "\n".join("  db %d" % v for v in dx))
L.append("dir_dy:\n" + "\n".join("  db %d" % v for v in dy))
# =====================================================================================
# BOSS PATTERN 45  (waves 4, 8, 12, 16)
# =====================================================================================
# Source: ref/src/PATT.asm .patt45 (original BBC values, read by read_blocks()).
# Y values are original BBC y units. src/aliens.asm FieldY maps them to screen pixels:
#   the value is halved, then scaled by 5/8 up to y=80 (so lower Y = higher on screen).
# The original rows sit 24 units apart (about 8 px on screen), which overlaps and exceeds
# the 10-objects-per-scanline limit, so the rows are spaced here (BOSS_A, BOSS_B).
# -------------------------------------------------------------------------------------
BOSS_A, BOSS_B = 80, 128
patts_out = [list(q) for q in patts]
# Path 0 (used by patterns 0 and 1, so waves 0 and 8): keep the original 3-step vertical legs.
# A 4-step leg (opcode 132) caused a lone alien to appear clipped at the right edge on Zone 1 (v0.0.10).
assert pdats[0][2] == 131 and pdats[0][11] == 131, pdats[0]
# Pattern layout (read by StartPattern in src/aliens.asm):
#   byte 0 = number of parts. Each part is 8 bytes:
#   [x, y, delay, count, relx, rely, gra, path]
#   Part 1 starts at index 1 (solo top boss), part 2 at index 9 (loop row), part 3 at index 17.
# -------------------------------------------------------------------------------------
assert patts_out[45][0] == 3 and patts_out[45][10] == 72 and patts_out[45][18] == 96
assert patts_out[45][2] == 40, patts_out[45]
# Part 1 (solo top boss) -- Y is the height of the solo boss.
patts_out[45][2] = 32                 # original 40; lower = higher on screen
# Part 2 (loop row) -- Y, spacing and count.
patts_out[45][10] = BOSS_A            # loop row Y
# Part 3 -- only used when BOSS_SINGLE_STREAM is False.
patts_out[45][18] = BOSS_B
assert patts_out[45][11] == 4 and patts_out[45][19] == 4
patts_out[45][11] = 10                # delay (spacing between aliens)
patts_out[45][12] = 12                # count (number of aliens)
patts_out[45][8] = 29                 # path: solo top boss
patts_out[45][16] = 28                # path: loop row (path 28 -> 27 -> 30 -> 28 loop)
# -------------------------------------------------------------------------------------
# Single-stream switch
#   True  : keep parts 1 and 2 only (the slice below removes part 3).
#   False : keep all three parts.
# -------------------------------------------------------------------------------------
BOSS_SINGLE_STREAM = True
if BOSS_SINGLE_STREAM:
    assert patts_out[45][0] == 3
    patts_out[45] = patts_out[45][:17]
    patts_out[45][0] = 2
for _wi in (3, 7, 11, 15):
    waves[_wi] = [waves[_wi][0], 45, 255]

L.append("patt_ptrs:\n" + "\n".join("  dw patt%d" % i for i in range(len(patts))))
for i, p in enumerate(patts_out):
    L.append("patt%d:  db %s" % (i, ",".join(str(b) for b in p)))
L.append("patdat_ptrs:\n" + "\n".join("  dw patdat%d" % i for i in range(len(pdats))))
for i, p in enumerate(pdats):
    L.append("patdat%d:  db %s" % (i, ",".join(str(b) for b in p)))
L.append("wave_ptrs:\n" + "\n".join("  dw wave%d" % i for i in range(len(waves))))
for i, w in enumerate(waves):
    L.append("wave%d:  db %s" % (i, ",".join(str(b) for b in w)))
L.append("alien_hits:  db 1,1,1,1,1,10,2,5,5,2,2,2")
L.append("alien_score: db 2,2,2,2,4,8,4,4,6,8,8,8   ; x10 points")
os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
open(os.path.join(ROOT, "build/data.inc"), "w").write("\n".join(L) + "\n")
json.dump({"patts": patts, "patdats": pdats, "waves": waves, "dx": dx, "dy": dy},
          open(os.path.join(ROOT, "assets/ref/waves.json"), "w"))
print("data.inc written:", sum(len(p) for p in patts), "pattern bytes,", sum(len(p) for p in pdats), "path bytes")
