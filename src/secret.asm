SECTION "secret", ROM0

; Secret screen: on the options screen press DOWN DOWN UP UP SELECT.
; The screen flashes, then a big heart grows from the centre outward and "FOR MAYA" fades in
; from the flash colour. A, B, START or SELECT returns to the options screen.

; SecretCheck: b = new keys. Tracks the secret sequence (same method as CheatCheck).
SecretCheck:
    ld a, b
    or a
    ret z
    ld a, [wSecPos]
    ld e, a
    ld d, 0
    ld hl, secretSeq
    add hl, de
    ld a, [hl]
    and b
    jr z, .miss
    ld a, e
    inc a
    ld [wSecPos], a
    cp 5
    ret nz
    xor a
    ld [wSecPos], a
    jp ShowSecret
.miss:
    xor a
    bit 7, b                        ; DOWN restarts the sequence (it is the first key)
    jr z, .set
    inc a
.set:
    ld [wSecPos], a
    ret

secretSeq: db PAD_DOWN, PAD_DOWN, PAD_UP, PAD_UP, PAD_SELECT

txtForMaya: db "FOR MAYA", 0
txtRobinson: db "ROBINSON", 0

; Enters the secret screen from the options screen.
ShowSecret:
    di
    call LcdOff
    call ClearMapA
    xor a
    ldh [hSplit], a
    ldh [hTitle], a
    ld [wPause], a
    ld [wPAlive], a
    ld [wDirty], a
    ld [wTimer], a
    ld [wTimer + 1], a
    ld a, ST_SECRET
    ld [wState], a
    ld a, 3
    ld [wFade], a
    call ApplyPalettes
    ld a, LCDC_FULL
    ldh [rLCDC], a
    xor a
    ldh [rIF], a
    ei
    ret

; Timeline, t = wTimer frames:
;   0-39   flash: black/normal blink every 4 frames (1UP sound at t=0)
;   40     heart centre (inner 2x2 tiles) grows in
;   52     whole heart appears
;   64     "FOR MAYA" appears
;   72-83  palette fades in from black in three steps
;   84+    normal; holds until A, B, START or SELECT
StateSecret:
    ld a, [wTimer]
    cp 100
    jr nc, .hold
    cp 40
    jr nc, .reveal
    or a
    jr nz, .fl
    ld a, SFX_1UP
    call Sfx
    ld a, [wTimer]
.fl:
    and 4
    ld a, 3
    jr z, .fs
    xor a
.fs:
    ld [wFade], a
    jr .tick
.reveal:
    cp 40
    jr nz, .r52
    jr .tick                        ; no partial heart: it appears whole at t=52
.r52:
    cp 52
    jr nz, .r64
    ld a, 1
    call DrawHeart
    jr .tick
.r64:
    cp 64
    jr nz, .r72
    ld hl, txtForMaya
    ld de, _SCRN0 + 32 * 10 + 6
    call PutStr
    ld hl, txtRobinson
    ld de, _SCRN0 + 32 * 12 + 6
    call PutStr
    jr .tick
.r72:
    cp 72
    jr c, .tick
    cp 84
    jr nc, .r84
    sub 72
    srl a
    srl a                           ; 0,1,2 for t = 72..83
    ld b, a
    ld a, 3
    sub b                           ; fade 3,2,1
    ld [wFade], a
    jr .tick
.r84:
    xor a
    ld [wFade], a
.tick:
    call ApplyPalettes
    ld hl, wTimer
    inc [hl]
    ret
.hold:
    ld a, [wKeysNew]
    and PAD_A | PAD_B | PAD_START | PAD_SELECT
    ret z
    call FadeOut
    jp ShowOptions

; DrawHeart: a = 0 draws only the inner 2x2 tiles, a = 1 draws the whole heart (4x4 tiles).
; Heart tiles are HEART0.. in row-major order; the heart sits at map rows 4-7, columns 8-11.
DrawHeart:
    ld b, a
    ld c, 0                         ; c = heart tile 0..15
.l:
    ld e, c
    ld d, 0
    ld hl, secHeartIn
    add hl, de
    ld a, [hl]
    or b
    ld a, T_BLANK
    jr z, .put
    ld a, c
    add HEART0
.put:
    push af
    ld a, c
    srl a
    srl a                           ; row = c / 4
    ld l, a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl                      ; hl = row * 32
    ld a, c
    and 3
    ld e, a
    ld d, 0
    add hl, de                      ; + column
    ld de, _SCRN0 + 32 * 4 + 8
    add hl, de
    pop af
    ld [hl], a
    inc c
    ld a, c
    cp 16
    jr nz, .l
    ret

; Sparkles around the heart, drawn from BuildOAM once the heart is whole (t >= 52).
; Eight fixed points (OAM y, x); each twinkles on for 16 frames, out of phase with its neighbours.
DrawSecretFX:
    ld a, [wTimer]
    cp 52
    ret c
    ; trill + shimmer once, on the frame the heart is whole
    sub 52
    jr nz, .nosnd
    ld a, SFX_SPARKLE
    call Sfx
.nosnd:
    ; each sparkle has a 32-frame life: grow (0-7), peak (8-15), shrink (16-23), rest (24-31)
    ld hl, secSparkPos
    ld c, 0                         ; sparkle index 0..7
.s:
    ld a, [hli]
    ld b, a                         ; OAM y (centre)
    ld a, [hli]
    ld e, a                         ; OAM x (centre)
    ; phase = (wTimer + index * 4) & 31
    ld a, [wTimer]
    ld d, a
    ld a, c
    add a
    add a                           ; index * 4
    add d
    and 31
    cp 24
    jr nc, .rest                    ; resting: nothing drawn
    ; size: 0..7 grow, 8..15 peak, 16..23 shrink -> 0 = small, 1 = full
    cp 8
    jr c, .small
    cp 16
    jr c, .full
    ; shrinking: small
.small:
    ld d, SPR_SPARK_S
    jr .draw
.full:
    ld d, SPR_SPARK
.draw:
    push hl
    push bc
    push de
    ; centre the 8x16 object: y-8, x-4
    ld a, b
    sub 8
    ld b, a
    ld a, e
    sub 4
    ld c, a
    pop de
    ld e, 0
    call PutObj
    pop bc
    pop hl
.rest:
    inc c
    ld a, c
    cp 8
    jr nz, .s
    ret

secSparkPos:
    db 30, 62,  30, 100,  44, 50,  44, 112
    db 60, 56,  60, 106,  70, 78,  26, 80

; 1 = inner tile of the 4x4 heart (centre 2x2 tiles)
secHeartIn:
    db 0,0,0,0
    db 0,1,1,0
    db 0,1,1,0
    db 0,0,0,0
