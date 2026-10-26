# Galaforce for Game Boy v0.0.10

Build: `galaforce-0.0.10.gb` (MBC1 + RAM + battery, 32 KB ROM).

## Gameplay
- **Player bullets** move 4 px per frame (was 3).
- **Alien bombs:** slow bombs move a steady 1 px per frame; fast bombs alternate 3 and 4 px per frame.
- **Wave 0 and wave 8 formation:** the two vertical legs of the first formation's path are longer, so the aliens swing a little further up and down.

## Sound
- **Fire:** full-volume, short click (was a slow attack that the next shot cut off).
- **Explosions:** kill explosions always play, cutting any sound still playing. Previously many were silently dropped.
- **Hits:** the hit sound on armoured aliens starts at full volume.
- **Title:** plays the attract-mode tune.
- **Attract demo:** silent (no music, no sound effects).

## Title screen
- **Flags:** one flag per five levels, up to three, showing the highest wave reached since the console was switched on. Not saved between power-ons.

## Known issues
- **Boss wave flicker:** on the boss waves (ZONE 04, 08, 12, 16), aliens below the boss bunch together and overlap, and the sprites flicker. Several formation changes were tried and none reduced it. Not fixed in this release.
- **Changes checked by build and measurement, not play-tested:** the wave 0/8 swing, the bomb speeds, the fire and explosion sounds, and the title music. Please report anything that sounds or looks wrong.

## Tools and docs
- `README.md`: screenshots replaced by two demo GIFs, light and dark background.
- `tools/makegif.py`: `BG=0` records the dark-background GIF.
- Static screenshots in `docs/screenshots/` have been removed.
