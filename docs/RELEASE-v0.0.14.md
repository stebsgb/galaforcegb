# Galaforce for Game Boy v0.0.14

Build: `galaforce-0.0.14.gb` (MBC1 + RAM + battery, 32 KB ROM).

## Enhancements
- Smart bomb: press SELECT, or A and B together, to use a smart bomb. Each new life starts with one bomb (two are kept if already held, up to a maximum of two). A boss kill adds one bomb, capped at two. The HUD shows the bomb icon in the lower status, with `X2` when two are held.
- Smart bomb damage: the bomb deals one hit to every alien, including the spawning aliens (which take two hits), and one hit to the boss. A 2-hit alien survives a bomb with one hit left. The original two-hit bomb is kept behind the `BOMB_HITS` switch in `src/main.asm` (set it to 2 to restore it).
- Smart bomb sound: a lower noise burst layered with a pulse whose frequency drops. The bomb cuts the music and holds the channel, so FIRE and explosions do not replace it while it sounds. A bomb can only be used once the music has finished.
- Smart bomb screen flash: the background flashes for 12 frames when a bomb is used.
- Alien bomb sprite: redrawn as a symmetric glowing orb.
- Lives option: the default is 5 starting lives, and the maximum is now 7.
- Black background is the default. A saved white background still overrides it.
- Hi-score defaults (used until a score is saved for that continue setting): 0 continues 15000, 1 continue 30000, 2 continues 50000, 3 continues 60000.
- Options screen: the OPTIONS title is drawn as sprites in a different shade. The title is centred and one row lower, the option values sit further left, and the ship and alien preview are 3 px higher.
- Boss waves (ZONE 04, 08, 12, 16): boss waves keep their original pattern list, so the boss pattern plays last, after the other formations.
- Boss formation: the loop row uses alien types 7 and 8 at random (one swap in four), at half sideways speed over the full distance. The solo boss has 20 hits and moves faster sideways.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts directly on ZONE 04 (the first boss wave) for testing.

## Build
- `make` builds `galaforce-0.0.14-SNAPSHOT.gb` from `VERSION` in the Makefile.
- `make god` builds `galaforce_god.gb` (cannot die; used for the headless checks).
- `make boss` builds `galaforce_boss.gb`.
- The reference source is in `ref/` (a separate git repo, not tracked here). `archive/ref-source.zip` holds a snapshot of it, with a SHA-256 in `archive/ref-source.zip.sha256`.

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16): carried over from earlier releases. The loop row is re-spaced and the aliens still overlap on some lines.
- Title screen: the GB crest art is in `tools/gen_art.py` and is built into the tile data, but it is not placed on the title. The title's scrolling star band hides the row it was placed in. Not fixed.
- Changes checked by build and headless tests, not play-tested: the smart bomb sound and its tone, the bomb's effect on the spawning aliens, the options screen layout and title shade, and the hi-score defaults. Please report anything that looks wrong.

## Tools and docs
- `tools/gen_art.py` has the new bomb icon, the symmetric alien bomb sprite and the GB crest art (not placed).
- `tools/gen_music.py` has the smart bomb sound.
- `tools/gen_data.py` has the boss path tuning (paths 27, 28 and the new reset path 30), the pattern 45 layout and the solo boss height, with comments explaining each value.
- `README.md` has a setup step for the `ref/` reference source.