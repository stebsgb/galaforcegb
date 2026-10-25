SECTION "render", ROM0

; Builds the shadow OAM for this frame.
; Order: messages, player, bullets, bombs, aliens (rotated start slot for fair flicker).
BuildOAM:
    ld hl, wOAM
    ld b, 40
    ld de, 4
    xor a
.clr:
    ld [hl], a
    add hl, de
    dec b
    jr nz, .clr
    ld [wOamLo], a

    ld a, [wState]
    or a
    jp z, TitleStars
    cp ST_OPTIONS
    jp z, BuildOptionsOAM
    call DrawMessages

    ; --- player / player explosion
    ld a, [wPY]
    add 24
    ld b, a
    ld a, [wPX]
    add 8
    ld c, a
    ld a, [wPAlive]
    or a
    jr z, .pdead
    ld d, SPR_PLAYER
    ld e, 0
    call Put16
    jr .bullets
.pdead:
    ld a, [wState]
    cp ST_PDEAD
    jr nz, .bullets
    ld a, [wPExp]
    cp 6
    jr nc, .bullets
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld e, 0
    call Put16

.bullets:
    ld hl, wBul
    ld a, 3
    ld [wTmp + 6], a
.bl:
    ld a, [hli]
    or a
    jr z, .bskip
    ld a, [hli]
    add 8
    ld c, a
    ld a, [hli]
    add 24
    ld b, a
    inc hl
    push hl
    ld d, SPR_BULLET
    ld e, 0
    call PutObj
    pop hl
    jr .bnext
.bskip:
    inc hl
    inc hl
    inc hl
.bnext:
    ld a, [wTmp + 6]
    dec a
    ld [wTmp + 6], a
    jr nz, .bl

    ld hl, wBomb
    ld a, 6
    ld [wTmp + 6], a
.ml:
    ld a, [hli]
    or a
    jr z, .mskip
    ld a, [hli]
    add 8
    ld c, a
    ld a, [hli]
    add 24
    ld b, a
    inc hl
    push hl
    ld d, SPR_BOMB
    ld e, 0
    call PutObj
    pop hl
    jr .mnext
.mskip:
    inc hl
    inc hl
    inc hl
.mnext:
    ld a, [wTmp + 6]
    dec a
    ld [wTmp + 6], a
    jr nz, .ml

    ; --- aliens
    ld a, [wRot]
    add 16
    cp MAXAL * 16
    jr c, .rot
    xor a
.rot:
    ld [wRot], a
    ld [wTmp + 1], a
    ld a, MAXAL
    ld [wTmp + 2], a
.al:
    ld a, [wTmp + 1]
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [hli]
    or a
    jr z, .alnext
    ld [wTmp + 3], a            ; state
    ld a, [hli]
    add 8
    ld c, a
    ld a, [hli]
    call FieldY
.yok:
    add 24
    ld b, a
    ld a, [hli]                 ; type
    ld d, a
    ld a, [wTmp + 3]
    bit 0, a
    jr nz, .dying
    ld a, d
    cp 10
    jr c, .art
    ld a, 9
.art:
    ld e, a
    ld hl, alien_pal
    ld d, 0
    add hl, de
    ld a, [hl]
    swap a
    ld [wTmp + 3], a
    ld a, e
    add a
    add a
    add SPR_ALIEN0
    ld d, a
    ld a, [wTmp + 3]
    ld e, a
    call Put16
    jr .alnext
.dying:
    ld a, [hl]                  ; frame
    cp 6
    jr nc, .alnext
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld e, 0
    call Put16
.alnext:
    ld a, [wTmp + 1]
    add 16
    cp MAXAL * 16
    jr c, .s
    xor a
.s: ld [wTmp + 1], a
    ld hl, wTmp + 2
    dec [hl]
    jr nz, .al
    ret

; DrawText: hl = string (charmap bytes, 0-terminated), b = OAM Y, c = OAM X
DrawText:
.l: ld a, [hli]
    or a
    ret z
    cp T_FONT0
    jr z, .sp
    sub T_FONT0
    add a
    add T_OFONT0
    ld d, a
    ld e, 0
    push hl
    call PutObj
    pop hl
.sp:
    ld a, c
    add 8
    ld c, a
    jr .l

DrawMessages:
    ld a, [wState]
    cp ST_WAVEMSG
    jr z, .wave
    cp ST_GAMEOVER
    ret nz
    ld hl, txtGameOver
    ld b, 80
    ld c, 53
    jp DrawText
.wave:
    ld hl, txtWave
    ld b, 80
    ld c, 65                    ; centred for one digit
    ld a, [wWave]
    cp 9
    jr c, .one
    ld c, 61                    ; two digits
.one:
    call DrawText               ; c = x after "WAVE "
    ld a, [wWave]
    inc a
    cp 100
    jr c, .ok
    ld a, 99
.ok:
    ld d, 0
.t: cp 10
    jr c, .u
    sub 10
    inc d
    jr .t
.u: ld e, a
    ld a, d
    or a
    jr z, .ones
    inc a
    add a
    add T_OFONT0
    push de
    ld d, a
    ld e, 0
    call PutObj
    pop de
    ld a, c
    add 8
    ld c, a
.ones:
    ld a, e
    inc a
    add a
    add T_OFONT0
    ld d, a
    ld e, 0
    jp PutObj

txtWave:     db "WAVE ", 0
txtGameOver: db "GAME OVER", 0
