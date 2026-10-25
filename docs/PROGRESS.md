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
- Title redesigned after the BBC original: HUD line (SC/HI) on top, wide red-style GALAFORCE, GAME BOY EDITION headline, small credit (BBC ORIGINAL 1986 / KEVIN EDWARDS / SUPERIOR SOFTWARE) for the original author and publisher, flags bottom-left.
- Title stars use the in-game method: the $9C00 star map scrolled via LYC splits between the text rows (TitleStat, waits for HBlank before switching); the logo also gets an occasional grey shine sweep (every ~8.5 s).
- Enemy bombs (all waves; extra random bombs from wave 4) redrawn as a fat 6x12 solid drop in the max-contrast palette index, visible in both background modes.
- Cheat: on the options screen press UP UP DOWN DOWN SELECT to reveal a LEVEL row (1-16, not saved; demo ignores it). Test: tools/cheattest.py.
- Wave 3 eased (playtest: sometimes no gap to shoot through): in StartPattern, streams with delay <= 16 are spaced x1.5 and carry 3/4 as many aliens. Other waves unchanged.
- Aliens whose path ends (die opcode) off the top edge (y<24 or >=224) now vanish quietly instead of exploding in the top corners (seen on waves 5, 6 and 11).
- Flicker: alien OAM draw order now strides over the slots (ALSTEP=9) instead of rotating by one, so an overflowing alien is hidden 1-3 frames at a time (was 7-10 on the boss wave). tools/flicker.py measures hidden-run lengths. Boss rows are ~8 px apart on screen vs 16 px sprites; re-spacing them to 16 px cuts hidden alien-frames 61% -> 47% but changes the layout (not applied).
- Boss wave (levels 4/8/12/16): rows re-spaced vertically and thinned to 8 aliens at double spacing (gen_data.py, pattern 45) so ~5 abreast fit the 10-objects-per-line limit; alien OAM order now alternates two halves per frame (ROTSTEP=7, 30 Hz) instead of a 1-slot rotation or scatter (shimmer). Bullets no longer hit aliens still above the top edge (fixes phantom explosions in the top corners on the looping 'hoop' patterns).
- Path-end 'die' now vanishes silently for y < 40 (the whole top row), not just y < 24: wave 4 pattern 2 ended at y~34 and exploded visibly at the top.

- Corner explosions: aliens in the entry/exit band (orig y < 40 or above the top) can no longer be shot, matching the quiet end-of-path vanish. Boss alone now drops a bomb about every 16 frames (its path has no bomb opcodes); with company the drop opcode gate is looser.

- Anti-camping: if the ship has not moved for 120 frames, new bombs are aimed at its x (wStill in StatePlay, InitBomb). Only affects levels where aliens drop bombs.

- Anti-camping revised: after 240 still frames (4s) a live alien within 4px of the ship x drops a bomb (AimedBomb, every 16 frames); bombs always originate from a real alien. The earlier x-teleport was removed.

- Wave 4 hoop corner glitch: aliens parked at original y=255 (above the top) were drawn at the top corners; BuildOAM now skips aliens whose FieldY is negative.

- Aliens spawning at x<8 (wave 4 patterns 10/11 at the top-left corner) now slide in from behind the left edge instead of popping in.

- Hoop (wave 4) aliens wrap past y=255 to y=5..17 for a few frames before their quiet vanish, which showed as pop-ins in the top corners. Aliens with field y < 8 are no longer drawn.

- Boss rows raised (y 80/128 instead of 80/150) so the formation sits closer to the original; flicker metric unchanged (32% hidden alien-frames).

- Boss alone fires a little less: bomb chance per frame 1/16 -> 1/32.

- Options: alien/ship preview moved down 16px and hints down a row so BACK is not cramped. Title: removed GAME BOY EDITION line (logo one row lower than the original; the star-scroll text bands in titleSegs were shifted to match).

- Wave 12 deep U (path 22, used only there) bottomed out at original y=240, under and below the ship where it could not be shot (and was hidden by the above-top rule). Its vertical movement is now scaled to 3/4 (bottom y=188, above the ship line). Other paths untouched.

- Boss death is now grand: for ~1.6 s (24 explosion steps) six staggered explosions burst over and around the boss (BossBoom in render.asm, bossBoomOfs), a boom plays every 4th step, then one final blast. Small aliens unchanged.

- The boss only gets the grand explosion when shot; when the player dies it uses the normal short explosion.

- Cheat options now also have CONTINUES (0..3, default 0, not saved). At game over with continues left the screen asks CONTINUE? >YES / NO (d-pad toggles, A/START confirms): YES refills lives, keeps the score and replays the wave; NO ends the game. Options rows moved up one row to fit. tools/continuetest.py covers it.
