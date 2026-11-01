; ---------------------------------------------------------------- GBC colour
; Bank 1 (bank 0 is full). Called as a normal subroutine: the game never switches ROM banks.
; On a Game Boy Color (hCgb = 1) the DMG palette registers are ignored. CgbFlush maps each DMG
; shade (0 lightest .. 3 darkest) to a colour in the palette for that register:
;   BGP  -> background palette 0      OBP0 -> object palette 0      OBP1 -> object palette 1
; The DMG registers still drive the fades, pause and flashes, so those work unchanged.
; Palette RAM is written in VBlank (MainLoop and FadeWait) and once at boot with the LCD off.
SECTION "cgb", ROMX, BANK[1]

; Clears the BG attribute map in VRAM bank 1 on a GBC so every tile uses palette 0 and VRAM bank 0.
; Called once at boot with the LCD off.
CgbInit:
    ldh a, [hCgb]
    or a
    ret z
    ld a, 1
    ldh [rVBK], a
    ld hl, _SCRN0
    ld bc, $0800
    xor a
    call MemFill
    xor a
    ldh [rVBK], a
    ret

; Preserves bc, de and hl.
CgbFlush:
    ldh a, [hCgb]
    or a
    ret z
    push bc
    push de
    push hl
    ld a, $80                       ; auto-increment from colour 0 of background palette 0
    ldh [rBCPS], a
    ldh a, [rBGP]
    ld hl, cgb_bg
    ld c, LOW(rBCPD)
    call CgbPal
    ld a, $80                       ; object palette 0, then palette 1 (auto-increment crosses palettes)
    ldh [rOCPS], a
    ldh a, [rOBP0]
    ld hl, cgb_obj0
    ld c, LOW(rOCPD)
    call CgbPal
    ldh a, [rOBP1]
    ld hl, cgb_obj1
    call CgbPal
    pop hl
    pop de
    pop bc
    ret

; a = DMG palette byte, hl = 4 colours for shades 0..3 (2 bytes each, BGR555), c = palette data port
; Writes colour index 0..3 of the palette: colour index i gets the colour for the shade in bits i*2.
CgbPal:
    ld e, a
    ld b, 4
.c: push hl
    ld a, e
    and 3
    add a                           ; shade * 2
    add l
    ld l, a
    jr nc, .n
    inc h
.n: ld a, [hli]
    ldh [c], a
    ld a, [hl]
    ldh [c], a
    pop hl
    srl e
    srl e
    dec b
    jr nz, .c
    ret

; BGR555 colours by DMG shade (0 lightest .. 3 darkest). Same palette in both background modes.
; Each line is one column of the palette chart: white, light, dark, black.
cgb_bg:   dw $7FFF, $7A90, $7061, $0000   ; blue
cgb_obj0: dw $7FFF, $465C, $2130, $0000   ; salmon / brown
cgb_obj1: dw $7FFF, $37D6, $1A09, $0000   ; green
