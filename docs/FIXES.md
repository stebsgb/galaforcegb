# Playtest fixes and tweaks

Changes made after the 12 build stages, driven by playtest reports. Each entry gives the symptom, the cause and the fix.
Wave numbers are 1-based as the player sees them; "wave index" is 0-based as in the code.

## Alien glitches

| # | Symptom | Cause | Fix | Where |
|---|---------|-------|-----|-------|
| 1 | Odd explosions in the top corners (waves 5, 6, 11) | The path "die" opcode made an alien explode even when its path ended off the top edge | Aliens ending at original y < 24 or >= 224 are freed silently | `AlienFetch .die` in `src/aliens.asm` |
| 2 | Wave 4 (hoop and second pattern) explosions at the top | Paths ended around y 34 and exploded visibly | The quiet vanish now covers the whole top row (y < 40) | `.die` |
| 3 | Phantom hits in the corners | Bullets could hit aliens still above the top edge or in the entry/exit band | Those aliens are not hittable | `CollideBullets` in `src/game.asm` |
| 4 | Aliens popping in at the top corners on wave 4 | Hoop aliens wait at original y=255 (above the top) and wrap to y 5..17 before vanishing; both were drawn | `BuildOAM` skips aliens whose field y is above the top or < 8 | `src/render.asm` |
| 5 | Alien appears fully formed at the left corner | Wave 4 patterns 10 and 11 spawn at x=0 | Aliens at x < 8 slide in from behind the left edge | `src/render.asm` |
| 6 | Wave 12 U-shaped alien path goes under the ship and cannot be shot | The path (patdat22, used only on wave 12) bottoms out at original y=240, below the ship, and the top/bottom hiding rules then removed it | Its vertical movement is scaled to 3/4 (bottom y=188). Other paths are untouched | `AlienStep` in `src/aliens.asm` |

## Difficulty and behaviour

| Change | Detail | Where |
|--------|--------|-------|
| Wave 3 easier | Fast streams get 1.5x spacing and 3/4 as many aliens, so there are gaps to shoot through | `StartPattern` |
| Anti-camping | After 240 still frames (4 s) on a level with bombs, a live alien within 4 px of the ship's x drops a bomb about every 16 frames. The bomb always comes from a real alien | `AimedBomb` in `src/bombs.asm`, `wStill` in `StatePlay` |
| Boss alone | The boss path has no bomb opcode, so it never fired. When it is the only alien left it now fires with a 1 in 32 chance per frame. With company, its bomb opcode gate is looser | `BossFire` in `src/aliens.asm` |

## Boss stage (waves 4, 8, 12, 16; pattern 45)

- The original rows are 24 y-units apart, which `FieldY` squeezes to about 8 px, so the two rows of 16 and 15 aliens overlap and put about 20 objects on one scanline. The hardware limit is 10, which caused heavy flicker.
- Each row is thinned to 8 aliens at double spacing, and the rows sit at y 80 and 128 (the original second row is at 96, but that flickers badly).
- The alien OAM draw order alternates halves every frame (`ROTSTEP=7`, `ALSTEP=1`), so an overflowing alien is hidden for 1 frame at a time, not many. This removes the slow shimmer.
- `tools/flicker.py` measures this: about 33 % of alien-frames are partly hidden on the boss wave, against 61 % at first.
- Data lives in `tools/gen_data.py` (`BOSS_A`, `BOSS_B`, `patts_out`).

## Screens

- **Title:** the "GAME BOY EDITION" line is removed. The logo sits one row lower than the original. The scrolling-star text bands (`titleSegs` in `src/screens.asm`) were moved to match, since the first attempt cut the logo in half.
- **Options:** the ship and alien preview moved down 16 px and the hints down a row, so BACK is no longer cramped.

## Tools and checks

- `tools/flicker.py ROM [level]`: hidden-alien-frame metric for the boss stage.
- Regression set run after each change: `tools/optionstest.py`, `cheattest.py`, `savetest.py`, `demotest.py`, and `tools/audit.py galaforce_god.gb 20000` (0 dropped frames).
- `make god` builds `galaforce_god.gb`, which cannot die and is used for the headless checks.

## Open points

- Corner pop-ins on wave 4 were reduced in several steps; the last two were checked only by reading sprite positions, not by watching play.
- The boss rows are a compromise between the original layout and flicker. Raise `BOSS_B` in `tools/gen_data.py` towards 96 for a more faithful layout at the cost of flicker.
- The wave 12 U depth (3/4) is a judgement call and easy to change in `AlienStep`.

## Boss death

When the boss is destroyed it stays for about 1.6 s with six staggered explosions bursting over and around it, a boom every 4th step, and a final blast (`BossBoom` in `src/render.asm`, `UpdateAliens` in `src/aliens.asm`). The next wave waits until it has finished.

## Wave 2 spawner could not be killed

The alien that spawns children in wave 2's last formation hovers at original y=39. My earlier "entry/exit band" rule made everything above y=40 unhittable, so shots passed through it. The band is now y < 32 (and above the top edge), which still covers the corner pop-in cases (`CollideBullets` in `src/game.asm`).

## Wave 3 spawner

The wave 3 spawner released children in a tight wall. Skipping spawns made it too easy, so every spawn is kept but a 8-frame pause (22 was too easy) (`wSpawnCD`) is enforced between them on that wave only; a blocked spawn retries next frame (`.newalien` in `src/aliens.asm`).
