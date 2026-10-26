SECTION "fx", ROM0

; ---------------------------------------------------------------- palette fades
; One frame, with the audio kept running (used while the main loop is not).
FadeWait:
.w: halt
    nop
    ldh a, [hVBlank]
    or a
    jr z, .w
    xor a
    ldh [hVBlank], a
    call hDma
    push bc
    call AudioUpdate
    pop bc
    ret

; Fade to black in three steps
FadeOut:
    ld b, 1
.s: ld a, b
    ld [wFade], a
    push bc
    call ApplyPalettes
    pop bc
    ld c, 5
.w: call FadeWait
    dec c
    jr nz, .w
    inc b
    ld a, b
    cp 4
    jr c, .s
    ; sprites faded with the palette; now clear them so nothing carries onto the next screen
    ld hl, wOAM
    ld bc, 160
    xor a
    call MemFill
    jp hDma

; Fade from black to normal
FadeIn:
    ld b, 2
.s: ld a, b
    ld [wFade], a
    push bc
    call ApplyPalettes
    pop bc
    ld c, 5
.w: call FadeWait
    dec c
    jr nz, .w
    dec b
    jr nz, .s
    xor a
    ld [wFade], a
    jp ApplyPalettes

; ---------------------------------------------------------------- attract mode
StartDemo:
    ld hl, wHi
    ld de, wHiBak
    ld bc, 7
    call MemCopy
    ld a, 1
    ld [wDemo], a
    xor a
    ld [wDemoT], a
    ld [wDemoT + 1], a
    ld a, $5A
    ld [wRng], a
    ld a, $C3
    ld [wRng + 1], a
    call FadeOut
    jp StartGame

; Leaves a demo (restoring the hi-score) or a finished game, via a fade, to the title
ReturnToTitle:
    ld a, [wDemo]
    or a
    jr z, .t
    ld hl, wHiBak
    ld de, wHi
    ld bc, 7
    call MemCopy
    xor a
    ld [wDemo], a
.t: xor a
    ld [wMenuSel], a
    call FadeOut
    jp ShowTitle

; Called each frame after ReadKeys. In the demo, replaces the pad with a simple auto-pilot.
DemoInput:
    ld a, [wDemo]
    or a
    ret z
    ld a, [wKeysNew]
    and PAD_START
    jr nz, .exit
    ld hl, wDemoT
    inc [hl]
    jr nz, .nc
    inc hl
    inc [hl]
.nc:
    ld a, [wDemoT + 1]
    cp DEMO_FRAMES_HI
    jr nc, .exit
    ld a, [wState]
    cp ST_GAMEOVER
    jr z, .quiet
    ld a, [wPX]
    ld d, a
    ld e, $FF                   ; best distance
    ld c, $FF                   ; best target x ($FF none)
    ld h, HIGH(wAliens)
    ld l, 0
    ld b, MAXAL
.l: ld a, [hl]
    cp $80
    jr nz, .n
    inc l
    inc l
    ld a, [hl]
    dec l
    dec l
    srl a
    cp 120
    jr nc, .n                   ; off the top of the field
    inc l
    ld a, [hl]
    cp 150
    jr nc, .n
    sub d
    jr nc, .p
    cpl
    inc a
.p: cp e
    jr nc, .n
    ld e, a
    ld a, [hl]
    ld c, a
.n: ld a, l
    and $F0
    add 16
    ld l, a
    dec b
    jr nz, .l
    ld b, PAD_A
    ld a, c
    cp $FF
    jr z, .sweep
    sub d
    jr c, .toleft
    cp 4
    jr c, .set
    ld b, PAD_A | PAD_RIGHT
    jr .set
.toleft:
    cpl
    inc a
    cp 4
    jr c, .set
    ld b, PAD_A | PAD_LEFT
    jr .set
.sweep:
    ld a, [wFrame]
    bit 6, a
    ld b, PAD_A | PAD_RIGHT
    jr z, .set
    ld b, PAD_A | PAD_LEFT
.set:
    ld a, b
    ld [wKeys], a
.quiet:
    xor a
    ld [wKeysNew], a
    ret
.exit:
    xor a
    ld [wKeysNew], a
    call ReturnToTitle
    ret
