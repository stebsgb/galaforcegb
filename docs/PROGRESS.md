# Progress

| Stage | Status |
|---|---|
| 01 Setup & analysis | done |
| 02 Asset extraction | done |
| 03 DMG art | done (sprites flipped upright, symmetry preserved) |
| 04 Engine core | done (different layout than planned, see DECISIONS.md) |
| 05 Player & bullets | done |
| 06 Attackers | done (all-sprite design) |
| 07 Bombs, collisions, flow | done |
| 08 Audio | done (custom driver; effects/music mix tuned for punch) |
| 09 Screens, hi-score, polish | title centred; SRAM hi-score; pause dim; soft reset; death flash. Demo mode and fades done in Stage 11 |
| 11 Demo & fades | done (`src/fx.asm`, `tools/demotest.py`) |
| 12 Options menu | planned (`STAGE-12-OPTIONS-MENU.md`) |
| 10 Tuning & QA | partial: 200k-frame god-mode soak (79 waves, no crash), frame-drop and sprite-per-line audit done. See QA below |

## QA notes
- Soak: `make god && .venv/bin/python tools/bot.py galaforce_god.gb 200000` reached wave 79, min SP 0xFFF2, no crash.
- Frame budget: `tools/audit.py galaforce_god.gb 60000` -> 2 dropped frames in 60000.
- Sprites per line: max 28 objects on a line (hardware shows 10) in the densest waves; overflow in ~30% of frames of the bot run, shared by rotation flicker. Possible improvement: cap simultaneous aliens per row or prioritise by type.
- "Wave 11 stall" was NOT a bug: armored aliens (10 hits) make that wave last ~4000 frames for the weak bot. Consider balancing the fire rate / hits if it feels slow.
- Persistence: `tools/savetest.py` (play, beat hi-score, game over, reboot) passes.
- Fixed: alien vertical speed was half of the original; collision now uses the drawn Y (no deaths without contact).
- Stage 12 done: options menu (lives 1-5, black/white background), persisted in SRAM `$A010`; `tools/optionstest.py` passes. Makefile now rebuilds gfx when `font5x7.py` changes.
- White background is now the default (a saved setting still overrides it).
- Title redesigned after the BBC original: HUD line (SC/HI) on top, wide red-style GALAFORCE, BY KEVIN EDWARDS, SUPERIOR SOFTWARE, flags bottom-left, static starfield.
- Title stars are falling sprites (behind the logo and text via BG priority, two speeds and palettes), like the in-game starfield; the logo also gets an occasional grey shine sweep (every ~8.5 s).
- Enemy bombs (all waves; extra random bombs from wave 4) redrawn as a fat 6x12 solid drop in the max-contrast palette index, visible in both background modes.
- Cheat: on the options screen press UP UP DOWN DOWN SELECT to reveal a LEVEL row (1-16, not saved; demo ignores it). Test: tools/cheattest.py.
