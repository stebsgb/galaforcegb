# STAGE 03 — DMG art: recreated tiles and sprites

**Goal:** recreate all graphics for the 4-shade DMG, 16×16 aliens, with strong contrast between enemy types.
**Input:** `assets/ref/*.png`, `docs/SPRITE-SHEET.md`. **Output:** `assets/*.png` (indexed 4-shade), `tools/gen_gfx.py`, `build/gfx/*.2bpp`, `docs/ART-NOTES.md`, preview screenshots.

## Rules
- Shades: 0 = lightest, 3 = darkest. Playfield background is shade 0 (light) or shade 3 (dark) — pick by testing which gives the best contrast, record in `docs/ART-NOTES.md`. Default proposal: dark space (shade 3) with light sprites, plus sparse stars at shade 1.
- Recreate, don't copy: keep each original's silhouette, structure and animation idea, redrawn on the 8×8 tile grid. The result should be recognisable as the original sprite.
- Each enemy type must be told apart with the 4 shades off: distinct silhouette, distinct internal pattern (solid, dither, outline) and, where possible, a different palette (OBP0 vs OBP1).
- Aliens: 16×16 (two 8×16 sprites side by side). Player ship: 16×16. Bullets: 8×8 within an 8×16 object (or 8×16 designed). Bombs: 8×16 or 8×8. Explosion: 3–4 frames, 16×16.
- Budget tiles: sprites ≤ 256 tiles (VRAM $8000 block), BG tiles share $8800–$97FF with sprites in a tile-map plan. Write a tile budget table.

## Tasks
1. Create PNG sources with `tools/draw_*.py` (generate pixel art from ASCII grids in Python) or edit existing PNGs. ASCII-grid art in a source file is preferred, since it is easy to diff and tune.
2. Cover: every enemy type (all animation frames), player ship (+ thruster frame), player bullet, enemy bomb(s), explosion frames, formation BG tiles (for each enemy type, 2×2 tiles per alien, with matching idle animation frames), star tile(s), HUD font (score digits, letters for title/hi-score), life icon, title logo tiles.
3. `tools/gen_gfx.py` converts the PNGs to 2bpp (`rgbgfx` or custom), emits `build/gfx/*.2bpp` and `build/gfx/tiles.inc` with tile index constants (`TILE_ALIEN1_A`, etc.).
4. **Contrast test:** `tools/preview.py` composites all enemy types in the formation layout on the target background at 160×144, using the 4 DMG greens (classic `#9BBC0F, #8BAC0F, #306230, #0F380F`) and also pure greyscale (Pocket). Save `build/preview_green.png` and `build/preview_grey.png`. Also output a "squint test" version converted to 2 shades to verify that types remain distinguishable. Revise the art until they are.
5. Write `docs/ART-NOTES.md`: palette choices, per-type look, tile map, and VRAM budget.

## Acceptance
- All art exists, converts, and assembles into the ROM with symbols for each tile range.
- The previews show a full formation with every enemy type clearly separable. Review the images yourself (view the PNG) and note any weak pairs fixed.
- `docs/PROGRESS.md` updated.
