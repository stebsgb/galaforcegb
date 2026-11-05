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
# Pattern 0 (wave 0, first pattern run): alien count (part byte 4, num) set to 20.
assert patts_out[0] == [1, 0, 50, 5, 20, 0, 5, 12, 0], patts_out[0]
patts_out[0][4] = 20
# Pattern 0: increase the spacing between aliens (part byte 3, delay) from 5 to 7 spawn ticks.
patts_out[0][3] = 7
# Pattern 0: increase the vertical spacing between aliens (part byte rely, index 6) from 5 to 7 Y units.
assert patts_out[0][6] == 5, patts_out[0]
patts_out[0][6] = 7
# Pattern 1 (mirrored path 0, waves 0 and 8): same spacing change, delay from 5 to 7 spawn ticks.
assert patts_out[1] == [1, 73, 50, 5, 20, 0, 5, 12, 128], patts_out[1]
patts_out[1][3] = 7
# Pattern 1: increase the vertical spacing between aliens (part byte rely, index 6) from 5 to 8 Y units.
assert patts_out[1][6] == 5, patts_out[1]
patts_out[1][6] = 7
# Pattern 2 (waves 0, 3, 6, 9): reduce the alien count (part byte 4, num) by 2, from 30 to 28.
assert patts_out[2] == [1, 12, 24, 4, 30, 0, 0, 18, 1], patts_out[2]
patts_out[2][4] = 28
# Patterns 15 and 16 (waves 4, 10 and 13): use the wider 8-tick spawn delay in every wave.
assert patts_out[15] == [1, 0, 210, 5, 12, 0, 0, 18, 10], patts_out[15]
assert patts_out[16] == [1, 74, 210, 5, 12, 0, 0, 18, 138], patts_out[16]
patts_out[15][3] = 8
patts_out[16][3] = 8
# Pattern 29 (part: [x, y, delay, count, relx, rely, gra, path]): reduce the alien count (part byte 4, num) from 21 to 12.
# Pattern 29 is the first pattern of wave 12 (ZONE 13) and also the last pattern of wave 10 (ZONE 11), so both zones get the change.
assert patts_out[29] == [1, 0, 32, 2, 21, 3, 0, 20, 18], patts_out[29]
patts_out[29][4] = 12
# Pattern 30 (part: [x, y, delay, count, relx, rely, gra, path]): reduce the alien count (part byte 4, num) from 21 to 12.
# Pattern 30 is the second pattern of wave 12 (ZONE 13) only.
assert patts_out[30] == [1, 74, 32, 2, 21, 253, 0, 20, 146], patts_out[30]
patts_out[30][4] = 12
# Patterns 8 and 9 keep their original spawn height (part byte y, index 2 = 32). No override.
# Pattern 8 is the third pattern of wave 12 (ZONE 13) and is also used by waves 1, 2, 3, 6, 7, 9, 10, 12, 13, 14 and 15.
# Pattern 9 is the fourth pattern of wave 12 (ZONE 13) and is also used by waves 2 and 9 (ZONES 3 and 10).
# No bomb rule on these two (patterns 8 and 9 fire normally).
assert patts_out[8] == [1, 36, 32, 6, 15, 0, 0, 20, 6], patts_out[8]
assert patts_out[9] == [1, 38, 32, 6, 15, 0, 0, 20, 134], patts_out[9]
# Patterns 29 and 30 (ZONE 13, first and second patterns): spawn delay (part byte index 3) from 2 to 3 ticks, so the gaps between aliens are slightly wider.
# Pattern 29 is also ZONE 11's last pattern, so ZONE 11 gets the wider gap too.
assert patts_out[29] == [1, 0, 32, 2, 12, 3, 0, 20, 18], patts_out[29]
patts_out[29][3] = 3
assert patts_out[30] == [1, 74, 32, 2, 12, 253, 0, 20, 146], patts_out[30]
patts_out[30][3] = 3
# Patterns 31 and 32 (ZONE 13 only, the last two patterns of wave 12): 8 aliens each (part byte 4, num) from 12,
# and spawn row (part byte y, index 2) lowered from 32 to 36 (higher Y is lower on screen). Both are no-bomb patterns.
assert patts_out[31] == [1, 73, 32, 4, 12, 0, 0, 32, 19], patts_out[31]
patts_out[31][2] = 36
patts_out[31][4] = 8
assert patts_out[32] == [1, 1, 32, 4, 12, 0, 0, 32, 147], patts_out[32]
patts_out[32][2] = 36
patts_out[32][4] = 8
# Pattern 23 (part: [x, y, delay, count, relx, rely, gra, path]): spawn delay (index 3) from 3 to 4 ticks,
# doubling the gap between aliens in the stream. Pattern 23 is used by waves 3, 7 and 14 (original lists).
assert patts_out[23] == [1, 2, 255, 3, 20, 0, 0, 20, 15], patts_out[23]
patts_out[23][3] = 4
# Pattern 24 (part: [x, y, delay, count, relx, rely, gra, path]): spawn delay (index 3) from 3 to 4 ticks,
# same change as pattern 23. Pattern 24 is in wave 3's original list.
assert patts_out[24] == [1, 72, 255, 3, 20, 0, 0, 20, 143], patts_out[24]
patts_out[24][3] = 4
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
patts_out[45][11] = 19              # delay (spacing between aliens)
patts_out[45][12] = 12               # count (number of aliens)
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
    # keep the original pattern list for this boss wave, so the earlier patterns play first;
    # the original list already ends with pattern 45 before the 255 terminator
    assert waves[_wi][-2] == 45 and waves[_wi][-1] == 255, waves[_wi]

L.append("patt_ptrs:\n" + "\n".join("  dw patt%d" % i for i in range(len(patts))))
for i, p in enumerate(patts_out):
    L.append("patt%d:  db %s" % (i, ",".join(str(b) for b in p)))
L.append("patdat_ptrs:\n" + "\n".join("  dw patdat%d" % i for i in range(len(pdats))))
for i, p in enumerate(pdats):
    L.append("patdat%d:  db %s" % (i, ",".join(str(b) for b in p)))
L.append("wave_ptrs:\n" + "\n".join("  dw wave%d" % i for i in range(len(waves))))
for i, w in enumerate(waves):
    L.append("wave%d:  db %s" % (i, ",".join(str(b) for b in w)))
L.append("alien_hits:  db 1,1,1,1,1,25,2,5,5,2,2,2")   # index 5 = solo boss (type 5): default 25 hits; first boss (wave 3) uses 20 hits
L.append("alien_score: db 1,1,1,1,4,8,4,4,6,8,8,8   ; x10 points (standard kills 10 pts)")
os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
open(os.path.join(ROOT, "build/data.inc"), "w").write("\n".join(L) + "\n")
json.dump({"patts": patts, "patdats": pdats, "waves": waves, "dx": dx, "dy": dy},
          open(os.path.join(ROOT, "assets/ref/waves.json"), "w"))
print("data.inc written:", sum(len(p) for p in patts), "pattern bytes,", sum(len(p) for p in pdats), "path bytes")
