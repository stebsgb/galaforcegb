#!/usr/bin/env python3
"""Debug wave scoring variables"""
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
    
    print("=== Initial state ===")
    print(f"wState: {m[S['wState']]}")
    print(f"wDemo: {m[S['wDemo']]}")
    print(f"wWave: {m[S['wWave']]}")
    print(f"wWaveKills: {read16(S['wWaveKills'])}")
    print(f"wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
    print(f"wWavePoints: {read16(S['wWavePoints'])}")
    print(f"wIsBossWave: {m[S['wIsBossWave']]}")
    print(f"wDebugMultiplier: {m[S['wDebugMultiplier']]}")
    print(f"Score: {read_score()}")
    
    # Run frames
    for i in range(1000):
        pb.tick(1, False)
        if i % 100 == 99:
            print(f"\n=== After {i+1} frames ===")
            print(f"wState: {m[S['wState']]}")
            print(f"wDemo: {m[S['wDemo']]}")
            print(f"wWave: {m[S['wWave']]}")
            print(f"wWaveKills: {read16(S['wWaveKills'])}")
            print(f"wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"wWavePoints: {read16(S['wWavePoints'])}")
            print(f"wDebugMultiplier: {m[S['wDebugMultiplier']]}")
            print(f"Score: {read_score()}")
            
            # Check if wave ended
            if m[S['wDebugMultiplier']] != 0:
                print(f"*** Multiplier applied: {m[S['wDebugMultiplier']]}x ***")
    
    print("\n=== Final state ===")
    print(f"wWave: {m[S['wWave']]}")
    print(f"wWaveKills: {read16(S['wWaveKills'])}")
    print(f"wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
    print(f"wWavePoints: {read16(S['wWavePoints'])}")
    print(f"wDebugMultiplier: {m[S['wDebugMultiplier']]}")
    print(f"Score: {read_score()}")

if __name__ == "__main__":
    main()