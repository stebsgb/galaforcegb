SECTION "bombs", ROM0

; InitBomb: c = alien slot offset. Preserves c.
InitBomb:
    ld hl, wBomb
    ld b, 6
.f: ld a, [hl]
    or a
    jr z, .got
    inc hl
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .f
    ret
.got:
    push hl
    ld h, HIGH(wAliens)
    ld a, c
    or AL_X
    ld l, a
    ld a, [hl]
    add 4
    cp 156
    jr nc, .abort
    ld d, a
    ld a, c
    or AL_Y
    ld l, a
    ld a, [hl]
    call FieldY
    cp 70
    jr nc, .abort
    add 8
    ld e, a
    cp 40
    ld a, 1                     ; slow
    jr nc, .kind
    push de
    call Rand
    pop de
    and 1
    inc a                       ; 1 slow / 2 fast
.kind:
    pop hl
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, e
    ld [hl], a
    ret
.abort:
    pop hl
    ret

UpdateBombs:
    ld hl, wBomb
    ld b, 6
.l: ld a, [hl]
    or a
    jr z, .n
    cp 2
    ld d, 3
    jr z, .go
    ld a, [wFrame]
    and 1
    inc a
    ld d, a
.go:
    inc hl
    inc hl
    ld a, [hl]
    add d
    cp 128
    jr nc, .kill
    ld [hl], a
    dec hl
    dec hl
    jr .n
.kill:
    dec hl
    dec hl
    xor a
    ld [hl], a
.n: inc hl
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .l
    ret

RandomBombs:
    ld a, [wWave]
    cp 3
    ret c
    ld a, [wFrame]
    and 1
    ret z
    call Rand
    and 15
    ret nz
    call Rand
    and 15
    cp MAXAL
    ret nc
    swap a
    ld c, a
    ld h, HIGH(wAliens)
    ld l, a
    ld a, [hl]
    cp $80
    ret nz
    jp InitBomb
