# Galaforce for Game Boy v0.0.11

Build: `galaforce-0.0.11.gb` (MBC1 + RAM + battery, 32 KB ROM).

## Sound
- Last life: the "last life" sound now plays as soon as the Lost a Life tune has finished, instead of after a fixed delay. The next wave waits until it has played.
- Last-life sound is not interrupted by bullets or explosions until it ends.
- Lost a Life tune: cuts off the death explosion rather than being dropped while the explosion plays.
- Music overrides other effects while a tune is still playing.

## Known issues
- Changes checked by build and code review, not play-tested: the last-life timing. Please report if it sounds early, late, or cut short.
- Boss wave flicker (ZONE 04, 08, 12, 16): carried over from v0.0.10, not fixed.

## Tools and docs
- `docs/FIXES.md` and `docs/PROGRESS.md`: last-life sound timing recorded.
