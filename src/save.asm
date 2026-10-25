; Battery-backed hi-score (MBC1 + 8 KB SRAM). Layout at $A000: "GF", 7 digit bytes, checksum.

DEF SRAM_BASE EQU $A000

SECTION "save", ROM0

; Loads the saved hi-score into wHi if the SRAM block is valid.
LoadHi:
    ld a, $0A
    ld [$0000], a
    ld hl, SRAM_BASE
    ld a, [hli]
    cp $47
    jr nz, .bad
    ld a, [hli]
    cp $46
    jr nz, .bad
    ld b, 7
    ld c, $5A
    push hl
.sum:
    ld a, [hli]
    cp 10
    jr nc, .badpop
    add c
    ld c, a
    dec b
    jr nz, .sum
    ld a, [hl]
    cp c
    jr nz, .badpop
    pop hl
    ld de, wHi
    ld bc, 7
    call MemCopy
    jr .off
.badpop:
    pop hl
.bad:
.off:
    xor a
    ld [$0000], a
    ret

SaveHi:
    ld a, $0A
    ld [$0000], a
    ld hl, SRAM_BASE
    ld a, $47
    ld [hli], a
    ld a, $46
    ld [hli], a
    ld de, wHi
    ld b, 7
    ld c, $5A
.l:
    ld a, [de]
    inc de
    ld [hli], a
    add c
    ld c, a
    dec b
    jr nz, .l
    ld [hl], c
    xor a
    ld [$0000], a
    ret

; Applies the normal or paused (dimmed) palettes according to wPause.
ApplyPalettes:
    ld a, [wFade]
    ld c, a
    ld a, [wPause]
    or a
    jr z, .lvl
    ld a, c
    or a
    jr nz, .lvl
    inc c                       ; pause dims by one fade step
.lvl:
    ld b, 0
    ld hl, fadeBGP
    add hl, bc
    ld a, [hl]
    ldh [rBGP], a
    ld hl, fadeOBP0
    add hl, bc
    ld a, [hl]
    ldh [rOBP0], a
    ld hl, fadeOBP1
    add hl, bc
    ld a, [hl]
    ldh [rOBP1], a
    ret

fadeBGP:  db %00011011, %01101111, %10111111, %11111111
fadeOBP0: db %10010000, %11100100, %11111000, %11111100
fadeOBP1: db %10000100, %11011000, %11101100, %11111100
