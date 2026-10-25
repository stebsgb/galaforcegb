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
.st:
    ld a, [hli]
    cp $FF
    jr z, .stdone
    ld b, a                     ; row
    ld a, [hli]
    ld c, a                     ; col
    ld a, [hli]
    ld e, a                     ; tile
    push hl
    ld h, 0
    ld l, b
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, c
    add l
    ld l, a
    ld a, h
    adc 0
    ld h, a
    ld bc, _SCRN0
    add hl, bc
    ld [hl], e
    pop hl
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

; row, column, star tile (T_STAR0 + n) for the title starfield
titleStars:
    db 1, 4, T_STAR0 + 0,  1, 15, T_STAR0 + 3,  4, 9, T_STAR0 + 1,  4, 18, T_STAR0 + 5
    db 6, 2, T_STAR0 + 4,  6, 13, T_STAR0 + 2,  8, 7, T_STAR0 + 6,  8, 17, T_STAR0 + 0
    db 10, 1, T_STAR0 + 3,  10, 12, T_STAR0 + 1,  12, 5, T_STAR0 + 5,  12, 16, T_STAR0 + 7
    db 13, 9, T_STAR0 + 2,  15, 3, T_STAR0 + 6,  15, 14, T_STAR0 + 4,  16, 8, T_STAR0 + 0
    db 16, 18, T_STAR0 + 3,  1, 10, T_STAR0 + 7
    db $FF
