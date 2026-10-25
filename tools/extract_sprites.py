import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from bbc import *
from PIL import Image, ImageDraw
sp = read_graphic()
Z = 8
sheet = Image.new("RGB", (len(sp)*(12*Z+8)//1, 16*Z+24), (40,40,40))
dr = ImageDraw.Draw(sheet)
for i, s in enumerate(sp):
    for y,row in enumerate(s):
        for x,c in enumerate(row):
            col = PAL[c & 7]
            dr.rectangle([i*(12*Z+8)+x*Z, 20+y*Z, i*(12*Z+8)+x*Z+Z-1, 20+y*Z+Z-1], fill=col)
    dr.text((i*(12*Z+8), 4), str(i), fill=(255,255,255))
os.makedirs(os.path.join(ROOT, "assets/ref"), exist_ok=True)
sheet.save(os.path.join(ROOT, "assets/ref/sprites_bbc.png"))
for i,s in enumerate(sp):
    print(i, sorted({c for r in s for c in r}))
