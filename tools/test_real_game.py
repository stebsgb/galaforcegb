#!/usr/bin/env python3
"""Test real game scoring"""
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
    
    print(f"Real game started: state={m[S['wState']]}, wave={m[S['wWave']]}, lives={m[S['wLives']]}")
    
    # Now run the game and monitor wave progression
    last_wave = m[S['wWave']]
    last_score = read_score()
    
    for i in range(3000):
        pb.tick(1, False)
        
        current_wave = m[S['wWave']]
        current_multiplier = m[S['wDebugMultiplier']]
        current_score = read_score()
        
        if current_wave != last_wave:
            print(f"\n*** Wave changed from {last_wave} to {current_wave} at frame {i+1} ***")
            print(f"  Multiplier: {current_multiplier}")
            print(f"  wWaveKills: {read16(S['wWaveKills'])}")
            print(f"  wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"  wWavePoints: {read16(S['wWavePoints'])}")
            print(f"  Score before: {last_score}")
            print(f"  Score after:  {current_score}")
            last_wave = current_wave
        
        if current_multiplier != 0:
            print(f"\n*** Multiplier {current_multiplier}x applied at frame {i+1} ***")
            print(f"  Wave: {current_wave}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
        
        if i % 500 == 499:
            print(f"\nProgress: {i+1} frames")
            print(f"  Wave: {current_wave}, Multiplier: {current_multiplier}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
            print(f"  Score: {current_score}")
        
        last_score = current_score
    
    print("\n=== Final state ===")
    print(f"Wave: {m[S['wWave']]}")
    print(f"Multiplier: {m[S['wDebugMultiplier']]}")
    print(f"Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
    print(f"Score: {read_score()}")

if __name__ == "__main__":
    main()