#!/usr/bin/env python3
"""Test shooting and wave completion"""
import sys
sys.path.insert(0, "tools")
from run_headless import make, load_syms
import warnings
warnings.filterwarnings("ignore")
import shutil
import os
import random

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
    
    # Main loop: shoot frequently, move occasionally
    last_wave = m[S['wWave']]
    shoot_counter = 0
    move_counter = 0
    move_direction = 0  # 0 = left, 1 = right
    
    for i in range(5000):
        # Press A to shoot every 10 frames
        if shoot_counter == 0:
            pb.button_press("a")
            pb.tick(1, False)
            pb.button_release("a")
        else:
            pb.tick(1, False)
        
        shoot_counter = (shoot_counter + 1) % 10
        
        # Move ship occasionally
        if move_counter == 0:
            if move_direction == 0:
                pb.button_press("left")
                pb.tick(1, False)
                pb.button_release("left")
            else:
                pb.button_press("right")
                pb.tick(1, False)
                pb.button_release("right")
            move_direction = 1 - move_direction  # toggle
        
        move_counter = (move_counter + 1) % 30
        
        # Check for wave change
        current_wave = m[S['wWave']]
        current_multiplier = m[S['wDebugMultiplier']]
        
        if current_wave != last_wave:
            print(f"\n*** Wave changed from {last_wave} to {current_wave} at frame {i+1} ***")
            print(f"  Multiplier: {current_multiplier}")
            print(f"  wWaveKills: {read16(S['wWaveKills'])}")
            print(f"  wWaveTotalAliens: {read16(S['wWaveTotalAliens'])}")
            print(f"  wWavePoints: {read16(S['wWavePoints'])}")
            print(f"  Score: {read_score()}")
            
            # If multiplier was applied, we won't see it because ResetWaveStats cleared it
            # But we can check if score increased significantly
            last_wave = current_wave
        
        if current_multiplier != 0:
            print(f"\n*** Multiplier {current_multiplier}x applied at frame {i+1} ***")
            print(f"  Wave: {current_wave}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
        
        if i % 500 == 499:
            print(f"\nProgress: {i+1} frames")
            print(f"  Wave: {current_wave}, Multiplier: {current_multiplier}")
            print(f"  Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
            print(f"  Score: {read_score()}")
    
    print("\n=== Final state ===")
    print(f"Wave: {m[S['wWave']]}")
    print(f"Multiplier: {m[S['wDebugMultiplier']]}")
    print(f"Kills: {read16(S['wWaveKills'])}, Total: {read16(S['wWaveTotalAliens'])}, Points: {read16(S['wWavePoints'])}")
    print(f"Score: {read_score()}")

if __name__ == "__main__":
    main()