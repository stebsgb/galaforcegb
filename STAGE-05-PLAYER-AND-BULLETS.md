# STAGE 05 — Player ship and bullets

**Goal:** a ship that moves and fires like the original.
**Input:** Stage 04 engine, `docs/ANALYSIS.md` (CHARP/ROUT sections). **Output:** `src/player.asm`, `src/bullets.asm`.

## Tasks
1. **Entity framework:** fixed-size object arrays in WRAM with struct-of-arrays layout (x.hi/x.lo, y.hi/y.lo, state, type, frame…). Document the layout in `docs/DECISIONS.md`. Provide `for each active` loop macros that keep inner loops short.
2. **Player:** horizontal movement (the original's ship moves left/right along the bottom; check ANALYSIS), speed in 8.8 scaled from the original, screen-edge clamping, 16×16 two-sprite draw, thruster animation, placed above the bottom Window strip.
3. **Bullets:** limit and rate as in the original (check ANALYSIS: max bullets on screen and fire delay). Spawn from the ship's nose, move up in 8.8, die at the top of the playfield. Draw as sprites.
4. **Respawn state hooks** (invulnerable blink, dead state) stubbed for Stage 07.
5. **Test script:** harness presses right, then holds A for 120 frames. Verify via screenshot and a WRAM dump: ship x clamps correctly, bullet count never exceeds the limit, the fire rate matches expected frames.

## Acceptance
- Smooth movement at 60 fps with no flicker of the player sprites.
- Screenshots in `build/screens/stage05_*.png` show the ship and a bullet stream.
- `docs/PROGRESS.md` updated.
