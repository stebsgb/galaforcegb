# Galaforce for Game Boy v0.0.14

Build: `galaforce-0.0.14.gb` (MBC1 + RAM + battery, 32 KB ROM).

## New
- **Smart bomb.** Press SELECT, or A and B together, to use a smart bomb. It hits every alien on screen once, and the boss once. Spawning aliens, which take two hits, survive a bomb with one hit left.
- **Bomb supply.** Each new life starts with one smart bomb. You can hold up to two. Destroying a boss gives you another.
- **Bomb display.** The lower status shows the bomb icon, with `X2` when you hold two.
- **Bomb sound and flash.** A lower noise burst with a falling tone, and a short screen flash when the bomb goes off.
- **New enemy bomb sprites.** Enemy bombs are redrawn as glowing orbs.

## Changes
- **Boss zone formation.** Zones 04, 08, 12 and 16 have a reworked boss formation. The boss pattern runs last, the lower alien row mixes two alien types, and the solo boss takes 20 hits and moves faster sideways.
- **Black background by default.** A white background can still be chosen on the options screen, and a saved choice is kept.
- **Up to 7 lives.** The starting lives default to 5, and you can now choose up to 7.
- **Fairer default high scores.** Each continue setting has its own starting high score: 15,000 with no continues, 30,000 with one, 50,000 with two and 60,000 with three. These apply until a real score is saved for that setting.
- **Options screen.** The OPTIONS title has its own shade and is centred. The menu values sit further left, and the ship and alien preview are a little higher.

## Boss test build
- `make boss` builds `galaforce_boss.gb`, which starts on ZONE 04 (the first boss wave) for testing.

## Build
- `make` builds `galaforce-0.0.14-SNAPSHOT.gb` from `VERSION` in the Makefile.
- `make god` builds `galaforce_god.gb`, which cannot die (used for headless checks).
- The reference source is in `ref/`, a separate git repo that this repo does not track. `archive/ref-source.zip` is a snapshot of it, with a SHA-256 in `archive/ref-source.zip.sha256`.

## Known issues
- Boss wave flicker and overlap (ZONE 04, 08, 12, 16) is reduced but not fixed. Aliens can still overlap on some lines.
- The GB crest is built into the title graphics but not shown on the title screen.
- Checked by build and headless tests, not play-tested: the bomb sound and tone, the bomb's effect on spawning aliens, the options layout and title shade, and the default high scores. Please report anything that looks wrong.