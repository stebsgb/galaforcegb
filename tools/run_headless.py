#!/usr/bin/env python3
"""Headless PyBoy harness.
usage: run_headless.py ROM [--frames N] [--shot out.png] [--script "60:RIGHT,30:A,..."] [--shots f1,f2,...]
Script format: comma separated  frames:BUTTON[+BUTTON]  (hold for that many frames; '-' = none)
Prints symbol-based memory values with --peek name,name (needs ROM.sym next to the ROM)."""
import argparse, os, sys, warnings
warnings.filterwarnings("ignore")
from pyboy import PyBoy

def load_syms(rom):
    syms = {}
    p = os.path.splitext(rom)[0] + ".sym"
    if os.path.exists(p):
        for line in open(p):
            line = line.strip()
            if not line or line.startswith(";"): continue
            a, n = line.split(" ", 1)
            bank, addr = a.split(":")
            syms[n] = int(addr, 16)
    return syms

def make(rom, window="null", sound=False):
    return PyBoy(rom, window=window, sound_emulated=sound, cgb=False)

def run_script(pb, script, shots=None, outdir="build/screens", prefix="shot", on_frame=None):
    os.makedirs(outdir, exist_ok=True)
    shots = shots or []
    for item in [s for s in script.split(",") if s]:
        n, btns = item.split(":")
        btns = [b for b in btns.split("+") if b and b != "-"]
        for b in btns: pb.button_press(b.lower())
        for _ in range(int(n)):
            pb.tick(1, True)
            if on_frame: on_frame(pb)
            if pb.frame_count in shots:
                pb.screen.image.save(f"{outdir}/{prefix}_{pb.frame_count:05d}.png")
        for b in btns: pb.button_release(b.lower())

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("rom"); ap.add_argument("--frames", type=int, default=120)
    ap.add_argument("--shot", default=None); ap.add_argument("--script", default="")
    ap.add_argument("--shots", default=""); ap.add_argument("--peek", default="")
    a = ap.parse_args()
    pb = make(a.rom)
    syms = load_syms(a.rom)
    shots = [int(x) for x in a.shots.split(",") if x]
    if a.script: run_script(pb, a.script, shots)
    while pb.frame_count < a.frames: pb.tick(1, True)
    if a.shot:
        os.makedirs(os.path.dirname(a.shot) or ".", exist_ok=True)
        pb.screen.image.save(a.shot)
    for n in [x for x in a.peek.split(",") if x]:
        print(n, pb.memory[syms[n]])
    pb.stop()
