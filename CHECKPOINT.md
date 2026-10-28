# CHECKPOINT: boss one-line test (approved by user)

- ROM: `galaforce_CHECKPOINT_boss_oneline_pattern45_path28.gb` (copy of `galaforce_boss_oneline_test.gb`)
- Boots directly into the boss stage (`make boss`, BOSSTEST build).
- Boss waves (3, 7, 11, 15) use only pattern 45.
- Pattern 45 has a single alien stream: the top X-alien row, with the path 28 wobble and drift. The striped lower row is removed.
- Generator state: `tools/gen_data.py` has no temporary edits. The only source change kept is `patts_out[45][16] = 28` (path 28 under the boss).
- Status: user confirmed this version looks good in testing.

## CHECKPOINT: boss one-line near-final curve tuning (28 -> 27 -> 28)

- Build target: `make boss` (`galaforce_boss.gb`, BOSSTEST).
- Boss waves (3, 7, 11, 15) are forced to pattern 45.
- Active boss pattern output (`build/data.inc`):
  - `patt45: db 2,0,40,1,1,0,0,22,29,0,80,8,13,0,0,26,28`
  - Top/single stream remains on path 29 (`patts_out[45][8] = 29`).
  - Non-solo row uses path 28 (`patts_out[45][16] = 28`).
- Path tuning in `ref/src/PATDAT.asm`:
  - `patdat28: db 164,9,136,10,164,11,2,27` (hands off to 27)
  - `patdat27: db 132,10,164,9,14,2,28` (half drop, horizontal sweep, reset, then handoff to 28)
- Loop behavior intent at this checkpoint:
  - Non-solo row alternates `28 -> 27 -> 28 ...`.
  - `14` in path 27 resets before re-entering 28 so 28 starts from its origin.
- Notes:
  - Current one-line checkpoint still slices pattern 45 to 2 parts (`patts_out[45] = patts_out[45][:17]`, `patts_out[45][0] = 2`).
  - `patts_out[45][12]` is currently set to `13` (visible stream count tuning).
