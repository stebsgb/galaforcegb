SECTION "player", ROM0

PlayerUpdate:
    ld a, [wFireCD]
    or a
    jr z, .cd
    dec a
    ld [wFireCD], a
.cd:
    ld a, [wPAlive]
    or a
    ret z
    ld a, [wKeys]
    ld b, a
    ld a, [wFrame]
    and 1
    inc a
    ld c, a                     ; 1 or 2 px per frame (1.5 average)
    bit 5, b
    jr z, .noleft
    ld a, [wPX]
    sub c
    jr nc, .l1
    xor a
.l1:
    ld [wPX], a
.noleft:
    bit 4, b
    jr z, .noright
    ld a, [wPX]
    add c
    cp PX_MAX + 1
    jr c, .r1
    ld a, PX_MAX
.r1:
    ld [wPX], a
.noright:
    bit 6, b
    jr z, .noup
    ld a, [wPY]
    dec a
    cp PY_MIN
    jr nc, .u1
    ld a, PY_MIN
.u1:
    ld [wPY], a
.noup:
    bit 7, b
    jr z, .nodown
    ld a, [wPY]
    inc a
    cp PY_MAX + 1
    jr c, .d1
    ld a, PY_MAX
.d1:
    ld [wPY], a
.nodown:
    ld a, b
    and PAD_A | PAD_B
    ret z
    ld a, [wFireCD]
    or a
    ret nz
    ; fall through

FireBullet:
    ld hl, wBul
    ld b, 3
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
    ld a, 1
    ld [hli], a
    ld a, [wPX]
    add 4
    ld [hli], a
    ld a, [wPY]
    sub 6
    ld [hl], a
    ld a, 9
    ld [wFireCD], a
    ld a, SFX_FIRE
    jp Sfx

UpdateBullets:
    ld hl, wBul
    ld b, 3
.l: ld a, [hl]
    or a
    jr z, .n
    inc hl
    inc hl
    ld a, [hl]
    sub 3
    jr c, .kill
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
