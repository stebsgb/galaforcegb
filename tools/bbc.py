"""Shared helpers for reading the original BBC Galaforce data."""
import os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, "ref")

# BBC Mode 2 logical colours 0-7 (8-15 flash; treated as same)
PAL = [(0,0,0),(255,0,0),(0,255,0),(255,255,0),(0,0,255),(255,0,255),(0,255,255),(255,255,255)]

def mode2_pixels(b):
    left = (((b>>7)&1)<<3) | (((b>>5)&1)<<2) | (((b>>3)&1)<<1) | ((b>>1)&1)
    right = (((b>>6)&1)<<3) | (((b>>4)&1)<<2) | (((b>>2)&1)<<1) | ((b>>0)&1)
    return left, right

def read_graphic():
    d = open(os.path.join(REF, "object", "O.GRAPHIC"), "rb").read()
    sprites = []
    for k in range(16):
        off = 38 + 96*k
        sprites.append(decode(d[off:off+96], 6, 16))
    sprites.append(decode(d[1574:1574+96], 6, 16))
    return sprites

def decode(data, wbytes, h):
    rows = []
    for y in range(h):
        row = []
        for x in range(wbytes):
            row.extend(mode2_pixels(data[y*wbytes+x]))
        rows.append(row)
    return rows
