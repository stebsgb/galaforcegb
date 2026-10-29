# Galaforce for Game Boy v0.0.16

Build: `galaforce-0.0.16.gb` (MBC1 + RAM + battery, 32 KB ROM).

## New
- **Wave multipliers.** Clear enough aliens in a pattern and the points you scored for that pattern are multiplied when it ends. Killing more than 80% of the aliens gives ×2. Killing every alien gives ×5. The multiplier is paid at the end of each pattern, not at the end of the zone.
- **Multiplier display.** The `X2` or `X5` text flashes beside the score when a multiplier is paid.
- **Boss stage multiplier.** The boss pattern is paid the same multiplier as any other pattern, so clearing it completely gives ×5.
- **Dynamic boss hit scaling.** The first boss (wave 3 / ZONE 04) takes 20 hits to destroy. Later bosses (waves 7, 11, 15 / ZONES 08, 12, 16) take 25 hits. Cosmetic explosions continue during the last 5 hits for both variants.
- **Boss hit tracking.** Added `wBossHits` RAM variable and `SetBossHits` function that sets hit count based on current wave.

## Changes
- **Standard alien score.** The four standard alien types score 10 points each. The boss scores 80 points.
- **Spawned aliens count toward the wave.** Aliens created by splitting or spawning are included in the wave total, so a pattern with spawning aliens can reach 100%.
- **Cheat unlock sound.** The cheat unlock sound plays at full priority, so it cuts the music.
- **Enemy bomb speed.** Fast enemy bombs move 2 or 3 px per frame (was 3 or 4), so they are a little slower but still faster than the slow bombs.
- **Boss spawn logic updated.** `FillAlien` in `src/aliens.asm` now uses `wBossHits` for type‑5 boss aliens instead of the static `alien_hits` table value.
- **Build improvements.** `.gitignore` updated to ignore `*.sav` save files and `.DS_Store` metadata.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts on ZONE 04 (the first boss wave) for testing.

## Build
- `make` builds `galaforce-0.0.16-SNAPSHOT.gb` from `VERSION` in the Makefile.
- `make god` builds `galaforce_god.gb`, which cannot die (used for headless checks).

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16) is reduced but not fixed. Aliens can still overlap on some lines.
- Boss death: the grand explosion can replay after it finishes while the player is still moving. Not yet diagnosed.
- Garbage lines can appear under the score during some explosions. Not yet diagnosed.
- The GB crest is built into the title graphics but not shown on the title screen.
- Wave multipliers and the cheat unlock sound are checked by build and headless tests, not yet play-tested. Please report anything that looks wrong.
