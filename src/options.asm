; Options: starting lives (1..5) and black/white background, stored in SRAM at $A010.
; Layout: $4F $50, lives, bg, checksum (lives + bg + $5A).

DEF OPT_SRAM EQU $A010
DEF OPT_ROW_LIVES EQU 4
DEF OPT_ROW_BG    EQU 6
DEF OPT_ROW_LEVEL EQU 8
DEF OPT_ROW_CONT  EQU 10
DEF OPT_ROW_BACK  EQU 12

SECTION "options", ROM0

LoadOptions:
    ld a, $0A
    ld [$0000], a
    ld hl, OPT_SRAM
    ld a, [hli]
    cp $4F
    jr nz, .off
    ld a, [hli]
    cp $50
    jr nz, .off
    ld b, [hl]                  ; lives
    inc hl
    ld c, [hl]                  ; bg
    inc hl
    ld a, b
    add c
    add $5A
    cp [hl]
    jr nz, .off
    ld a, b
    or a
    jr z, .off
    cp 6
    jr nc, .off
    ld a, c
    cp 2
    jr nc, .off
    ld a, b
    ld [wOptLives], a
    ld a, c
    ld [wOptBg], a
.off:
    xor a
    ld [$0000], a
    ret

SaveOptions:
    ld a, $0A
    ld [$0000], a
    ld hl, OPT_SRAM
    ld a, $4F
    ld [hli], a
    ld a, $50
    ld [hli], a
    ld a, [wOptLives]
    ld [hli], a
    ld b, a
    ld a, [wOptBg]
    ld [hli], a
    add b
    add $5A
    ld [hl], a
    xor a
    ld [$0000], a
    ret

; Opens the options screen from the title (called after a fade out)
ShowOptions:
    di
    call LcdOff
    call ClearMapA
    ld hl, strOptions
    ld de, _SCRN0 + 32 * 2 + 6
    call PutStr
    ld hl, strLives
    ld de, _SCRN0 + 32 * OPT_ROW_LIVES + 4
    call PutStr
    ld hl, strBackground
    ld de, _SCRN0 + 32 * OPT_ROW_BG + 4
    call PutStr
    ld hl, strBack
    ld de, _SCRN0 + 32 * OPT_ROW_BACK + 4
    call PutStr
    ld hl, strHint1
    ld de, _SCRN0 + 32 * 16 + 1
    call PutStr
    ld hl, strHint2
    ld de, _SCRN0 + 32 * 17 + 6
    call PutStr
    xor a
    ldh [hSplit], a
    ldh [hTitle], a
    ld [wPause], a
    ld [wPAlive], a
    ld [wMenuSel], a
    ld a, ST_OPTIONS
    ld [wState], a
    call MenuDraw
    ld a, 3
    ld [wFade], a
    call ApplyPalettes
    call ClearField
    ld a, LCDC_FULL
    ldh [rLCDC], a
    xor a
    ldh [rIF], a
    ei
    jp FadeIn

; Leaves the options screen: saves, fades, back to the title with OPTIONS selected
LeaveOptions:
    call SaveOptions
    call FadeOut
    ld a, 1
    ld [wMenuSel], a
    jp ShowTitle

StateOptions:
    ld a, [wKeysNew]
    ld b, a
    and PAD_B
    jr nz, LeaveOptions
    call CheatCheck
    ld a, b
    and PAD_UP
    jr z, .nu
    ld a, [wMenuSel]
    or a
    jr z, .nu
    dec a
    cp 2
    jr c, .u
    ld c, a
    ld a, [wCheat]
    or a
    ld a, c
    jr nz, .u
    ld a, 1                     ; WAVE and CONTINUES rows only exist after the cheat
.u: ld [wMenuSel], a
    ld a, 1
    ld [wDirty], a
.nu:
    ld a, b
    and PAD_DOWN
    jr z, .nd
    ld a, [wMenuSel]
    cp 4
    jr nc, .nd
    inc a
    cp 2
    jr c, .d
    cp 4
    jr nc, .d
    ld c, a
    ld a, [wCheat]
    or a
    ld a, c
    jr nz, .d
    ld a, 4
.d: ld [wMenuSel], a
    ld a, 1
    ld [wDirty], a
.nd:
    ld a, [wMenuSel]
    cp 4
    jp z, .back
    cp 3
    jr z, .cont
    cp 2
    jr z, .level
    or a
    jr nz, .bg
    ; lives row: left / right
    ld a, b
    and PAD_LEFT
    jr z, .nl
    ld hl, wOptLives
    ld a, [hl]
    cp 2
    jr c, .nl
    dec [hl]
    ld a, 1
    ld [wDirty], a
.nl:
    ld a, b
    and PAD_RIGHT
    ret z
    ld hl, wOptLives
    ld a, [hl]
    cp 5
    ret nc
    inc [hl]
    ld a, 1
    ld [wDirty], a
    ret
.cont:
    ld hl, wOptCont
    ld a, b
    and PAD_LEFT
    jr z, .ncn
    ld a, [hl]
    or a
    jr z, .ncn
    dec [hl]
    ld a, 1
    ld [wDirty], a
.ncn:
    ld a, b
    and PAD_RIGHT
    ret z
    ld a, [hl]
    cp 3
    ret nc
    inc [hl]
    ld a, 1
    ld [wDirty], a
    ret
.level:
    ld hl, wStartLvl
    ld a, b
    and PAD_LEFT
    jr z, .nlv
    ld a, [hl]
    cp 2
    jr c, .nlv
    dec [hl]
    ld a, 1
    ld [wDirty], a
.nlv:
    ld a, b
    and PAD_RIGHT
    ret z
    ld a, [hl]
    cp 16
    ret nc
    inc [hl]
    ld a, 1
    ld [wDirty], a
    ret
.bg:
    ld a, b
    and PAD_LEFT | PAD_RIGHT | PAD_A
    ret z
    ld a, [wOptBg]
    xor 1
    ld [wOptBg], a
    ld a, 1
    ld [wDirty], a
    jp ApplyPalettes
.back:
    ld a, b
    and PAD_A | PAD_START
    ret z
    jp LeaveOptions

; Cheat code on the options screen: UP UP DOWN DOWN SELECT reveals the LEVEL row. b = new keys
CheatCheck:
    ld a, b
    or a
    ret z
    ld a, [wCheatPos]
    ld e, a
    ld d, 0
    ld hl, cheatSeq
    add hl, de
    ld a, [hl]
    and b
    jr z, .miss
    ld a, e
    inc a
    ld [wCheatPos], a
    cp 5
    ret nz
    xor a
    ld [wCheatPos], a
    ld a, 1
    ld [wCheat], a
    ld [wDirty], a
    ld a, SFX_1UP
    jp Sfx
.miss:
    xor a
    bit 6, b                    ; PAD_UP restarts the sequence
    jr z, .set
    inc a
.set:
    ld [wCheatPos], a
    ret

cheatSeq: db PAD_UP, PAD_UP, PAD_DOWN, PAD_DOWN, PAD_SELECT

; Title menu input (selection 0 = start, 1 = options)
TitleMenuKeys:
    ld a, [wKeysNew]
    ld b, a
    and PAD_UP
    jr z, .nu
    xor a
    ld [wMenuSel], a
    ld a, 1
    ld [wDirty], a
.nu:
    ld a, b
    and PAD_DOWN
    ret z
    ld a, 1
    ld [wMenuSel], a
    ld [wDirty], a
    ret

; Redraws the dynamic menu tiles; only safe in VBlank or with the LCD off
MenuRefresh:
    ld a, [wDirty]
    or a
    ret z
    ldh a, [hSplit]
    or a
    ret nz
    xor a
    ld [wDirty], a
MenuDraw:
    ld a, [wState]
    or a
    jp z, .title
    cp ST_OPTIONS
    ret nz
    ld a, [wMenuSel]
    ld c, a
    ld hl, _SCRN0 + 32 * OPT_ROW_LIVES + 2
    ld a, c
    cp 0
    call CursorTile
    ld hl, _SCRN0 + 32 * OPT_ROW_BG + 2
    ld a, c
    cp 1
    call CursorTile
    ld hl, _SCRN0 + 32 * OPT_ROW_LEVEL + 2
    ld a, c
    cp 2
    call CursorTile
    ld hl, _SCRN0 + 32 * OPT_ROW_CONT + 2
    ld a, c
    cp 3
    call CursorTile
    ld hl, _SCRN0 + 32 * OPT_ROW_BACK + 2
    ld a, c
    cp 4
    call CursorTile
    ld a, [wCheat]
    or a
    jr z, .nolv
    ld hl, strCont
    ld de, _SCRN0 + 32 * OPT_ROW_CONT + 4
    call PutStr
    ld a, [wOptCont]
    add T_FONT0 + 1
    ld [_SCRN0 + 32 * OPT_ROW_CONT + 15], a
    ld hl, strLevel
    ld de, _SCRN0 + 32 * OPT_ROW_LEVEL + 4
    call PutStr
    ld a, [wStartLvl]
    ld de, _SCRN0 + 32 * OPT_ROW_LEVEL + 15
    cp 10
    jr nc, .two
    add T_FONT0 + 1
    ld [de], a
    inc de
    ld a, T_FONT0
    ld [de], a
    jr .nolv
.two:
    sub 10
    add T_FONT0 + 1
    ld c, a
    ld a, T_FONT0 + 2           ; tens digit is always 1
    ld [de], a
    inc de
    ld a, c
    ld [de], a
.nolv:
    ld a, [wOptLives]
    add T_FONT0 + 1
    ld [_SCRN0 + 32 * OPT_ROW_LIVES + 15], a
    ld hl, strBlack
    ld a, [wOptBg]
    or a
    jr z, .b
    ld hl, strWhite
.b: ld de, _SCRN0 + 32 * OPT_ROW_BG + 15
    jp PutStr
.title:
    ld a, [wMenuSel]
    ld c, a
    ld hl, _SCRN0 + 32 * 9 + 3
    ld a, c
    cp 0
    call CursorTile
    ld hl, _SCRN0 + 32 * 11 + 3
    ld a, c
    cp 1
    jp CursorTile

; hl = tile address, Z flag set when this row is the selected one
CursorTile:
    ld a, CHARVAL(" ")
    jr nz, .w
    ld a, CHARVAL(">")
.w: ld [hl], a
    ret

; Sprite preview so the contrast of the chosen background can be judged
BuildOptionsOAM:
    ld b, 128
    ld c, 32
    ld d, SPR_PLAYER
    ld e, 0
    call Put16
    xor a
    ld [wTmp], a
    ld a, 32 + 24
    ld [wTmp + 1], a
.l: ld a, [wTmp]
    ld c, a
    ld b, 0
    ld hl, alien_pal
    add hl, bc
    ld a, [hl]
    swap a
    ld e, a
    ld a, c
    add a
    add a
    add SPR_ALIEN0
    ld d, a
    ld a, [wTmp + 1]
    ld c, a
    ld b, 128
    call Put16
    ld a, [wTmp + 1]
    add 24
    ld [wTmp + 1], a
    ld a, [wTmp]
    inc a
    ld [wTmp], a
    cp 4
    jr c, .l
    ret

strOptions:    db "OPTIONS", 0
strLives:      db "LIVES", 0
strLevel:      db "WAVE ", 0
strCont:       db "CONTINUES", 0
strBackground: db "BACKGROUND", 0
strBack:       db "BACK", 0
strBlack:      db "BLACK", 0
strWhite:      db "WHITE", 0
strHint1:      db "LEFT/RIGHT CHANGES", 0
strHint2:      db "B = BACK", 0
strStartGame:  db "START GAME", 0
strOptionsItem: db "OPTIONS", 0
