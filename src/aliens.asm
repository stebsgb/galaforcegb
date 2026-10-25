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
    ld a, [hl]
    cp 6
    jr c, .next
    ld l, c
    xor a
    ld [hl], a
.next:
    ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .loop
    ret

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
    call SpawnChild
    ld a, 1
    ret

.die:
    ld h, HIGH(wAliens)
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
    call Rand
    and 3
    jp nz, .again
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
    ld e, a
    ld d, 0
    ld hl, alien_hits
    add hl, de
    ld a, [hl]
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
    jr nz, .d
    inc a
.d: ld [de], a                  ; count
    inc e
    ld [de], a                  ; delay
    inc e
    ld a, [hli]                 ; num
    ld [de], a
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
    ld [wTmp + 3], a
    inc e
    ld a, [de]
    ld b, a
    rlca
    and 1
    ld [wTmp + 2], a
    ld a, b
    and $7F
    call FillAlien

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
