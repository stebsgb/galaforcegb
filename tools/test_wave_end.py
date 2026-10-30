#!/usr/bin/env python3
"""Test wave completion"""
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
    
    # Wait for demo to start
    print("Waiting for demo to start...")
    f = 0
    while f < 2000 and not m[S["wDemo"]]:
        pb.tick(1, False)
        f += 1
    
    print(f"Demo started after {f} frames")
    
    # Run many frames and check for wave change
    last_wave = m[S['wWave']]
    last_multiplier = m[S['wDebugMultiplier']]
    
    for i in range(5000):
        pb.tick(1, False)
        
        current_wave = m[S['wWave']]
        current_multiplier = m[S['wDebugMultiplier']]
        
        if current_wave != last_wave:
            print(f"\nWave changed from {last_wave} to {current_wave} at frame {i+1}")
            print(f"  wWaveKills: {read16(S['wWaveKills'])}")
            print(f"  wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"  wWavePoints: {read16(S['wWavePoints'])}")
            print(f"  wDebugMultiplier: {current_multiplier}")
            last_wave = current_wave
        
        if current_multiplier != last_multiplier and current_multiplier != 0:
            print(f"\nMultiplier applied: {current_multiplier}x at frame {i+1}")
            print(f"  Wave: {current_wave}")
            print(f"  wWaveKills: {read16(S['wWaveKills'])}")
            print(f"  wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"  wWavePoints: {read16(S['wWavePoints'])}")
            last_multiplier = current_multiplier
        
        if i % 1000 == 999:
            print(f"\nProgress: {i+1} frames, wave={current_wave}, multiplier={current_multiplier}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
    
    print("\n=== Final state ===")
    print(f"Wave: {m[S['wWave']]}")
    print(f"Multiplier: {m[S['wDebugMultiplier']]}")
    print(f"Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")

if __name__ == "__main__":
    main()