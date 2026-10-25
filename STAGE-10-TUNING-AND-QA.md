# STAGE 10 — Tuning, performance and QA

**Goal:** a smooth, fast, balanced, bug-free game.
**Input:** the full game. **Output:** a final `galaforce.gb`, `docs/QA-REPORT.md`, `README.md`.

## Tasks
1. **Performance audit:** use the debug CPU bar and the harness to measure worst-case frame cost across all waves (the most attackers + bombs + bullets + explosions + audio). Report the headroom. Optimise hot loops (unrolling, lookup tables, avoiding 16-bit multiplies) if the headroom is under 15%.
2. **Sprite-limit audit:** log the max sprites per scanline across a long bot playthrough; where more than 10 occurs, adjust attacker caps, bomb positions, or bomb/bullet sizes. Confirm flicker is fair and is rarely seen.
3. **Feel tuning vs the original:** compare player speed, bullet speed, alien dive speeds and bomb speeds with the scaled originals. Since the playfield is 120 px tall instead of 256, check dive times and reaction time for bombs and tune within `docs/DECISIONS.md` limits. Make every tuning constant live in one `src/tuning.inc` file.
4. **Contrast re-check:** render screenshots of every wave using the 4-green palette and the grey palette. Fix any enemy types that blur together or any sprites lost against stars.
5. **Robustness:** a long random-input bot run (≥ 200,000 frames, a few seeds) with no crash, no stuck wave, no VRAM corruption, and no stack overflow (fill the stack with a canary and check it). Test on a second emulator (mGBA headless or SameBoy) if available, and check that the ROM header and checksums are valid (`rgbfix -v`).
6. **Accuracy edge cases:** hit the same alien with two bullets in one frame, kill during entry, die at the instant of wave clear, pause during explosion, pressing Start while dying, score overflow (cap at 999999), lives cap.
7. **Docs:** `README.md` with build instructions, controls, differences from the original, credits (Kevin Edwards / Superior Software for the original), "personal project, not for distribution". `docs/QA-REPORT.md` with all measurements and open issues.

8. **Wave 11 stall (open bug, found in the godmode soak):** with `make god` and `CHEAT=1 tools/bot.py`, the run sat at wave 11 for ~3,000 frames and the wave never ended. The remaining aliens were on looping paths (e.g. path data at 0x18f2, which ends `0,0`). In the original these loop until shot. Check that every looping alien can be reached and shot in the 128 px playfield, that its loop doesn't leave the player's firing range, and whether the bot is simply failing to hit it. If it is a real port bug, fix it (a wave-timeout fallback that makes survivors fly off is an acceptable last resort). Then rerun the soak through all 16 waves.

## Acceptance
- Headroom ≥ 15% of the frame at worst case, or documented and justified.
- Sprite-per-line overflow occurs rarely and only in documented situations.
- Bot runs pass; `rgbfix -v` passes.
- `docs/PROGRESS.md` final update, and a summary to the user of what's done and what's left.
