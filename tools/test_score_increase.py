#!/usr/bin/env python3
"""Test score increase from multiplier"""
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
    
    print(f"Real game started: state={m[S['wState']]}, wave={m[S['wWave']]}")
    
    # Main loop: shoot frequently
    last_multiplier = m[S['wDebugMultiplier']]
    score_before_multiplier = None
    
    for i in range(10000):
        # Press A every 5 frames
        if i % 5 == 0:
            pb.button_press("a")
            pb.tick(1, False)
            pb.button_release("a")
        else:
            pb.tick(1, False)
        
        current_multiplier = m[S['wDebugMultiplier']]
        
        if current_multiplier != last_multiplier:
            if last_multiplier == 0 and current_multiplier in (2, 5):
                score_before = read_score()
                # Capture state before potential change
                kills_before = read16(S['wWaveKills'])
                total_before = read16(S['wWaveTotalAliens'])
                points_before = read16(S['wWavePoints'])
                wave_before = m[S['wWave']]
                
                # Run one more frame to let score update
                pb.tick(1, False)
                
                score_after = read_score()
                print(f"\n*** Multiplier {current_multiplier}x applied at frame {i+1} ***")
                print(f"  Wave: {wave_before}")
                print(f"  Kills: {kills_before}/{total_before} ({kills_before/total_before*100:.1f}%)")
                print(f"  Wave points: {points_before} (x10 = {points_before*10})")
                print(f"  Score before: {score_before}")
                print(f"  Score after:  {score_after}")
                
                # Calculate expected score increase
                # extra points = points_before * (multiplier-1)
                extra_points = points_before * (current_multiplier - 1)
                print(f"  Expected extra points: {extra_points} (x10 = {extra_points*10})")
                # We can't easily convert BCD score to decimal, but we can check if score changed
                if score_before != score_after:
                    print(f"  Score changed! (difference)")
                else:
                    print(f"  Score unchanged (BUG!)")
                
                # Stop after first multiplier
                break
        
        last_multiplier = current_multiplier
    
    print("\n=== Final ===")
    print(f"Wave: {m[S['wWave']]}, Multiplier: {m[S['wDebugMultiplier']]}")
    print(f"Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
    print(f"Score: {read_score()}")

if __name__ == "__main__":
    main()