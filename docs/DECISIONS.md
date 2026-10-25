# Design decisions (as built)

These supersede the original stage plans where they differ.

| Topic | Plan | As built | Why |
|---|---|---|---|
| Aliens | BG-tile formation + sprite attackers | **All sprites**, 16x16 (two 8x16 objects) | The original has no persistent grid; aliens fly in scripted streams (path bytecode in PATT/PATDAT). The path interpreter is ported 1:1. |
| Playfield | 120 + 16 px | 128 px playfield (lines 8-135) between an 8 px HUD strip (score/hi-score, top) and an 8 px window strip (wave flag, lives, bottom) | Matches original HUD placement. |
| Time base | - | 1 frame = half an original "sweep"; step/spawn counters tick on odd frames | Keeps original speeds on a 59.7 Hz display. |
| Music | hUGEDriver | **Custom 3-channel driver** (pulse1, pulse2, wave) reading the original note streams, 50 Hz tick on 59.7 Hz frames | Original tunes are simple 3-voice streams; conversion is exact and tiny (674 bytes). |
| SFX | - | Event lists on pulse1/pulse2/noise; they steal music channels like the original SFX did | Approximations of the BBC `SOUND`/envelope blocks. Music is mixed lower than effects. |
| Mapper | none | **MBC1 + RAM + battery, 8 KB SRAM**, ROM still 32 KB | Hi-score persistence (`$A000`: "GF", 7 digits, checksum). |
| Sprite art | - | Original 12x16 art redrawn at 16x16; symmetric originals are mirrored exactly. Source art is stored upside down, so all sprites are flipped vertically. | User requirement. |
| Sprites/line | - | Hardware limit 10 objects per line = 5 aliens abreast. OAM start slot rotates each frame so overflow flickers fairly. | Measured: dense waves exceed it for ~30% of frames (see QA). |

## Controls
D-pad move, A fire, Start pause (screen dims), A+B+Select+Start soft reset.
