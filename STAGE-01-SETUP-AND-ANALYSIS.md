# STAGE 01 — Setup and source analysis

**Goal:** working toolchain, a headless test harness, and a written analysis of the original game that later stages rely on.
**Input:** `00-OVERVIEW.md`. **Output:** `Makefile`, `tools/`, `ref/`, `docs/ANALYSIS.md`, `docs/DECISIONS.md`, `docs/PROGRESS.md`, a "hello" ROM that builds.

## Tasks
1. **Toolchain check.** Look for `rgbasm`, `rgblink`, `rgbfix`, `rgbgfx`, `python3`, `make`. Install missing ones (Homebrew `rgbds`; pip `pillow`, `numpy`, `pyboy`). If the shell can't install, say so and stop.
2. **Clone reference.** `git clone https://github.com/KevEdwards/Galaforce1BBC ref/` and add `ref/`, `build/` to `.gitignore`.
3. **Harness.** Write `tools/run_headless.py` using PyBoy (null window): loads a ROM, runs N frames, optionally presses buttons from a script, saves a screenshot PNG and can dump WRAM/OAM. This is the main way to verify later stages. Also note a fallback (mGBA with a Lua script, if installed).
4. **Skeleton ROM.** `src/main.asm` with a valid header (title `GALAFORCE`, DMG-only, ROM-only 32 KB), a vblank wait, and a tile drawn on screen. `Makefile` builds `galaforce.gb`. Prove it with a harness screenshot.
5. **Analyse the original** by reading every file in `ref/src` and `ref/object`. Write `docs/ANALYSIS.md` with these sections:
   - Memory map and the main loop order (what runs each frame, in what order).
   - Object model: alien slots, how many exist at once, per-slot fields, state machine.
   - Waves/levels: how many, how each is defined (WAVE, PATT, PATDAT), number and mix of enemy types, formation grid (rows × columns, spacing), entry order and timing.
   - Alien motion: the envelope/path format (O.ALLENV1, PATDAT), step units, speeds in pixels per frame at the original frame rate.
   - Bombs: spawn rules, speeds, limits (BOMBS1/2).
   - Player: speed, fire rate, bullet count limit, collision box sizes.
   - Scoring values per enemy type, bonus rules, extra lives, starting lives.
   - Enemy types: list every distinct type with a short description of look and behaviour.
   - Stars: count, speeds, layers.
   - Sprite format (Mode 5 bitplane layout, sprite dimensions) and the data tables in SPRITES/O.GRAPHIC.
   - Music/sound: how MUSIC1–3 are structured (note tables, durations, channel assignment) and which sound effects exist.
   - Timing: original frame rate (BBC runs at 50 Hz) → factor for converting speeds to 60 Hz DMG.
   - Update the file map in `00-OVERVIEW.md` if it is wrong.
6. **Initial `docs/DECISIONS.md`** with the locked decisions and the vertical playfield size change (original 256 px → 120 px playfield). Note how speeds/distances will be scaled.
7. **`docs/PROGRESS.md`** created with the stage checklist.

## Acceptance
- `make` produces `galaforce.gb`; `tools/run_headless.py` renders a PNG that shows the test tile.
- `docs/ANALYSIS.md` covers every bullet above with file references. Unknowns are flagged as "TODO/uncertain", not guessed.
