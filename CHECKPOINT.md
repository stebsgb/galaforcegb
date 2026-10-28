# CHECKPOINT: boss one-line test (approved by user)

- ROM: `galaforce_CHECKPOINT_boss_oneline_pattern45_path28.gb` (copy of `galaforce_boss_oneline_test.gb`)
- Boots directly into the boss stage (`make boss`, BOSSTEST build).
- Boss waves (3, 7, 11, 15) use only pattern 45.
- Pattern 45 has a single alien stream: the top X-alien row, with the path 28 wobble and drift. The striped lower row is removed.
- Generator state: `tools/gen_data.py` has no temporary edits. The only source change kept is `patts_out[45][16] = 28` (path 28 under the boss).
- Status: user confirmed this version looks good in testing.
