# Galaforce for Game Boy (DMG)

Personal-project port of Kevin Edwards' BBC Micro *Galaforce* (original source: https://github.com/KevEdwards/Galaforce1BBC, cloned to `ref/`). Not for distribution.

Build: `make` (needs RGBDS and a Python venv in `.venv` with pillow, numpy, pyboy) -> `galaforce.gb` (MBC1+RAM+battery, 32 KB ROM).
`make god` builds `galaforce_god.gb` (cannot die; used for soak tests).

Controls: D-pad move, A fire, Start pause, A+B+Select+Start reset.

Tools: `tools/bot.py`, `audit.py`, `savetest.py`, `sfxlevels.py`, `audiotest.py`, `snap.py`. See `docs/DECISIONS.md` and `docs/PROGRESS.md`.
