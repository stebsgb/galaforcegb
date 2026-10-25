# STAGE 09 — Title, game over, hi-score, polish

> **Status/as built:** see `docs/DECISIONS.md` and `docs/PROGRESS.md`; the design changed (all-sprite aliens, custom audio driver, 128 px playfield, MBC1 SRAM). Where this file disagrees, those win.

**Goal:** the frame around the game, as in the original.
**Input:** Stages 03–08, `docs/ANALYSIS.md` (TITLE, HIGH). **Output:** `src/title.asm`, `src/gameover.asm`, `src/hiscore.asm`, header update for SRAM.

## Tasks
1. **Title screen:** the Galaforce logo (recreated from the original's title look), "PRESS START", the original title music, a scrolling starfield, and a demo/attract mode only if the original has one (check ANALYSIS).
2. **Game over screen:** message, final score, jingle, return to title after the timeout or on Start.
3. **Hi-score:** the original's entry mechanism (HIGH.asm — name entry or just a score). Implement the same. Persist in cartridge SRAM: change the header to MBC1+RAM+BATTERY with 8 KB RAM (or the smallest permissible), with checksum and default init. Keep the ROM 32 KB if possible. Note any header/mapper change in `docs/DECISIONS.md`. If SRAM is unreliable in the emulator, keep the RAM-only hi-score and mark persistence as optional.
4. **Pause:** Start toggles the pause, screen dims (palette swap) and the music is paused.
5. **Wave banners:** "WAVE n" text between waves as in the original, using the BG/window text routines.
6. **Soft reset:** A+B+Start+Select returns to the title.
7. **Polish list:** a screen shake or palette flash on player death, an enemy hit flash using palette swap, a clean fade in/out between screens using BGP steps.

## Acceptance
- A scripted run goes: title → play → die ×N → game over → title, with the hi-score updated and retained after a reset (save RAM check in the harness).
- Screenshots of each screen in `build/screens/stage09_*.png`.
- `docs/PROGRESS.md` updated.
