# STAGE 11 — Attract-mode demo and screen fades

**Status: DONE** (see `src/fx.asm`, `tools/demotest.py`).
**Goal:** the title screen idles into a self-playing demo, and screen changes fade through black.
**Input:** Stages 1–10 as built. **Output:** `src/fx.asm`, small hooks in `game.asm`, `screens.asm`, `save.asm`, `main.asm`.

## Design as built
- **Fades:** `wFade` 0..3 (0 normal, 3 black). `ApplyPalettes` (in `save.asm`) picks palettes from `fadeBGP/fadeOBP0/fadeOBP1[wFade]`. Each step darkens every shade by one. Pause is the same as fade level 1. `FadeOut` (3 steps x 5 frames) and `FadeIn` are blocking; they call `FadeWait`, which halts for VBlank, runs the OAM DMA and keeps `AudioUpdate` running so music continues.
  - Gotcha found: `AudioUpdate` and `ApplyPalettes` clobber `bc`; the fade loops save it.
  - Used on: boot (fade in), title -> game, game over -> title, demo start/exit.
- **Demo:** after `IDLE_HI`*256 idle frames (768, about 13 s) on the title, `StartDemo` saves the hi-score to `wHiBak`, sets `wDemo`, seeds the RNG to a fixed value and starts a normal game from wave 1. `DemoInput` (called after `ReadKeys`) replaces the pad with an auto-pilot: hold A, move to the nearest on-screen alien, sweep when none. The ship is invulnerable (`CollidePlayer` returns early). "DEMO" is shown in the bottom strip. Start, or `DEMO_FRAMES_HI`*256 frames (1792, about 30 s), returns to the title through `ReturnToTitle`, which restores the hi-score. `SaveHi` is skipped in demo.
- Soft reset (A+B+Select+Start) still works everywhere.

## Acceptance (all passing)
1. `tools/demotest.py`: the title idles into the demo after about 750 frames, the demo scores, Start returns to the title, the hi-score is unchanged, and Start then starts a real game with `wDemo=0`.
2. `tools/savetest.py` still passes; `tools/bot.py galaforce_god.gb 20000` has no crash and min SP 0xFFF2.
3. `tools/audit.py` reports 0 dropped frames during play (fade frames excluded).

## Possible follow-ups
- A demo that shows a "GAME OVER" sequence, or cycles through several waves (e.g. start on wave 3).
- Fade during wave transitions or on death.
