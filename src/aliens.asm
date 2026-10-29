SECTION "aliencode", ROM0

; FieldY: a = original alien y -> playfield y (h = y>>1; values >= 120 are above the top).
; h <= 80: 5/8 h, so formations and sweeps sit high in the playfield and are easy to hit.
; h > 80: 50 + 15/8 (h - 80), so a dive still reaches the player's row (h 113 -> 112).
FieldY:
    srl a
    cp 120
    jr c, .pos
    sub 128
    ret
.pos:
    cp 81
    jr nc, .low
    push bc
    ld b, a
    srl a
    srl a
    ld c, a
    srl a
    add c
    sub b
    cpl
    inc a                       ; b - 3/8 b = 5/8 b
    pop bc
    ret
.low:
    push bc
    sub 80
    ld b, a
    add a
    ld c, a
    ld a, b
    srl a
    srl a
    srl a
    ld b, a
    ld a, c
    sub b                       ; 2d - d/8
    add 50
    pop bc
    ret

; ---------------------------------------------------------------- per-frame alien update
UpdateAliens:
    ld a, [wSpawnCD]
    or a
    jr z, .cd
    dec a
    ld [wSpawnCD], a
.cd:
    ld c, 0
.loop:
    ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    or a
    jr z, .next
    bit 0, a
    jr nz, .dying
    call AlienStep
    call BossFire
    jr .next
.dying:
    ld a, c
    or AL_TMR
    ld l, a
    inc [hl]
    ld a, [hl]
    and 3
    jr nz, .next
    ld a, c
    or AL_FRAME
    ld l, a
    inc [hl]
    ld b, [hl]
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    ld a, b
    jr nz, .small
    ld a, [wState]
    cp ST_PDEAD                 ; the boss only blows up grandly when shot
    ld a, b
    jr nz, .bossdie
.small:
    cp 6
    jr c, .next
.free:
    ld l, c
    xor a
    ld [hl], a
    jr .next
.bossfree:                      ; boss death finished: 2000-point bonus + heart sound, one smart bomb (max 2), free the slot
    push bc
    ld hl, 200                      ; 2000 points bonus (x10 units)
    call AddScoreHL
    ld a, SFX_SPARKLE               ; heart sound
    call Sfx
    pop bc
    ld a, [wBombs]
    cp 2
    jr nc, .bombcap
    inc a
    ld [wBombs], a
.bombcap:
    ld l, c
    xor a
    ld [hl], a
    jr .next
.bossdie:                       ; boss: 36 frame steps (~2.4 s) of chained explosions, a boom every 4th step
    cp 36
    jr nc, .bossfree
    and 3
    jr nz, .next
    push bc
    ld a, SFX_BOOM
    call Sfx
    pop bc
.next:
    ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .loop
    ret

; BossFire: c = slot. A boss (type 5) with no other live alien drops a bomb about every 32 frames;
; the boss path has no bomb opcodes, so this is its only fire.
BossFire:
    ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80
    ret nz
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    ret nz
    ld d, MAXAL
    ld e, 0
    ld hl, wAliens
.c: ld a, [hl]
    cp $80
    jr nz, .n
    inc e
.n: ld a, l
    add 16
    ld l, a
    dec d
    jr nz, .c
    ld a, e
    cp 2
    ret nc
    call Rand
    and 31
    ret nz
    jp InitBomb

; c = slot offset. Interprets path script when the current move is finished, then moves.
AlienStep:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_STEPS
    ld l, a
    ld a, [hl]
    or a
    jr nz, .move
    call AlienFetch
    or a
    ret nz
.move:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_DIR
    ld l, a
    ld a, [hl]
    cp $40
    jr nc, .dec                 ; pause
    ld e, a
    ld d, 0
    ld hl, dir_dx
    add hl, de
    ld a, [hl]
    ld b, a
    ; boss loop row (types 7 and 8, pattern 45 only): halve the sideways step so it moves slower in X
    ld h, HIGH(wAliens)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 7
    jr z, .halfx
    cp 8
    jr nz, .fullx
.halfx:
    sra b
.fullx:
    ; solo boss (type 5, pattern 45): double the sideways step (its legs are halved in .store)
    ld h, HIGH(wAliens)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr nz, .notsolox
    ld a, e
    cp 1
    jr z, .solox
    cp 3
    jr nz, .notsolox
.solox:
    sla b
.notsolox:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_X
    ld l, a
    ld a, [hl]
    add b
    cp 160
    jr c, .xo
    cp 200
    jr nc, .xneg
    sub 160
    jr .xo
.xneg:
    add 160
.xo:
    ld [hl], a
    ld hl, dir_dy
    add hl, de
    ld a, [hl]                  ; table dy is half the original; applied on both frames of a step
    ld b, a
    ld a, c
    or AL_PATH
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [hl-]
    cp HIGH(patdat22)
    jr nz, .fulldy
    ld a, [hl]
    cp LOW(patdat22)
    jr nz, .fulldy
    ld a, [wFrame]              ; wave 12 deep U (patdat22, only user) dives 3/4 as deep so it stays above the ship line
    and 3
    jr nz, .fulldy
    ld b, 0
.fulldy:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_Y
    ld l, a
    ld a, [hl]
    add b
    ld [hl], a
.dec:
    ld a, [wFrame]
    and 1
    ret z
    ld h, HIGH(wAliens)
    ld a, c
    or AL_STEPS
    ld l, a
    dec [hl]
    ret

; ReadPat: reads next byte of slot c's path script into A.
ReadPat:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_PATL
    ld l, a
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld a, c
    or AL_OFF
    ld l, a
    ld a, [hl]
    inc [hl]
    add e
    ld e, a
    jr nc, .nc
    inc d
.nc:
    ld a, [de]
    ret

; AlienFetch: returns A=0 to continue with a movement this frame, A=1 if the turn ended.
AlienFetch:
.again:
    call ReadPat
    bit 7, a
    jr nz, .move
    or a
    jp z, .loop
    cp 2
    jp z, .newpat
    cp 4
    jp z, .newalien
    cp 6
    jp z, .die
    cp 8
    jp z, .drop
    cp 10
    jp z, .for
    cp 12
    jp z, .next
    jp .mve

.move:
    and $7F
    ld b, a
    call ReadPat
    ld e, a
    cp $40
    jr nc, .store
    ld h, HIGH(wAliens)
    ld a, c
    or AL_REFL
    ld l, a
    ld a, [hl]
    or a
    jr z, .store
    ld a, e
    cp 48
    jr nc, .hi
    and 7
    cp 4
    jr nc, .h4
    ld d, a
    ld a, 4
    sub d
    and 3
    jr .comb
.h4:
    ld d, a
    ld a, 11
    sub d
.comb:
    ld d, a
    ld a, e
    and $F8
    or d
    ld e, a
    jr .store
.hi:
    ld a, e
    xor 7
    ld e, a
.store:
    ; solo boss (type 5, pattern 45): horizontal legs (dir 1 right, 3 left) take half the steps.
    ; AlienStep doubles their X step, so the sweep is twice as fast over half the distance.
    ld h, HIGH(wAliens)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr nz, .soloskip
    ld a, e
    cp 1
    jr z, .soloh
    cp 3
    jr nz, .soloskip
.soloh:
    srl b
.soloskip:
    ; boss loop row (types 7 and 8): horizontal legs (dir 9 right, 11 left) take twice the steps.
    ; AlienStep halves their X step, so this restores the full sideways distance at half speed.
    ld h, HIGH(wAliens)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 7
    jr z, .dbl
    cp 8
    jr nz, .nodbl
.dbl:
    ld a, e
    cp 9
    jr z, .hz
    cp 11
    jr nz, .nodbl
.hz:
    sla b
.nodbl:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_STEPS
    ld l, a
    ld [hl], b
    inc l
    ld [hl], e
    xor a
    ret

.loop:
    call ReadPat
    ld b, a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_OFF
    ld l, a
    ld [hl], b
    jp .again

.newpat:
    call ReadPat
    add a
    ld e, a
    ld d, 0
    ld hl, patdat_ptrs
    add hl, de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_PATL
    ld l, a
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    xor a
    ld [hl], a
    jp .again
.newalien:
    call ReadPat
    ld b, a
    ld a, [wWave]
    and 15
    cp 2
    jr nz, .spawn
    ld a, [wSpawnCD]            ; wave 3: pause between spawns so children don't form a wall
    or a
    jr z, .go
    ld h, HIGH(wAliens)
    ld a, c
    or AL_OFF
    ld l, a
    dec [hl]
    dec [hl]                    ; retry this spawn next frame
    ld a, 1
    ret
.go:
    ld a, 8
    ld [wSpawnCD], a
.spawn:
    call SpawnChild
    ld a, 1
    ret

.die:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_Y
    ld l, a
    ld a, [hl]
    add 32                      ; y < 40 or >= 224: path ended in the top row / above it, vanish quietly
    cp 72
    jr nc, .vis
    ld l, c
    xor a
    ld [hl], a
    inc a
    ret
.vis:
    ld l, c
    ld a, $81
    ld [hl], a
    ld a, c
    or AL_FRAME
    ld l, a
    xor a
    ld [hl], a
    ld a, c
    or AL_TMR
    ld l, a
    xor a
    ld [hl], a
    ld a, 1
    ret

.drop:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr nz, .dnorm
    ld d, MAXAL                 ; boss: count the other live aliens
    ld e, 0
    ld hl, wAliens
.dc:
    ld a, [hl]
    cp $80
    jr nz, .dn
    inc e
.dn:
    ld a, l
    add 16
    ld l, a
    dec d
    jr nz, .dc
    ld a, e
    cp 2
    jr c, .dgo                  ; boss alone: drops on every bomb opcode
    call Rand
    and 1                       ; boss with company: twice the normal rate
    jp nz, .again
    jr .dgo
.dnorm:
    call Rand
    and 3
    jp nz, .again
.dgo:
    call InitBomb
    jp .again

.for:
    call ReadPat
    ld b, a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_LCNT
    ld l, a
    ld [hl], b
    ld a, c
    or AL_OFF
    ld l, a
    ld d, [hl]
    ld a, c
    or AL_LSTART
    ld l, a
    ld [hl], d
    jp .again

.next:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_LCNT
    ld l, a
    dec [hl]
    bit 7, [hl]
    jp nz, .again
    ld a, c
    or AL_LSTART
    ld l, a
    ld d, [hl]
    ld a, c
    or AL_OFF
    ld l, a
    ld [hl], d
    jp .again

.mve:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_X
    ld l, a
    xor a
    ld [hl], a
    inc l
    ld a, 72
    ld [hl], a
    ld a, 1
    ret

; ---------------------------------------------------------------- spawning
; FillAlien: a = path id, wTmp0 = x, wTmp1 = y, wTmp2 = mirrored(0/1), wTmp3 = type, wTmp7 = slot offset
FillAlien:
    ld [wTmp + 6], a
    ld a, [wTmp + 3]
    cp 5
    jr nz, .notBoss
    ld a, [wBossHits]
    jr .storeHits
.notBoss:
    ld e, a
    ld d, 0
    ld hl, alien_hits
    add hl, de
    ld a, [hl]
.storeHits:
    ld [wTmp + 4], a
    ld a, [wTmp + 6]
    add a
    ld e, a
    ld d, 0
    ld hl, patdat_ptrs
    add hl, de
    ld a, [hli]
    ld [wTmp + 5], a
    ld a, [hl]
    ld [wTmp + 6], a
    ld a, [wTmp + 7]
    ld l, a
    ld h, HIGH(wAliens)
    ld a, $80
    ld [hli], a
    ld a, [wTmp]
    ld [hli], a
    ld a, [wTmp + 1]
    ld [hli], a
    ld a, [wTmp + 3]
    ld [hli], a
    xor a
    ld [hli], a                 ; frame
    ld a, [wTmp + 4]
    ld [hli], a                 ; hits
    ld a, [wTmp + 5]
    ld [hli], a
    ld a, [wTmp + 6]
    ld [hli], a
    xor a
    ld [hli], a                 ; off
    ld [hli], a                 ; steps
    ld [hli], a                 ; dir
    ld [hli], a                 ; loop count
    ld [hli], a                 ; loop start
    ld a, [wTmp + 2]
    ld [hli], a                 ; reflect
    xor a
    ld [hl], a                  ; timer
    ; a boss in this pattern marks the pattern as a boss pattern (no wave multiplier on it)
    ld a, [wTmp + 3]
    cp 5
    jr nz, .notboss
    ld a, 1
    ld [wIsBossWave], a
.notboss:
    ; every alien created (spawned or split child) counts toward the wave total
    push hl
    push de
    ld hl, wWaveTotalAliens
    inc [hl]
    jr nz, .incdone
    inc hl
    inc [hl]
.incdone:
    pop de
    pop hl
    ret

; FindFreeAlien: returns e = offset, carry set if none
FindFreeAlien:
    ld h, HIGH(wAliens)
    ld e, 0
.f: ld l, e
    ld a, [hl]
    or a
    ret z                       ; carry clear
    ld a, e
    add 16
    ld e, a
    cp MAXAL * 16
    jr c, .f
    scf
    ret

; SpawnChild: c = parent slot, b = child path id (type 0/1 random, one row below parent)
SpawnChild:
    call FindFreeAlien
    ret c
    ld a, e
    ld [wTmp + 7], a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_X
    ld l, a
    ld a, [hl]
    ld [wTmp], a
    ld a, c
    or AL_Y
    ld l, a
    ld a, [hl]
    add 8
    ld [wTmp + 1], a
    ld a, c
    or AL_REFL
    ld l, a
    ld a, [hl]
    ld [wTmp + 2], a
    call Rand
    and 2
    srl a
    ld [wTmp + 3], a
    ld a, b
    jp FillAlien

; StartPattern: a = pattern id -> creates spawn records
StartPattern:
    add a
    ld e, a
    ld d, 0
    ld hl, patt_ptrs
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]
    ld b, a
    ld a, [wWave]               ; wave 3 is eased: see .d / num below
    and 15
    sub 2
    ld [wTmp + 6], a
    ld de, wInits
.part:
    ld a, 1
    ld [de], a
    inc e
    ld a, [hli]                 ; x (units) or 78/79 random
    cp 78
    jr c, .xok
    ld c, a
    call Rand
    and 31
    ld [wTmp], a
    ld a, c
    cp 79
    ld a, [wTmp]
    jr nz, .xok
    add 40
.xok:
    ld [de], a
    inc e
    ld a, [hli]                 ; y
    ld [de], a
    inc e
    ld a, [hli]                 ; delay
    or a
    jr nz, .d0
    inc a
.d0:
    ld c, a
    ld a, [wTmp + 6]
    or a
    ld a, c
    jr nz, .d
    cp 17
    jr nc, .d
    srl c
    add c                       ; wave 3: spacing x1.5 so there are gaps to shoot through
.d: ld [de], a                  ; count
    inc e
    ld [de], a                  ; delay
    inc e
    ld a, [wTmp + 6]
    or a
    ld a, [hli]                 ; num
    jr nz, .n
    ld c, a
    srl c
    srl c
    sub c                       ; wave 3: 3/4 as many aliens per stream
    jr nz, .n
    inc a
.n: ld [de], a
    inc e
    ld a, [hli]                 ; relx
    ld [de], a
    inc e
    ld a, [hli]                 ; rely
    ld [de], a
    inc e
    ld a, [hli]                 ; gra -> type
    sub 12
    srl a
    ld [de], a
    inc e
    ld a, [hli]                 ; path id | mirror
    ld [de], a
    ld a, e
    and $F0
    add 16
    ld e, a
    dec b
    jr nz, .part
    ret

; Spawn records tick once per original "sweep" (every 2nd frame)
UpdateInits:
    ld a, [wFrame]
    and 1
    ret z
    ld c, 0
.l: ld h, HIGH(wInits)
    ld l, c
    ld a, [hl]
    or a
    jr z, .n
    ld a, c
    or IN_CNT
    ld l, a
    dec [hl]
    call z, SpawnAlien
.n: ld a, c
    add 16
    ld c, a
    cp MAXINIT * 16
    jr c, .l
    ret

SpawnAlien:
    call FindFreeAlien
    jr nc, .got
    ld h, HIGH(wInits)
    ld a, c
    or IN_CNT
    ld l, a
    ld [hl], 1
    ret
.got:
    ld a, e
    ld [wTmp + 7], a
    ld d, HIGH(wInits)
    ld a, c
    or IN_XU
    ld e, a
    ld a, [de]
    add a
    ld [wTmp], a
    inc e
    ld a, [de]
    ld [wTmp + 1], a
    ld a, c
    or IN_TYPE
    ld e, a
    ld a, [de]
    ; boss wave loop row: type 7 or 8 chosen at random per alien (both come only from pattern 45)
    cp 7
    jr z, .mix
    cp 8
    jr nz, .typeok
.mix:
    ld b, a
    push bc
    call Rand
    pop bc
    and 3                           ; 1 in 4 swaps, so runs of the same type are longer
    jr nz, .keep
    ld a, b
    xor 15                          ; 7 <-> 8 (0111 <-> 1000)
    jr .typeok
.keep:
    ld a, b                         ; keep the original type (7 stays 7)
.typeok:
    ld [wTmp + 3], a
    inc e
    ld a, [de]
    ld b, a
    rlca
    and 1
    ld [wTmp + 2], a
    ld a, b
    and $7F
    call FillAlien                  ; counts toward wWaveTotalAliens itself

    ; advance the spawn record
    ld d, HIGH(wInits)
    ld a, c
    or IN_NUM
    ld e, a
    ld a, [de]
    dec a
    ld [de], a
    jr nz, .more
    ld e, c
    xor a
    ld [de], a
    ret
.more:
    ld a, c
    or IN_DELAY
    ld e, a
    ld a, [de]
    ld b, a
    ld a, c
    or IN_CNT
    ld e, a
    ld a, b
    ld [de], a
    ld a, c
    or IN_RELX
    ld e, a
    ld a, [de]
    ld b, a
    ld a, c
    or IN_XU
    ld e, a
    ld a, [de]
    add b
    cp 80
    jr c, .xo
    cp 200
    jr nc, .xn
    sub 80
    jr .xo
.xn:
    add 80
.xo:
    ld [de], a
    ld a, c
    or IN_RELY
    ld e, a
    ld a, [de]
    ld b, a
    ld a, c
    or IN_Y
    ld e, a
    ld a, [de]
    add b
    ld [de], a
    ret
