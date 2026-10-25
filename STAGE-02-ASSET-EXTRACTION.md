# STAGE 02 — Asset and data extraction

**Goal:** turn the original's binary/graphic/music/path data into inspectable files and ROM-ready tables.
**Input:** `ref/`, `docs/ANALYSIS.md`. **Output:** `tools/extract_*.py`, `assets/ref/*.png`, `docs/SPRITE-SHEET.md`, `docs/AUDIO.md`, `build/data/*.inc` (generated).

## Tasks
1. **Sprite decode.** Write `tools/extract_sprites.py` that decodes the Mode 5 (4 colour, 2 px per bit-pair interleaved) data from `object/O.GRAPHIC`, `O.SPFONT`, `O.DIGITS`, and sprite tables in `src/SPRITES.asm`/`CHARP.asm`. Output each sprite as a PNG on a labelled contact sheet, at 8× zoom, plus a catalogue in `docs/SPRITE-SHEET.md` (id, name, size in original pixels, enemy type, animation frames).
   - Correct the aspect ratio in the preview: BBC Mode 5 pixels are about 2:1 (wide), so also output a "square pixel" view.
   - Cross check with `screenshot.png` in the repo to confirm the decode.
2. **Font and digits.** Decode the score font and digit set to PNG.
3. **Path/envelope data.** Write `tools/extract_paths.py` to parse `O.ALLENV1` and `src/PATDAT.asm`/`PATT.asm` into JSON (`assets/ref/paths.json`) and render each path as a plotted PNG (a trace over a 160×120 grid) so it can be seen.
4. **Wave data.** Parse `src/WAVE.asm`/`ALIENS*.asm` tables into `assets/ref/waves.json`: per wave, enemy type, formation slot, path id, entry delay.
5. **Music/SFX data.** Parse `MUSIC1–3.asm` into `assets/ref/music.json` (per channel: note, duration, volume/envelope) and render a plain text score per tune. Decode the sound effect parameters from the code, if any. Document in `docs/AUDIO.md`, including the note-to-frequency table used and the BBC SN76489 clock formula so notes map to correct pitch.
   - Optional: render a WAV of each tune with a small Python SN76489 emulation to compare with the DMG version later.
6. **Generators.** Make `tools/gen_tables.py` that emits `build/data/paths.inc`, `waves.inc` ready for RGBDS (`db`/`dw`), with speeds scaled by the 50→60 Hz factor and the playfield scale from `docs/DECISIONS.md`. Hook into `make`.

## Acceptance
- Contact sheet PNGs exist and the sprites are recognisable and match the repo screenshot.
- `paths.json`, `waves.json`, `music.json` are produced and every wave in the original is represented.
- Generated `.inc` files assemble without errors.
- `docs/SPRITE-SHEET.md` and `docs/AUDIO.md` are written. Update `docs/PROGRESS.md`.
