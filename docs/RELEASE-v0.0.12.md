# Galaforce for Game Boy v0.0.12

Build: `galaforce-0.0.12.gb` (MBC1 + RAM + battery, 32 KB ROM). Version number in the Makefile is still 0.0.11 for this release.

## Fixes
- Lost life music: the last-life sound is no longer cut by bullets or explosions while it plays. The Lost a Life tune cuts off the death explosion rather than being dropped while it plays.
- Music priority: a tune now takes the sound channels back and cuts any effect that is sounding. While a tune plays, sound effects are dropped, except the FIRE and BOOM effects, which always start.
- Secret screen: options screen DOWN DOWN UP UP SELECT opens a secret screen with a heart and sparkles, with a sparkle sound.
- Fades: fades clear sprites at black, so game-over text and sparkles no longer carry onto the next screen.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts directly on ZONE 04 (the first boss wave) for testing.
- `tools/flicker.py` now selects the LEVEL row before choosing a level.

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16): carried over from v0.0.10 and v0.0.11, not fixed. On the boss wave the aliens still overlap and flicker. Several path and row changes were tried, and none removed the overlap without breaking the across-screen sweep. Not fixed in this release.
- Changes checked by build and code review, not play-tested: the secret screen. Please report anything that looks wrong.

## Tools and docs
- `tools/secrettest.py` and `tools/secretdiag.py` added for the secret screen.
- `tools/gen_art.py` and `tools/gen_music.py` updated for the secret screen art and sparkle sound.
