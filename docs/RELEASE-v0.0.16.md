# Galaforce for Game Boy v0.0.16

Build: `galaforce-0.0.16.gb` (MBC1 + RAM + battery, 32 KB ROM).

## New
- **Dynamic boss hit scaling.** The first boss (wave 3 / ZONE 04) takes 20 hits to destroy. Later bosses (waves 7, 11, 15 / ZONES 08, 12, 16) take 25 hits. Cosmetic explosions continue during the last 5 hits for both variants.
- **Boss hit tracking.** Added `wBossHits` RAM variable and `SetBossHits` function that sets hit count based on current wave.

## Changes
- **Boss spawn logic updated.** `FillAlien` in `src/aliens.asm` now uses `wBossHits` for type‑5 boss aliens instead of the static `alien_hits` table value.
- **Build improvements.** `.gitignore` updated to ignore `*.sav` save files and `.DS_Store` metadata.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts on ZONE 04 (the first boss wave) for testing.

## Build
- `make` builds `galaforce-0.0.16-SNAPSHOT.gb` from `VERSION` in the Makefile.
- `make god` builds `galaforce_god.gb`, which cannot die (used for headless checks).

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16) is reduced but not fixed. Aliens can still overlap on some lines.
- The GB crest is built into the title graphics but not shown on the title screen.