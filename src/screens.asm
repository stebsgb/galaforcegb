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
    ld hl, _SCRN0 + 32 * 3 + 1
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
    ld hl, strPort
    ld de, _SCRN0 + 32 * 7 + 2
    call PutStr
    ld hl, strStartGame
    ld de, _SCRN0 + 32 * 9 + 5
    call PutStr
    ld hl, strOptionsItem
    ld de, _SCRN0 + 32 * 11 + 6
    call PutStr
    ld de, wHi
    ld hl, _SCRN0 + 32 * 13 + 10
    call HudNum
    ld hl, strHiTitle
    ld de, _SCRN0 + 32 * 13 + 3
    call PutStr
    ld hl, strOrig1
    ld de, _SCRN0 + 32 * 15 + 1
    call PutStr
    ld hl, strOrig2
    ld de, _SCRN0 + 32 * 16 + 2
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
strOrig1:   db "ORIGINAL BBC MICRO", 0
strOrig2:   db "BY KEVIN EDWARDS", 0
