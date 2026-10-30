#!/usr/bin/env python3
"""Debug demo scoring"""
import sys
sys.path.insert(0, "tools")
from run_headless import make, load_syms
import warnings
warnings.filterwarnings("ignore")
import shutil
import os

def main():
    rom = "galaforce.gb"
    if not os.path.exists(rom):
        shutil.copy("galaforce-0.0.16.gb", rom)
    
    pb = make(rom)
    S = load_syms(rom)
    m = pb.memory
    
    def read16(addr):
        return m[addr] + (m[addr+1] << 8)
    
    def read_score():
        return bytes(m[S["wScore"]:S["wScore"] + 7]).hex()
    
    # Wait for demo to start
    print("Waiting for demo to start...")
    f = 0
    while f < 2000 and not m[S["wDemo"]]:
        pb.tick(1, False)
        f += 1
        if f % 100 == 0:
            print(f"  frame {f}: state={m[S['wState']]}, demo={m[S['wDemo']]}")
    
    print(f"Demo started after {f} frames; state {m[S['wState']]}, fade {m[S['wFade']]}")
    
    # Now run 400 frames as in demo test
    print("\nRunning 400 frames of demo...")
    for i in range(400):
        pb.tick(1, False)
        if i % 100 == 99:
            print(f"  After {i+1} frames:")
            print(f"    wWave: {m[S['wWave']]}")
            print(f"    wWaveKills: {read16(S['wWaveKills'])}")
            print(f"    wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"    wWavePoints: {read16(S['wWavePoints'])}")
            print(f"    wDebugMultiplier: {m[S['wDebugMultiplier']]}")
            print(f"    Score: {read_score()}")
    
    print(f"\nFinal after 400 frames in demo:")
    print(f"  state {m[S['wState']]}, wave {m[S['wWave']]}, score {read_score()}, lives {m[S['wLives']]}, fade {m[S['wFade']]}")
    print(f"  wWaveKills: {read16(S['wWaveKills'])}")
    print(f"  wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
    print(f"  wWavePoints: {read16(S['wWavePoints'])}")
    print(f"  wDebugMultiplier: {m[S['wDebugMultiplier']]}")
    
    # Continue to see if wave ends
    print("\nRunning 1200 more frames...")
    for i in range(1200):
        pb.tick(1, False)
        if i % 200 == 199:
            print(f"  After {i+1} more frames:")
            print(f"    wWave: {m[S['wWave']]}")
            print(f"    wDebugMultiplier: {m[S['wDebugMultiplier']]}")
            print(f"    Score: {read_score()}")
            if m[S['wDebugMultiplier']] != 0:
                print(f"    *** Multiplier {m[S['wDebugMultiplier']]}x applied! ***")
    
    print(f"\nFinal after total 1600 frames in demo:")
    print(f"  wave {m[S['wWave']]}, score {read_score()}, lives {m[S['wLives']]}, demo {m[S['wDemo']]}")

if __name__ == "__main__":
    main()