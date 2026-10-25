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
    ld hl, _SCRN0 + 32 * 4 + 1
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
    ld hl, strCred1
    ld de, _SCRN0 + 32 * 14 + 1
    call PutStr
    ld hl, strCred2
    ld de, _SCRN0 + 32 * 15 + 3
    call PutStr
    ld hl, strCred3
    ld de, _SCRN0 + 32 * 16 + 1
    call PutStr
    ld a, T_FLAG
    ld hl, _SCRN0 + 32 * 17
    ld [hli], a
    ld [hli], a
    ld [hl], a
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
    inc a
    ldh [hTitle], a
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
strPress:   db "PRESS  START", 0
strHiTitle: db "HI-SCORE", 0
strCred1:   db "BBC ORIGINAL 1986", 0
strCred2:   db "KEVIN EDWARDS", 0
strCred3:   db "SUPERIOR SOFTWARE", 0

; Title screen split: text rows come from the $9800 map, the gaps show the scrolling star map at
; $9C00 (same stars and speed as in the game). Each entry: line where the next split happens (the blank bottom line of a text row,
; so the mid-line map switch is invisible), then 1 = stars.
titleSegs:
    db 7, 0,  15, 1,  31, 0,  47, 1,  55, 0,  71, 1,  79, 0,  87, 1,  95, 0,  111, 1,  200, 0

; Called from the STAT interrupt (af already pushed) while the title is shown
TitleStat:
    push de
    push hl
    ldh a, [hSeg]
    inc a
    ldh [hSeg], a
    add a
    ld e, a
    ld d, 0
    ld hl, titleSegs
    add hl, de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
.hb:
    ldh a, [rSTAT]
    and 3
    jr nz, .hb
    ld a, d
    or a
    jr z, .text
    ldh a, [hStarY]
    ldh [rSCY], a
    ld a, LCDC_TSTAR
    jr .set
.text:
    xor a
    ldh [rSCY], a
    ld a, LCDC_FULL
.set:
    ldh [rLCDC], a
    ld a, e
    ldh [rLYC], a
    pop hl
    pop de
    pop af
    reti

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


