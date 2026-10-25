# Galaforce for Game Boy (DMG)

Personal-project port of Kevin Edwards' BBC Micro *Galaforce* (original source: https://github.com/KevEdwards/Galaforce1BBC, cloned to `ref/`). Not for distribution.

Pure SM83 assembly (RGBDS) with Python tooling. Targets the original monochrome Game Boy: 160x144, 16x16 sprites, the original formations, paths and wave data, a custom 4-channel audio driver with the original tunes and effects, and battery-backed hi-score and settings (MBC1 + RAM).

| White background (default) | Black background |
|---|---|
| ![Title](docs/screenshots/title_white.png) | ![Title](docs/screenshots/title_black.png) |
| ![Wave 1](docs/screenshots/wave1_white.png) | ![Wave 1](docs/screenshots/wave1_black.png) |
| ![Wave 5](docs/screenshots/wave5_white.png) | ![Wave 5](docs/screenshots/wave5_black.png) |
| ![Options](docs/screenshots/options_white.png) | ![Options](docs/screenshots/options_black.png) |

## Build
`make` (needs RGBDS and a Python venv in `.venv` with pillow, numpy, pyboy) -> `galaforce.gb` (MBC1+RAM+battery, 32 KB ROM).
`make god` builds `galaforce_god.gb` (cannot die; used for soak tests and gameplay screenshots).

## Controls
D-pad move, A fire, Start pause, A+B+Select+Start soft reset. Title and options: Up/Down select, A or Start choose, Left/Right change a value, B go back.

## Features
- Title styled after the BBC original (SC/HI line, wide logo, credits, flags, occasional shine sweep). Idles into a self-playing demo after about 13 s; any Start returns.
- Options: starting lives 1-5 and a black or white background (white is the default); both are saved in battery RAM.
- Cheat: on the options screen press Up, Up, Down, Down, Select to unlock a LEVEL row (1-16, not saved).
- Screen fades, pause dimming, hi-score saved to SRAM.

## Tools and docs
`tools/`: `bot.py`, `audit.py`, `savetest.py`, `demotest.py`, `optionstest.py`, `cheattest.py`, `sfxlevels.py`, `audiotest.py`, `snap.py`, `screenshots.py` (regenerates `docs/screenshots/`; run `make` and `make god` first).
See `00-OVERVIEW.md`, `docs/DECISIONS.md` and `docs/PROGRESS.md`. Stage plans `STAGE-01` to `STAGE-12` are all done.
