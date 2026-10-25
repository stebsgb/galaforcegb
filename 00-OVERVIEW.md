# Galaforce → Game Boy DMG — Project Overview

Personal project. Port of Kevin Edwards' BBC Micro Model B *Galaforce* (source: https://github.com/KevEdwards/Galaforce1BBC) to the original Game Boy (DMG, 4 shades, no colour).

These files are instructions for an AI coding agent. Work through the stages in order (`STAGE-01` … `STAGE-10`). Each stage is sized to fit in one working session, has a clear input, output and acceptance test, and leaves the repo in a working state. Do not start a stage until the previous stage's acceptance checks pass.

## Locked decisions
| Topic | Decision |
|---|---|
| Toolchain | Pure SM83 assembly, RGBDS (`rgbasm`, `rgblink`, `rgbfix`, `rgbgfx`). Python 3 for tooling. Make for build. |
| ROM | 32 KB. As built: MBC1+RAM+battery header (8 KB SRAM for the hi-score); the ROM itself is still 32 KB. |
| Layout | Score and hi-score at the TOP (like the original). Lives (and level) at the BOTTOM (like the original). Playfield between. |
| Screen split | 160×144 = 8 px score row + 128 px playfield + 8 px bottom lives strip (as built) (Window layer). |
| Formation | As built: all aliens are sprites (two 8x16 objects each) following the original path scripts; no BG formation. |
| Sprites | 8×16 sprite mode. Aliens are hand-redrawn 16×16 (2 sprites). Recreated from the original, not copied pixel for pixel. |
| Frame rate | 60 fps locked to vblank. 8.8 fixed point motion. Shadow OAM + HRAM DMA routine. |
| Audio | As built: custom 3-channel driver (not hUGEDriver) for music, with SFX that borrow channels. Sound and tunes follow the original. |
| Scope | Personal use. Not for distribution. |

## Source map (original repo, `src/` and `object/`)
| Area | Files |
|---|---|
| Constants, zero page, work areas | CONST, ZPWORK, ABSWORK |
| Init, vectors, title, flags | INIT, VECTORS, TITLE, FLAGS |
| Aliens, wave/level control | ALIENS1–4, WAVE, PATT, PATDAT |
| Bombs (enemy fire) | BOMBS1, BOMBS2 |
| Player, routines, collision | CHARP, ROUT1–4, DOWN |
| Stars, high score | STARS, HIGH |
| Sprites | SPRITES, object/O.GRAPHIC, O.SPFONT, O.DIGITS, O.DOWN |
| Alien motion envelopes | object/O.ALLENV1 |
| Music | MUSIC1–3 |

Stage 01 verifies this map. It is a first estimate from the file list and sizes only.

## Target repo layout
```
galaforcegb/
  00-OVERVIEW.md, STAGE-*.md      (these plans)
  Makefile
  docs/        ANALYSIS.md, DECISIONS.md, SPRITE-SHEET.md, AUDIO.md, PROGRESS.md
  ref/         cloned original repo (read only, git-ignored)
  tools/       python scripts (extract, convert, render, test helpers)
  assets/      png sources (tiles, sprites, font), hugetracker .uge
  src/         *.asm  (main, hardware.inc, engine, player, aliens, ...)
  build/       outputs (git-ignored)
  galaforce.gb
```

## Working rules for the agent
1. Read `docs/PROGRESS.md` first; update it at the end of every stage (what's done, what's next, known issues).
2. Keep a build that runs at all times. Run `make` after each meaningful change; fix errors before moving on.
3. Verify with an emulator headlessly where possible (see STAGE-01 for the test harness). Don't claim a feature works without a screenshot, memory dump or test.
4. Record each decision that differs from the original in `docs/DECISIONS.md` with the reason.
5. Respect the hardware budgets: ≤10 sprites per scanline, ≤40 OAM entries, vblank work ≤ ~1,100 cycles beyond OAM DMA, main-loop work finished within one frame.
6. Don't copy the original's art byte for byte into the final ROM assets. Use it as reference and redraw it for the DMG grid.
7. Keep commits small, one per stage minimum (only if the user asks for commits).

## Stage list
| # | File | Goal |
|---|---|---|
| 01 | STAGE-01-SETUP-AND-ANALYSIS.md | Tools, clone, harness, source analysis |
| 02 | STAGE-02-ASSET-EXTRACTION.md | Decode original graphics, data, music to usable files |
| 03 | STAGE-03-DMG-ART.md | Redrawn DMG tiles/sprites, contrast tested |
| 04 | STAGE-04-ENGINE-CORE.md | Boot, vblank loop, OAM DMA, input, split screen, stars |
| 05 | STAGE-05-PLAYER-AND-BULLETS.md | Ship, firing, bullets |
| 06 | STAGE-06-FORMATION-AND-ATTACKERS.md | (as built: all-sprite) attackers, paths, hand-over |
| 07 | STAGE-07-BOMBS-COLLISION-GAMEFLOW.md | Bombs, collisions, explosions, lives, score, waves |
| 08 | STAGE-08-AUDIO.md | Music and sound effects |
| 09 | STAGE-09-SCREENS-HISCORE-POLISH.md | Title, game over, hi-score, SRAM |
| 10 | STAGE-10-TUNING-AND-QA.md | Performance, difficulty, flicker, final checks |

| 11 | STAGE-11-DEMO-AND-FADES.md | Attract-mode demo and fades (done) |
| 12 | STAGE-12-OPTIONS-MENU.md | Options menu: lives, white background (planned) |
