# STAGE 06 — Formation and attackers (hybrid BG + sprite)

> **Status/as built:** see `docs/DECISIONS.md` and `docs/PROGRESS.md`; the design changed (all-sprite aliens, custom audio driver, 128 px playfield, MBC1 SRAM). Where this file disagrees, those win.

**Goal:** the alien formation drawn on the BG, with aliens that peel off along the original paths as sprites. This is the hardest stage — split it into the sub-steps below and verify each one.
**Input:** Stages 02–05, `build/data/paths.inc`, `waves.inc`. **Output:** `src/formation.asm`, `src/aliens.asm`, `src/paths.asm`.

## Design (fixed)
- **Formation BG:** the grid of aliens occupies BG tiles (2×2 tiles per alien) within the playfield. The formation sways horizontally by SCX changes in the playfield LYC zone. Keep a **formation occupancy bitmap** in WRAM (one bit or byte per slot) as the source of truth.
- **Attackers/entrants:** any alien in motion (entering or diving) is a sprite pair. When an alien leaves the formation, clear its 2×2 tiles (queued VRAM writes, **budgeted per vblank**, e.g. ≤ 2 aliens per frame), then spawn the sprite at the same screen position (account for SCX) on the same frame. When it returns to its slot, reverse the process.
- **Sprite budget:** max ~6 simultaneous moving aliens, so that with the player (2), bullets and bombs the 10-per-line limit is rarely exceeded. Use the OAM rotation from Stage 04 for fairness.
- **Entry waves:** entering aliens follow the path from `paths.inc` and settle into their formation slots, as in the original (check ANALYSIS).
- If the original's formation is not static (e.g. it moves as a group), follow that behaviour.

## Sub-steps
1. **Static formation:** draw one wave's formation from `waves.inc` using BG tiles. Screenshot: confirm the layout, spacing and enemy type contrast.
2. **Formation sway + idle animation:** SCX motion and 2-frame tile animation via bulk tile-data swaps or map edits (budgeted). Prefer swapping the tile data of a single tile bank per type, and avoid rewriting the map.
3. **Path engine:** interpret path data per alien (step table, speed, 8.8 position). Draw a test alien that follows each path; the harness traces the position per frame and compares it to the `paths.json` plot from Stage 02.
4. **Entry:** wave entry with per-alien delays, ending with settling into formation slots (BG tiles drawn when it lands).
5. **Attack dives:** select attackers (rules from ANALYSIS: timing, how many, which types), run dive paths, then either leave the screen and re-enter from the top, or return to the slot as the original does.
6. **Hit handling hooks:** `alien_kill(slot)` that works for BG-resident and sprite-resident aliens (clears bitmap, tiles or sprite) — used in Stage 07.
7. **VRAM write queue:** a small ring buffer drained in vblank under a cycle budget. Assert it never overflows (debug build).

## Acceptance
- A full first-wave formation is visible with clear contrast between the types; attackers visibly leave and return with no tile glitch or double drawing.
- Harness check over 1,800 frames: sprites-per-line max is recorded, and the vblank budget isn't exceeded (no VRAM writes outside vblank — verify with a PyBoy memory write check or by corruption-free screenshots).
- `docs/PROGRESS.md` updated, with the maximum concurrent attackers actually achieved.
