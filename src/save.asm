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
    ld a, [wPause]
    or a
    jr nz, .dim
    ld a, %00011011
    ldh [rBGP], a
    ld a, %10010000
    ldh [rOBP0], a
    ld a, %10000100
    ldh [rOBP1], a
    ret
.dim:
    ld a, %01101111
    ldh [rBGP], a
    ld a, %11100100
    ldh [rOBP0], a
    ld a, %11011000
    ldh [rOBP1], a
    ret
