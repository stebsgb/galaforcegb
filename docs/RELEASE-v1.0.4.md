# Galaforce for Game Boy v1.0.4

Build: `galaforce-1.0.4.gb` (MBC1 + RAM + battery, 32 KB ROM).

## Changes
- **Optimised alien formations:** Adjusted spawn timing and movement for patterns 23 and 24. The streams move faster while retaining their horizontal formation width and useful gaps between aliens.
- **More consistent wave spacing:** Patterns 15 and 16 now share the same wider spacing in every wave where they appear. The mirrored formations move at the same speed.
- **Wave 0 formation tuning:** Increased the separation in the opening mirrored streams and slightly reduced the alien count in pattern 2, making crowded groups easier to approach and shoot through.
- **Alien-kill sound variation:** Alien-kill explosions retain their immediate sound, with a subtle lower white-noise pitch on about one in eight kills. Other explosion sounds are unchanged.
- **Options return behavior:** Returning from Options now highlights Start Game by default.
- **Soft-reset protection:** Added a short input delay after a soft reset so the held reset buttons cannot immediately start another game.
- **HRAM initialization:** Clear the active HRAM variables during startup/reset before they are read.
- **Release build target:** `make` now creates the versioned release ROM by default; `make snapshot-build` remains available for development builds.

## Known issue
Dense formations can still flicker when more than 10 sprites share a scanline, due to the Game Boy's hardware limit. Alien draw-order and formation tuning reduce the effect but do not eliminate it.
