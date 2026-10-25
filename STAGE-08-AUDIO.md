# STAGE 08 — Music and sound effects

> **Status/as built:** see `docs/DECISIONS.md` and `docs/PROGRESS.md`; the design changed (all-sprite aliens, custom audio driver, 128 px playfield, MBC1 SRAM). Where this file disagrees, those win.

**Goal:** music and SFX that follow the original BBC Galaforce.
**Input:** `assets/ref/music.json`, `docs/AUDIO.md`. **Output:** `assets/music/*.uge` (or `.asm` song data), `src/audio.asm`, `src/sfx.asm`, `docs/AUDIO.md` updated.

## Approach
- Player: **hUGEDriver** (vendor it into `lib/hUGEDriver/`; fetch from the official GitHub repo; record version and license in `docs/DECISIONS.md`).
- Song data: generate hUGETracker-compatible song data from `music.json` with a Python converter (`tools/music_to_huge.py`), so the original notes are transcribed exactly. If generating `.uge` is impractical, emit hUGEDriver's `.asm` song format directly (read the driver's `hUGE.inc` / song format docs first).
- Channel mapping: SN76489 tone 1 → DMG pulse 1; tone 2 → pulse 2; tone 3 → wave channel (bass/harmony); SN noise → DMG noise. Use duty and envelope choices that approximate the BBC timbre (square/bright).
- Tempo: convert the BBC timing (50 Hz tick) to the DMG's 60 Hz ticks (hUGE speed + tempo or adjusted durations) so tunes play at the original tempo.

## Tasks
1. Convert the title tune and the in-game tune(s). The in-game music should loop cleanly.
2. SFX engine: priority-based, SFX borrow pulse 1 and/or noise only for the duration of the effect and then restore the music channel state (mute/unmute channel via hUGE `hUGE_mute_channel`).
3. Effects needed (match the original's list from ANALYSIS): player fire (short pulse sweep down), alien explosion (noise, decaying), player death (long noise/pulse sweep), bomb drop (if present), extra life/bonus jingle, wave start, game over jingle. Keep each effect ≤ ~30 bytes of data.
4. Hook into the game events from Stage 07 (calls only, no logic changes).
5. Audio test: the harness (PyBoy) captures audio (`sound` enabled) to WAV for the title tune, the in-game tune, and each SFX. Render the original (SN76489 emulation from Stage 02) to WAV and compare note sequences and tempo by analysing pitch tracks (simple FFT/zero-crossing), recording the match in `docs/AUDIO.md`.
6. CPU: audio update runs once per frame; make sure it fits in the frame budget (check with the debug load bar).

## Acceptance
- Title and gameplay tunes play with the right note sequence and tempo (pitch-track comparison report).
- SFX trigger without audible music glitches, and the channel is restored.
- ROM still ≤ 32 KB, or the MBC decision is recorded.
- `docs/PROGRESS.md` updated.
