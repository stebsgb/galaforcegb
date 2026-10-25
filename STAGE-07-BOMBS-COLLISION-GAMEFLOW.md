# STAGE 07 — Bombs, collisions, lives, score, waves

> **Status/as built:** see `docs/DECISIONS.md` and `docs/PROGRESS.md`; the design changed (all-sprite aliens, custom audio driver, 128 px playfield, MBC1 SRAM). Where this file disagrees, those win.

**Goal:** a complete, playable loop from wave 1 upward.
**Input:** Stages 05–06, `docs/ANALYSIS.md` (BOMBS, FLAGS, HIGH, WAVE sections). **Output:** `src/bombs.asm`, `src/collide.asm`, `src/explode.asm`, `src/game.asm`, `src/hud.asm`.

## Tasks
1. **Bombs:** spawn rules, speeds, concurrency limits per the original. Bomb sprites, with a cap that respects the sprite budget. Bomb-vs-player collision.
2. **Collisions:** AABB tests, using the box sizes from ANALYSIS scaled to the DMG sprite sizes. Bullet↔alien (both for sprite-resident aliens and BG-resident formation aliens, by mapping bullet position to the formation grid slot, which is far cheaper than looping all aliens). Alien↔player body collision. Early-out loops, and a cycle-budget check in the debug build.
3. **Explosions:** an animated 16×16 sprite for aliens, and a longer one for the player. The pool is small (≤3).
4. **Player death and lives:** lose life on a hit, respawn blink, game over when none are left. Starting lives, extra lives and scoring values from ANALYSIS.
5. **Scoring/HUD:** top row: `SCORE` and `HI` as BCD, updated through the VRAM queue, with the BCD add routine. Bottom window: lives icons and level number. Update only on change.
6. **Wave progression:** wave complete detection (formation empty, no attackers/bombs), a short between-wave pause, next-wave data load from `waves.inc`, difficulty parameters. Loop the wave set with increased speed as the original does.
7. **State machine:** `STATE_TITLE`, `STATE_PLAY`, `STATE_DYING`, `STATE_WAVE_CLEAR`, `STATE_GAMEOVER`, `STATE_PAUSE` (Start button). Stub the title/game-over screens (finished in Stage 09).
8. **Scripted playtest:** a harness bot that sweeps and fires, to run a few thousand frames and report waves cleared, score and any crash, stuck state or sprite overflow.

## Acceptance
- A bot run clears wave 1 and progresses to wave 2+ with correct score changes and no crashes over ≥ 10,000 frames.
- Player can die, lose lives, reach game over and restart.
- `docs/PROGRESS.md` updated. List any behaviours that differ from the original.
