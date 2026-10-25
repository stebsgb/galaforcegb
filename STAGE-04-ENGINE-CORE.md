# STAGE 04 — Engine core

> **Status/as built:** see `docs/DECISIONS.md` and `docs/PROGRESS.md`; the design changed (all-sprite aliens, custom audio driver, 128 px playfield, MBC1 SRAM). Where this file disagrees, those win.

**Goal:** the frame loop, screen layout and shared systems everything else builds on.
**Input:** Stage 03 tiles. **Output:** `src/hardware.inc`, `src/engine.asm`, `src/oam.asm`, `src/input.asm`, `src/screen.asm`, `src/stars.asm`, `src/math.asm`, `src/ram.asm`.

## Tasks
1. **Boot and init:** wait for vblank, LCD off, load tiles, clear VRAM/OAM/WRAM, set palettes (BGP, OBP0, OBP1), set LCD on. Stack in WRAM, DMG-only header flag.
2. **Frame loop:** vblank interrupt sets a flag. Main loop: wait flag → run OAM DMA from HRAM → apply queued VRAM writes (budgeted) → update input → game logic → build shadow OAM. Frame counter and a simple RNG (LFSR) with `rand8`.
3. **OAM manager:** shadow OAM at an aligned WRAM page, `oam_begin`/`oam_add_sprite` helpers, and a **rotating start index** so flicker is fair if more than 10 sprites share a line. Unused entries hidden (Y=0). 8×16 mode enabled.
4. **Screen layout (per `00-OVERVIEW.md`):**
   - Top 8 px: score / hi-score row. Rendered with BG tiles at SCX=0, SCY=0.
   - Middle 120 px: playfield BG (stars, formation). Use an LYC interrupt on line 8 to switch SCX/SCY to the playfield scroll values, and back to 0 for the next frame (a stat interrupt handler kept very short).
   - Bottom 16 px: Window layer (WY=128+8, WX=7) showing lives icons and level number.
   - Verify with a harness screenshot that the three zones are right and that the playfield scroll doesn't move the HUDs.
5. **Starfield:** parallax stars via per-zone scroll or tile rows, vertical scrolling downward with ≥2 speeds (match `docs/ANALYSIS.md`). Zero CPU cost beyond SCY updates; use a second LYC split if two speeds are wanted.
6. **Input:** D-pad + A/B with press/held/released edge bits. Choose controls: left/right move, A fire (hold for auto-fire at the original rate), Start pause, Select to be decided in Stage 09.
7. **Math:** 8.8 fixed-point add/sub, 8×8→16 multiply if needed, a sine/path helper only if Stage 02 shows it's needed.
8. **Debug aids (build flag `DEBUG=1`):** a CPU load bar (change BGP at the end of logic) and a sprites-per-line counter in a hidden WRAM region, readable by the harness.

## Acceptance
- ROM boots in PyBoy; screenshot shows the HUD top row, a starfield scrolling in the playfield, and the bottom window strip.
- Over 600 frames, the frame loop never misses vblank (harness checks the frame counter equals the emulated frames).
- Input edge logic verified by a scripted button test.
- `docs/PROGRESS.md` updated.
