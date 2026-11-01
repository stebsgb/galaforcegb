#!/usr/bin/env python3
"""Check the explosion limits in src/edgefx.asm.

- Player-kill explosions (state $81, AL_BOMB 0): at most 3 live at once.
- Smart bomb kills (AL_BOMB 1): not counted and not capped, so a bomb can leave more than 3 live.
- Edge (path-end) explosions (state $83): at most 1 live at once.
- Boss (type 5) is never capped.
usage: test_explosion_cap.py [ROM]   (default galaforce.gb; run `make` first)
"""
import sys
sys.path.insert(0, "tools")
from run_headless import make, load_syms
import warnings
warnings.filterwarnings("ignore")
import os

MAXAL = 14
AL_ST, AL_TYPE, AL_TMR, AL_BOMB = 0, 3, 14, 15


def main():
    rom = sys.argv[1] if len(sys.argv) > 1 else "galaforce.gb"
    if not os.path.exists(rom):
        print("ROM not found:", rom)
        return 2

    pb = make(rom)
    S = load_syms(rom)
    m = pb.memory
    aliens = S["wAliens"]

    def slots():
        out = []
        for i in range(MAXAL):
            base = aliens + i * 16
            out.append((m[base + AL_ST], m[base + AL_TYPE], m[base + AL_BOMB], m[base + AL_TMR]))
        return out

    def counts():
        s = slots()
        kills = sum(1 for st, t, b, _ in s if st == 0x81 and t != 5 and b == 0)
        bombs = sum(1 for st, t, b, _ in s if st == 0x81 and t != 5 and b == 1)
        edges = sum(1 for st, t, b, _ in s if st == 0x83)
        boss = sum(1 for st, t, b, _ in s if st == 0x81 and t == 5)
        return kills, bombs, edges, boss

    # Boot to the demo, then start a real game (same key sequence as test_multiplier.py)
    f = 0
    while f < 2000 and not m[S["wDemo"]]:
        pb.tick(1, False)
        f += 1
    for _ in range(400):
        pb.tick(1, False)
    pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
    for _ in range(80):
        pb.tick(1, False)
    pb.button_press("start"); pb.tick(1, False); pb.button_release("start")
    for _ in range(200):
        pb.tick(1, False)

    worst_kills = 0
    worst_edges = 0
    saw_bomb_over_cap = False
    bombs_used = 0

    for i in range(12000):
        if i % 1500 == 750 and m[S["wBombs"]] > 0 and m[S["wPAlive"]]:
            pb.button_press("select"); pb.tick(1, False); pb.button_release("select")
            bombs_used += 1
        elif i % 5 == 0:
            pb.button_press("a"); pb.tick(1, False); pb.button_release("a")
        else:
            pb.tick(1, False)

        kills, bombs, edges, _ = counts()
        worst_kills = max(worst_kills, kills)
        worst_edges = max(worst_edges, edges)
        if kills + bombs > 3 and bombs > 0:
            saw_bomb_over_cap = True

    print(f"bombs used: {bombs_used}")
    print(f"max player-kill explosions live at once: {worst_kills} (limit 3)")
    print(f"max edge explosions live at once: {worst_edges} (limit 1)")
    print(f"smart bomb kills let total exceed 3: {saw_bomb_over_cap}")
    ok = worst_kills <= 3 and worst_edges <= 1
    print("PASS" if ok else "FAIL")
    pb.stop()
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
