#!/usr/bin/env python3
"""Test multiplier detection"""
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
    f = 0
    while f < 2000 and not m[S["wDemo"]]:
        pb.tick(1, False)
        f += 1
    
    print(f"Demo started after {f} frames")
    
    # Wait a bit in demo
    for _ in range(400): pb.tick(1, False)
    
    # Press Start to exit demo
    pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
    for _ in range(80): pb.tick(1, False)
    
    # Press Start to start real game
    pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
    
    # Wait for game to start
    for _ in range(200): pb.tick(1, False)
    
    print(f"Real game started: state={m[S['wState']]}, wave={m[S['wWave']]}")
    
    # Main loop: shoot frequently
    last_multiplier = m[S['wDebugMultiplier']]
    last_wave = m[S['wWave']]
    
    for i in range(10000):
        # Press A every 5 frames
        if i % 5 == 0:
            pb.button_press("a")
            pb.tick(1, False)
            pb.button_release("a")
        else:
            pb.tick(1, False)
        
        current_multiplier = m[S['wDebugMultiplier']]
        current_wave = m[S['wWave']]
        
        if current_multiplier != last_multiplier:
            print(f"\nFrame {i+1}: Multiplier changed from {last_multiplier} to {current_multiplier}")
            print(f"  Wave: {current_wave}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
            last_multiplier = current_multiplier
        
        if current_wave != last_wave:
            print(f"\nFrame {i+1}: Wave changed from {last_wave} to {current_wave}")
            print(f"  Multiplier: {current_multiplier}")
            last_wave = current_wave
        
        if i % 1000 == 999:
            print(f"\nProgress: {i+1} frames")
            print(f"  Wave: {current_wave}, Multiplier: {current_multiplier}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
    
    print("\n=== Final ===")
    print(f"Wave: {m[S['wWave']]}, Multiplier: {m[S['wDebugMultiplier']]}")
    print(f"Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")

if __name__ == "__main__":
    main()