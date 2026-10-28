SECTION "hud", ROM0

; HudNum: de = 7 digit buffer, hl = VRAM destination (leading zeros suppressed)
HudNum:
    ld b, 6
    ld c, 1
.l: ld a, [de]
    inc de
    or a
    jr nz, .show
    bit 0, c
    jr nz, .blank
    jr .show2
.show:
    ld c, 0
.show2:
    add T_FONT0 + 1
    jr .put
.blank:
    ld a, T_FONT0
.put:
    ld [hli], a
    dec b
    jr nz, .l
    ld a, [de]
    add T_FONT0 + 1
    ld [hl], a
    ret

; Called right after VBlank starts
HudUpdate:
    ldh a, [hSplit]
    or a
    ret z
    ld de, wScore
    ld hl, _SCRN0 + 32 + 2
    call HudNum
    ld de, wHi
    ld hl, _SCRN0 + 32 + 13
    call HudNum
    ; wave number (bottom strip, window row 0)
    ld a, [wWave]
    inc a
    cp 100
    jr c, .ok
    ld a, 99
.ok:
    ld b, 0
.t: cp 10
    jr c, .d
    sub 10
    inc b
    jr .t
.d: ld c, a
    ld hl, _SCRN0 + 1
    ld a, b
    or a
    jr nz, .tens
    ld a, T_FONT0
    jr .wt
.tens:
    add T_FONT0 + 1
.wt:
    ld [hli], a
    ld a, c
    add T_FONT0 + 1
    ld [hl], a
    ; spare lives (right side)
    ld hl, _SCRN0 + 15
    ld a, [wLives]
    ld b, a
    ld c, 5
.life:
    ld a, b
    or a
    jr z, .no
    dec b
    ld a, T_LIFE
    jr .lp
.no:
    ld a, T_BLANK
.lp:
    ld [hli], a
    dec c
    jr nz, .life
    ; smart bombs (lower status, left of the lives): icon, then "X" and count when there are two
    ld hl, _SCRN0 + 4
    ld a, [wBombs]
    or a
    jr z, .nobomb
    ld a, T_BOMB
    ld [hli], a
    ld a, [wBombs]
    cp 2
    jr nz, .bombone
    ld a, T_FONT0 + 34              ; 'X' (font order: space=0, '0'=1 ... 'X'=34)
    ld [hli], a
    ld a, T_FONT0 + 3               ; digit 2 ('0'=1, so '2'=3)
    ld [hl], a
    ret
.bombone:
    ld a, T_BLANK
    ld [hli], a
    ld [hl], a
    ret
.nobomb:
    ld a, T_BLANK
    ld [hli], a
    ld [hli], a
    ld [hl], a
    ret
