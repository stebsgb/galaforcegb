SECTION "screens", ROM0

; PutStr: hl = 0-terminated string (charmap bytes), de = VRAM destination
PutStr:
.l: ld a, [hli]
    or a
    ret z
    ld [de], a
    inc de
    jr .l

ClearMapA:
    ld hl, _SCRN0
    ld bc, 1024
    ld a, T_BLANK
    jp MemFill

; gameplay tile map: row 0 = bottom strip (shown by the window), row 1 = top HUD
BuildGameMap:
    call ClearMapA
    ld a, T_FLAG
    ld [_SCRN0], a
    ld hl, strSC
    ld de, _SCRN0 + 32
    call PutStr
    ld hl, strHI
    ld de, _SCRN0 + 32 + 11
    call PutStr
    ld a, [wDemo]
    or a
    ret z
    ld hl, strDemo
    ld de, _SCRN0 + 8
    jp PutStr

; full-screen title (LCD is switched off while it is drawn)
ShowTitle:
    di
    call LcdOff
    call ClearMapA
    call ResetLogoTiles
    ; big title letters "GALFORCE": 2x2 tiles each
    ld hl, _SCRN0 + 32 * 2 + 1
    ld b, 9
    ld c, T_BIG0
.big:
    ld a, c
    ld [hli], a
    inc a
    ld [hl], a
    ld de, 31
    add hl, de
    inc a
    ld [hli], a
    inc a
    ld [hl], a
    ld de, -31
    add hl, de
    ld a, c
    add 4
    ld c, a
    dec b
    jr nz, .big
    ld hl, strBy
    ld de, _SCRN0 + 32 * 5 + 2
    call PutStr
    ld hl, strPort
    ld de, _SCRN0 + 32 * 7 + 2
    call PutStr
    ld hl, strSC
    ld de, _SCRN0
    call PutStr
    ld a, T_FONT0 + 1
    ld [_SCRN0 + 7], a
    ld hl, strHI
    ld de, _SCRN0 + 11
    call PutStr
    ld de, wHi
    ld hl, _SCRN0 + 13
    call HudNum
    ld hl, strSuperior
    ld de, _SCRN0 + 32 * 14 + 1
    call PutStr
    ld a, T_FLAG
    ld hl, _SCRN0 + 32 * 17
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ld hl, titleStars
    ld de, wStars
.st:
    ld a, [hli]
    cp $FF
    jr z, .stdone
    add a
    add a
    add a
    ld b, a                     ; y = row * 8
    ld a, [hli]
    add a
    add a
    add a
    ld c, a                     ; x = col * 8
    ld a, [hli]
    and 7
    add c
    ld [de], a                  ; x with a little jitter
    inc de
    ld a, b
    ld [de], a
    inc de
    jr .st
.stdone:
    ld hl, strStartGame
    ld de, _SCRN0 + 32 * 9 + 5
    call PutStr
    ld hl, strOptionsItem
    ld de, _SCRN0 + 32 * 11 + 6
    call PutStr
    xor a
    ldh [hSplit], a
    ld [wState], a
    ld [wPause], a
    ld [wPAlive], a
    call MenuDraw
    xor a
    ld [wIdle], a
    ld [wIdle + 1], a
    ld a, 3
    ld [wFade], a
    call ApplyPalettes
    call ClearField
    ld a, LCDC_FULL
    ldh [rLCDC], a
    xor a
    ldh [rIF], a
    ei
    ld a, MUS_DEMO
    call MusicPlay
    jp FadeIn

strSC:      db "SC", 0
strDemo:    db "DEMO", 0
strHI:      db "HI", 0
strPort:    db "GAME BOY EDITION", 0
strPress:   db "PRESS  START", 0
strHiTitle: db "HI-SCORE", 0
strBy:      db "BY KEVIN EDWARDS", 0
strSuperior: db "SUPERIOR SOFTWARE", 0

; Falling title stars as sprites, behind the logo/text (BG priority). Even-numbered stars fall
; every frame and use the second palette, odd ones every other frame: a little parallax.
TitleStars:
    ld hl, wStars
    ld a, [wFrame]
    ld [wTmp], a
    ld a, 0
    ld [wTmp + 1], a
.l: ld a, [wTmp + 1]
    cp 18
    ret nc
    ld a, [hli]
    ld c, a                     ; x
    ld a, [hl]
    ld b, a                     ; y
    ld a, [wTmp + 1]
    bit 0, a
    jr z, .fast
    ld a, [wTmp]
    and 1
    jr z, .nomove
.fast:
    inc b
    ld a, b
    cp 144
    jr c, .nomove
    ld b, 0
.nomove:
    ld a, b
    ld [hli], a
    ld a, b
    add 16
    ld b, a
    ld a, c
    add 8
    ld c, a
    ld a, [wTmp + 1]
    and 1
    swap a                      ; palette select bit 4
    or %10000000                ; behind BG colours 1-3
    ld e, a
    ld d, SPR_STAR
    push hl
    call PutObj
    pop hl
    ld a, [wTmp + 1]
    inc a
    ld [wTmp + 1], a
    jr .l

; Occasional shine across the GALAFORCE logo (called in VBlank). A 512-frame cycle; during the
; first 80 frames of every second 256 a lighter band sweeps over the logo one tile column per
; 4 frames, one tile rewritten per frame (face pixels shade 3 -> 2, restored from ROM behind it).
TitleShine:
    ld a, [wState]
    or a
    ret nz
    ld a, [wFade]
    or a
    ret nz
    ld hl, wTwk
    inc [hl]
    jr nz, .nc
    inc hl
    inc [hl]
.nc:
    ld a, [wTwk + 1]
    and 1
    ret z
    ld a, [wTwk]
    cp 80
    ret nc
    ld c, a
    srl a
    srl a
    ld b, a                     ; n = sweep column
    ld a, c
    and 3
    ld c, a
    bit 1, c
    jr nz, .restore
    ld a, b
    cp 18
    ret nc
    ld a, $FF
    jr .go
.restore:
    ld a, b
    sub 2
    ret c
    ld b, a
    xor a
.go:
    ld [wTmp], a                ; $FF = highlight, 0 = restore
    ld a, b                     ; tile column 0..17
    ld e, a
    srl a
    add a
    add a
    ld d, a
    ld a, e
    and 1
    add d
    ld d, a
    ld a, c
    and 1
    add a
    add d
    add T_BIG0
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld b, h
    ld c, l
    ld hl, _VRAM_BG
    add hl, bc
    ld d, h
    ld e, l
    ld hl, gfx_bg
    add hl, bc
    ld a, [wTmp]
    or a
    jr nz, .hi
    ld bc, 16
    jp MemCopy
.hi:
    ld b, 8
.r: ld a, [hli]
    ld c, a
    ld a, [hli]
    push af
    cpl
    and c
    ld [de], a
    inc de
    pop af
    ld [de], a
    inc de
    dec b
    jr nz, .r
    ret

; Puts the logo tiles back to normal (LCD off)
ResetLogoTiles:
    ld hl, gfx_bg + T_BIG0 * 16
    ld de, _VRAM_BG + T_BIG0 * 16
    ld bc, 36 * 16
    call MemCopy
    xor a
    ld [wTwk], a
    ld [wTwk + 1], a
    ret

; row, column, star tile (T_STAR0 + n) for the title starfield
titleStars:
    db 1, 4, T_STAR0 + 0,  1, 15, T_STAR0 + 3,  4, 9, T_STAR0 + 1,  4, 18, T_STAR0 + 5
    db 6, 2, T_STAR0 + 4,  6, 13, T_STAR0 + 2,  8, 7, T_STAR0 + 6,  8, 17, T_STAR0 + 0
    db 10, 1, T_STAR0 + 3,  10, 12, T_STAR0 + 1,  12, 5, T_STAR0 + 5,  12, 16, T_STAR0 + 7
    db 13, 9, T_STAR0 + 2,  15, 3, T_STAR0 + 6,  15, 14, T_STAR0 + 4,  16, 8, T_STAR0 + 0
    db 16, 18, T_STAR0 + 3,  1, 10, T_STAR0 + 7
    db $FF
