# STAGE 12 — Options menu (lives, white-background mode)

**Status: PLANNED.**
**Goal:** an OPTIONS screen reachable from the title, with (1) the number of starting lives and (2) a choice of black or white playfield background, with sprite art that stays high-contrast in both. Settings persist in battery RAM.
**Input:** Stages 1–11 as built. **Output:** `src/options.asm`, edits to `screens.asm`, `game.asm`, `save.asm`, `save` layout, `tools/gen_art.py` (inverted-contrast art variants), `docs/DECISIONS.md`, `docs/PROGRESS.md`.

Do the tasks in order and run the acceptance checks after each one.

## Task 1 — Title menu
- Title shows two items: `START GAME` and `OPTIONS`, with a `>` cursor tile (add a font glyph or reuse `>`-like tile). Up/Down move, A or Start selects. Keep the existing centring rules (strings centred on 20 columns, `HudNum` writes leading blanks so print numbers before labels).
- Idle timer for the demo (Stage 11) keeps running on the title but is reset on any key press, and does not run on the options screen.
- Selecting OPTIONS: `FadeOut`, `ShowOptions`, `FadeIn`. B or Start on the options screen returns the same way.

## Task 2 — Lives setting
- Options row `LIVES`: values 1..5, default 3 (the original). Left/Right change it, with wrap or clamp (choose clamp).
- Store in `wOptLives`. `StartGame` loads `wLives` from it instead of the hard-coded 3.
- The HUD lives display and the extra-life cap (`cp 5` in `AddScoreInner`) must cope with the max. Confirm the bottom strip fits the maximum number of ship icons; if not, show a ship icon plus a number above 3.
- The hi-score table is shared across settings; optional: only save a hi-score when lives <= 3 so that easy modes do not pollute it. Record the decision in `docs/DECISIONS.md`.

## Task 3 — Background setting (white mode)
Playfield background: `BLACK` (default) or `WHITE`. This is a palette and art question, not a map change.
- BG palette for white mode: swap the BG shade order (`BGP = %11100100` style: colour 0 = white). Stars, which are BG tiles, then need to be dark: either reuse the star tile colour index that maps to black, or add a second star tile set. Verify stars remain visible.
- **Sprite contrast is the main work.** The current OBJ art was designed against black: bright ships and aliens with grey details. On white, bright shapes vanish. Plan:
  1. Keep the OBJ palettes but add a second set of tiles?  Do not do this: ROM and VRAM budgets are tight. Instead use palette swaps first: `OBP0/OBP1` with the shade order inverted so the sprite's lightest shade becomes black and the outline/darkest becomes white. Preview every sprite sheet in both modes with `tools/preview_sprites.py` (add a `--white` flag that renders against a white background with the inverted OBP).
  2. If a sprite loses its internal detail after inversion (the 4 shades map 1:1, so detail is preserved but the silhouette reads differently), add per-sprite fixes in `gen_art.py` only if the preview shows a problem. The enemy types must remain distinguishable from each other: check the type-contrast table (the 12 alien types) for both modes, and bullets and bombs must stay visible against white.
  3. Explosions use OBP shades too; check them.
- HUD/window text is BG: in white mode it should be black on white (invert BG palette, so no change in tiles).
- Fades: add a `fadeBGP_white` set that fades toward white instead of black (white-mode fade-out goes to white). `ApplyPalettes` selects the table set by `wOptBg`.
- Pause dim and the death flash need white-mode equivalents (the flash currently writes `rBGP` directly, so make it read the current base palette).
- Title and options screens follow the chosen mode.

## Task 4 — Persistence
- Extend the SRAM block at `$A000` (currently `"GF"` magic, 7 hi-score digits, checksum): add `lives` and `bg` bytes and keep the checksum covering them. Bump the magic or version byte so old saves are treated as defaults rather than rejected with garbage. Settings are saved when leaving the options screen.
- Validate on load: lives clamped to 1..5, bg 0/1.

## Task 5 — Tests and docs
- `tools/optionstest.py`: drive the menu with the pad in PyBoy: set lives to 5 and bg to white, start a game, assert `wLives == 5`, assert BGP/OBP values for white mode, reboot with the same `.ram` and assert persistence. Take screenshots of the options screen and of a wave in both modes, and view them.
- Run the existing `savetest.py`, `demotest.py`, the god soak (`make god`, 20000 frames) and `audit.py`; none may regress.
- Update `README.md`, `docs/DECISIONS.md`, `docs/PROGRESS.md`.

## Risks / notes
- Sprite contrast in white mode is subjective and cannot be fully judged by measurement; give the user screenshots from both modes and iterate on feedback.
- The demo (Stage 11) must run with the user's chosen settings for palette but with 3 lives and its normal behaviour (it is invulnerable anyway).
- Keep the ROM at 32 KB; the options screen is small.
