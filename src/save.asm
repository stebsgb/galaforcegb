; Battery-backed hi-score (MBC1 + 8 KB SRAM). Layout at $A000: "GF", 7 digit bytes, checksum.

DEF SRAM_BASE EQU $A000

SECTION "save", ROM0

; Loads the saved hi-score into wHi if the SRAM block is valid.
; Returns hl = SRAM address of the hi-score slot for the current continue setting (wOptCont 0..3).
; Slot 0 is at $A000 (as before); slots 1..3 at $A020, $A030, $A040.
SlotPtr:
    ld a, [wOptCont]
    ld e, a
    ld d, 0
    ld hl, slot_sram
    add hl, de
    add hl, de
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret

slot_sram: dw SRAM_BASE, SRAM_BASE + $20, SRAM_BASE + $30, SRAM_BASE + $40

; Default hi-score for each continue setting (0..3), used when no valid score is saved.
; Digits are 7 bytes, most significant first (index 0 = 10^6, index 2 = 10^4, index 1 = 10^5).
; 0 continues = 25000, 1 = 50000, 2 = 75000, 3 = 100000.
default_hi: db 0,0,2,5,0,0,0    ; 25000
            db 0,0,5,0,0,0,0    ; 50000
            db 0,0,7,5,0,0,0    ; 75000
            db 0,1,0,0,0,0,0    ; 100000
ResetHi:
    ld a, [wOptCont]
    and 3
    ld e, a
    ld d, 0
    ld hl, default_hi
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    ld de, wHi
    ld bc, 7
    jp MemCopy

LoadHi:
    ld a, $0A
    ld [$0000], a
    call SlotPtr
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
    call ResetHi
.off:
    xor a
    ld [$0000], a
    ret

SaveHi:
    ld a, $0A
    ld [$0000], a
    call SlotPtr
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
    ld a, [wOptBg]
    add a
    add a
    add c                       ; white-background tables follow the black ones
    ld c, a
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

; entries 0-3: black background fading to black; 4-7: white background fading to white
fadeBGP:  db %00011011, %01101111, %10111111, %11111111
          db %11100100, %10010000, %01000000, %00000000
fadeOBP0: db %10010000, %11100100, %11111000, %11111100
          db %01101100, %00011000, %00000100, %00000000
fadeOBP1: db %10000100, %11011000, %11101100, %11111100
          db %01111000, %00100100, %00010000, %00000000
