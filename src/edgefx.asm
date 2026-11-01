SECTION "edgefx", ROMX, BANK[1]

; Boss stage music. Called from StartPattern (src/aliens.asm) when pattern 45 starts. The music does not
; start yet: BossCheck only arms wBossWait, and BossWaitTick (called every frame from UpdateAliens) starts
; the boss tune once the boss is alive and at most two standard aliens are left on screen.
; The boss tune (MUS_BOSS) is the title tune's wave stream, one octave lower, on a pulse waveform. It plays on the wave channel only and repeats. Pulse 1 and pulse 2 are
; left to the explosions and player bullets (src/audio.asm: aMute, aLoop). Lives in bank 1 to save space in bank 0.
BossCheck:                      ; a = pattern id, preserved
    cp 45
    ret nz
    push af
    ld a, [wDemo]               ; the attract demo has no music
    or a
    jr nz, .out
    ld a, 1
    ld [wBossWait], a           ; wait for the boss to be the last big threat (see BossWaitTick)
.out:
    pop af
    ret

; BossWaitTick: called at the end of UpdateAliens. While wBossWait is set, count the live aliens:
; the boss (type 5, state $80) must be alive, all of the pattern's spawn records must have finished
; (the loop row spawns after the boss), and the other live aliens (state $80, not the boss) must be 2 or fewer.
; Then the boss tune starts and the wait ends. Dying aliens ($81) are not counted.
BossWaitTick:
    ld a, [wBossWait]
    or a
    ret z
    ld h, HIGH(wAliens)
    ld l, 0
    ld b, MAXAL
    ld c, 0                     ; c = live standard aliens
    ld d, 0                     ; d = 1 when the boss is alive
.slot:
    ld e, l                     ; e = slot base
    ld a, [hl]
    cp $80
    jr nz, .next
    ld a, e
    or AL_TYPE
    ld l, a
    ld a, [hl]
    ld l, e
    cp 5
    jr z, .boss
    inc c
    jr .next
.boss:
    ld d, 1
.next:
    ld a, l
    add 16
    ld l, a
    dec b
    jr nz, .slot
    ld a, d
    or a
    ret z                       ; boss not alive (not spawned yet, or dying)
    ; the pattern must have finished spawning: a spawn record still pending means more standard aliens
    ; (the loop row) are still to come, so the count below would be too early
    ld hl, wInits
    ld b, MAXINIT
    ld de, 16
.init:
    ld a, [hl]
    or a
    ret nz                      ; a record is still spawning: keep waiting
    add hl, de
    dec b
    jr nz, .init
    ld a, c
    cp 3
    ret nc                      ; three or more standard aliens: keep waiting
    xor a
    ld [wBossWait], a
    jp BossMusic

BossMusic:
    ld a, [wDemo]               ; the attract demo has no music
    or a
    ret nz
    ld a, MUS_BOSS
    call MusicPlay
    ld hl, WaveTableBoss                ; the boss has its own pulse waveform (MusicPlay loaded the default triangle)
    call LoadWave
    ld a, 1
    ld [aMute], a
    ld [aLoop], a
    ret

; BossStop: the boss dies. Stop the boss tune and silence the wave channel. Called from the boss death
; explosion (src/aliens.asm .bossdie). Clears every tune flag so the next wave's tune starts normally.
BossStop:
    xor a
    ld [aPlay], a
    ld [aMute], a
    ld [aLoop], a
    ld [wBossWait], a           ; a boss death also cancels a boss tune that has not started yet
    ld [aGateCt], a
    ldh [rNR30], a
    ret

; RestartTune: reload all three stream pointers of the current tune and start again.
; Called from MusicTick (src/audio.asm) when the wave channel reaches the end of a looping tune.
RestartTune:
    push bc
    ld a, [aTune]
    swap a
    ld e, a
    ld d, 0
    ld hl, TuneTable
    add hl, de
    ld de, aPtr
    ld b, 6
.c: ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .c
    ld a, 1
    ld [aCnt], a
    ld [aCnt + 1], a
    ld [aCnt + 2], a
    ld a, [aRate]                   ; boss tune: each loop speeds up (+10 per loop, 50 -> 60 -> 70 -> 80 -> 90 -> 100)
    add 10
    cp 101
    jr c, .rate
    ld a, 100                       ; cap: 2x the starting tempo (rate 50 = 1x)
.rate:
    ld [aRate], a
    pop bc
    ret

; Edge (path-end) explosions. This code lives in ROM bank 1 to free space in bank 0.
; Bank 1 is selected at boot and the game never writes the MBC1 bank register ($2000-$3FFF),
; so a plain call from bank 0 reaches this code. Add bank switching only with a matching change here.
;
; EdgeExplode: c = alien slot offset that has just reached the end of its path (state $81 -> $83).
; Only one edge explosion is shown at a time: the previous one (wEdgeSlot) is removed first.
; Player-kill explosions ($81, set in game.asm) are not touched. Preserves c.
EdgeExplode:
    ld a, [wEdgeSlot]
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [hl]
    cp $83
    jr nz, .keep
    xor a
    ld [hl], a
.keep:
    ld a, c
    ld [wEdgeSlot], a
    ld l, c
    ld a, $83                   ; edge explosion: still dying (bit 0 set), so every dying check applies
    ld [hl], a
    ret

; KillCap: called from AlienHit just before slot c becomes a player-kill explosion ($81).
; At most KILL_CAP player-kill explosions are live. If the cap is already reached, the oldest
; one (largest AL_TMR, its age in frames) is removed now. The boss (type 5) is never capped or removed,
; and smart bomb kills (AL_BOMB set from wBombKill) are neither counted nor removed.
; Preserves c.
DEF KILL_CAP EQU 3

KillCap:                        ; wrapper: keeps bc, de and hl for the caller
    push bc
    push de
    push hl
    call KillCapBody
    pop hl
    pop de
    pop bc
    ret

; BombHit: c = alien slot. UseBomb calls this in place of AlienHit, so a kill made by the smart bomb is
; tagged as a bomb kill (wBombKill = 1) and is not counted or capped. Preserves bc (AlienHit does).
BombHit:
    ld a, 1
    ld [wBombKill], a
    call AlienHit
    xor a
    ld [wBombKill], a
    ret

; BombTagClear: c = slot of a player-death explosion ($81 set in PlayerDie). Tags it exempt (AL_BOMB = 1)
; so the death animation is not counted or capped, as before. Preserves c.
BombTagClear:
    ld a, c
    or AL_BOMB
    ld l, a
    ld h, HIGH(wAliens)
    ld a, 1
    ld [hl], a
    ret

KillCapBody:
    ld a, c
    or AL_BOMB
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [wBombKill]
    ld [hl], a                  ; tag this kill: 1 = smart bomb kill (set by UseBomb), 0 = player kill
    or a
    ret nz                      ; smart bomb kill: not capped and not counted
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    ret z                       ; the boss is not capped
    ld b, 0                     ; b = live non-boss kill explosions
    ld d, 0                     ; d = oldest age found
    ld e, 0
.c1:
    ld h, HIGH(wAliens)
    ld l, e
    ld a, [hl]
    cp $81
    jr nz, .c1n
    ld a, e
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr z, .c1n
    ld a, e
    or AL_BOMB
    ld l, a
    ld a, [hl]
    or a
    jr nz, .c1n                 ; smart bomb kill: not counted
    inc b
    ld a, e
    or AL_TMR
    ld l, a
    ld a, [hl]
    cp d
    jr c, .c1n
    ld d, a
.c1n:
    ld a, e
    add 16
    ld e, a
    cp MAXAL * 16
    jr c, .c1
    ld a, b
    cp KILL_CAP
    ret c                       ; below the cap: nothing to remove
    ld e, 0
.c2:
    ld h, HIGH(wAliens)
    ld l, e
    ld a, [hl]
    cp $81
    jr nz, .c2n
    ld a, e
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr z, .c2n
    ld a, e
    or AL_BOMB
    ld l, a
    ld a, [hl]
    or a
    jr nz, .c2n                 ; smart bomb kill: never removed by the cap
    ld a, e
    or AL_TMR
    ld l, a
    ld a, [hl]
    cp d
    jr nz, .c2n
    ld a, e
    or AL_ST
    ld l, a
    xor a
    ld [hl], a                  ; remove the oldest kill explosion
    ret
.c2n:
    ld a, e
    add 16
    ld e, a
    cp MAXAL * 16
    jr c, .c2
    ret
