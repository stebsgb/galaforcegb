# Galaforce for Game Boy v0.0.13

Build: `galaforce-0.0.13.gb` (MBC1 + RAM + battery, 32 KB ROM).

## Fixes
- Lost life music: the last-life sound is no longer cut by bullets or explosions while it plays. The Lost a Life tune cuts off the death explosion instead of being dropped while it plays.
- Music priority: a tune now takes the sound channels back and cuts any effect that is sounding. While a tune plays, sound effects are dropped, except FIRE and BOOM, which always start.
- Secret screen: on the options screen, DOWN DOWN UP UP SELECT opens a secret screen with a heart and sparkles, plus a sparkle sound.
- Fades: fades clear sprites at black, so game-over text and sparkles no longer carry onto the next screen.
- Lives option: the LIVES setting is the total number of ships, so setting 1 gives one ship.
- Last-life tune: no Lost a Life tune plays on a final game over; GAME OVER starts straight away.
- Right-edge alien artifact on Zone 1: a 4-step vertical leg on path 0 (added in 0.0.10) put a lone alien clipped at the right edge. Path 0 is back to 3 steps.

## Enhancements
- Hi-score per continue setting: each CONTINUES setting (0 to 3) keeps its own hi-score. Defaults: 0 continues 30000, 1 continue 60000, 2 continues 75000, 3 continues 100000. The score shown changes when the setting is changed on the options screen.
- No hi-score with continues: a hi-score is recorded only when no continue was used in that game.
- No hi-score after a cheat start: a hi-score is not recorded when the game starts past ZONE 01 (cheat level select).
- Continues default to off (0).
- Sprite flicker, partial: alien draw order uses a coprime stride (`ALSTEP` = 9). This changes which aliens are hidden when a line has more than 10 sprites. It does not fix the boss wave flicker.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts directly on ZONE 04 (the first boss wave) for testing.
- `tools/flicker.py` now selects the LEVEL row before choosing a level.

## Build
- `make` builds `galaforce-0.0.13.gb` (release copy of `galaforce.gb`).
- `make snapshot-build` builds the current development build from source.

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16): carried over from v0.0.10 to v0.0.12, not fixed. The aliens still overlap and flicker on the boss wave.
- Zone 1 wave 0 flicker: aliens still overlap on some rows and flicker. Not fixed.
- Changes checked by build and automated tests, not play-tested: the hi-score per continue, the default values on the title and HUD, and the right-edge fix. Please report anything that looks wrong.

## Tools and docs
- `tools/secrettest.py` and `tools/secretdiag.py` added for the secret screen.
- `tools/gen_art.py` and `tools/gen_music.py` updated for the secret screen art and sparkle sound.
- `tools/optionstest.py` expects the new default (0 continues).
