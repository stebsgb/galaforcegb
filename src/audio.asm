; Sound driver: the original three-channel tunes (pulse1, pulse2, wave) ticked at 50 Hz
; from a 59.7 Hz frame, plus a small event-list SFX player that takes over pulse1/pulse2/noise.

SECTION "audioram", WRAM0
aPtr:     ds 6             ; aPtr..aGate (14 bytes) are copied straight from a TuneTable record
aSpd:     ds 4
aNr12:    ds 3
aGate:    db
aCnt:     ds 3
aPlay:    db
aAcc:     db
aGateCt:  db
aSfxOn:   db
aSfxCt:   db
aSfxPtr:  dw
aPaused:  db
aSfxLock: db              ; 1 while the last-life sound plays: nothing (bullets, explosions) can cut it
aSfxId:   db              ; id of the effect now playing (SFX_*), so a BOOM can be held off while the bomb sounds

SECTION "audio", ROM0

AudioInit:
    ld a, $80
    ldh [rNR52], a
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a
    xor a
    ldh [rNR30], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR42], a
    ld hl, WaveTable
    ld de, $FF30
    ld b, 16
.wave:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .wave
    xor a
    ld [aPlay], a
    ld [aAcc], a
    ld [aGateCt], a
    ld [aSfxOn], a
    ld [aSfxLock], a
    ld [aPaused], a
    ret

; a = tune id. During the attract demo there is no music: any tune request silences the channels.
MusicPlay:
    push af
    ld a, [wDemo]
    or a
    jr z, .play
    pop af
    xor a
    ld [aPlay], a
    ld [aAcc], a
    ld [aGateCt], a
    ldh [rNR30], a
    ldh [rNR12], a
    ldh [rNR22], a
    ret
.play:
    pop af
    swap a
    ld e, a
    ld d, 0
    ld hl, TuneTable
    add hl, de
    ld de, aPtr
    ld b, 14
.copy:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ld a, 1
    ld [aCnt], a
    ld [aCnt + 1], a
    ld [aCnt + 2], a
    ld [aPlay], a
    xor a
    ld [aAcc], a
    ld [aGateCt], a
    ldh [rNR30], a
    xor a
    ld [aSfxOn], a                  ; the tune takes the pulse channels back, cutting any effect (e.g. the death explosion)
    ld [aSfxLock], a                ; a tune also releases the last-life lock
    ldh [rNR12], a
    ldh [rNR22], a
    ret

; Z set when every channel has reached the end of its stream
MusicBusy:
    ld hl, aPtr
    ld b, 3
    xor a
    ld c, a
.l:
    ld a, [hli]
    ld e, a
    ld a, [hli]
    ld d, a
    ld a, [de]
    or c
    ld c, a
    dec b
    jr nz, .l
    ld a, c
    or a
    ret

; toggles with wPause
AudioPause:
    ld a, [wPause]
    ld [aPaused], a
    or a
    ld a, $FF
    jr z, .set
    xor a
.set:
    ldh [rNR51], a
    ret

AudioUpdate:
    ld a, [aPaused]
    or a
    ret nz
    ld a, [aSfxOn]
    or a
    call nz, SfxStep
    ld a, [aGateCt]
    or a
    jr z, .nogate
    dec a
    ld [aGateCt], a
    jr nz, .nogate
    xor a
    ldh [rNR30], a
.nogate:
    ld a, [aPlay]
    or a
    ret z
    ld a, [aAcc]
    add 50
    cp 60
    jr c, .store
    sub 60
    ld [aAcc], a
    jr MusicTick
.store:
    ld [aAcc], a
    ret

MusicTick:
    ld c, 0
.ch:
    ld e, c
    ld d, 0
    ld hl, aCnt
    add hl, de
    dec [hl]
    jr nz, .next
    ld a, c
    add a
    ld e, a
    ld hl, aPtr
    add hl, de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld a, [de]
    or a
    jr nz, .note
    ld e, c                     ; channel finished: idle until restarted
    ld d, 0
    ld hl, aCnt
    add hl, de
    ld [hl], 1
    jr .next
.note:
    inc de
    ld [hl], d
    dec hl
    ld [hl], e
    ld b, a
    and 63
    cp 63
    jr z, .rest
    push bc
    call PlayNote
    pop bc
.rest:
    ld a, b
    rlca
    rlca
    and 3
    ld e, a
    ld d, 0
    ld hl, aSpd
    add hl, de
    ld a, [hl]
    ld e, c
    ld hl, aCnt
    add hl, de
    ld [hl], a
.next:
    inc c
    ld a, c
    cp 3
    jr nz, .ch
    ret

; a = note, c = channel
PlayNote:
    ld e, a
    ld d, 0
    ld a, c
    cp 2
    jr z, .wave
    ld a, [aSfxOn]
    or a
    ret nz
    ld hl, PulseFreq
    add hl, de
    add hl, de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld hl, aNr12
    ld b, 0
    add hl, bc
    ld a, c
    or a
    jr nz, .p2
    xor a
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    ld a, [hl]
    ldh [rNR12], a
    ld a, e
    ldh [rNR13], a
    ld a, d
    or $80
    ldh [rNR14], a
    ret
.p2:
    ld a, $80
    ldh [rNR21], a
    ld a, [hl]
    ldh [rNR22], a
    ld a, e
    ldh [rNR23], a
    ld a, d
    or $80
    ldh [rNR24], a
    ret
.wave:
    ld hl, WaveFreq
    add hl, de
    add hl, de
    ld a, [hli]
    ld e, a
    ld a, [hl]
    ld d, a
    ld a, $80
    ldh [rNR30], a
    ld a, $40                   ; wave at 50% so it doesn't swamp the pulses
    ldh [rNR32], a
    ld a, e
    ldh [rNR33], a
    ld a, d
    or $80
    ldh [rNR34], a
    ld a, [aGate]
    ld [aGateCt], a
    ret

; a = sfx id. FIRE never interrupts another effect.
Sfx:
    push bc
    push de
    push hl
    ld b, a
    ld a, [wDemo]                   ; no sound effects during the attract demo
    or a
    jr nz, .out
    ld a, [aSfxLock]                ; the last-life sound blocks every other effect until it ends
    or a
    jr nz, .out
    ld a, b                         ; the last-life effect cuts the tune rather than being dropped by it
    cp SFX_LAST
    jr z, .force
    cp SFX_BOMB                     ; the smart bomb cuts whatever is playing so it is always heard
    jr z, .force
    ld a, [aPlay]                   ; music overrides every effect while a tune is still playing
    or a
    jr z, .free
    push bc
    call MusicBusy                  ; Z when every channel has finished
    pop bc
    jr nz, .out
.free:
    ld a, b
    cp 2
    jr nc, .notfb
    ; FIRE (0) and BOOM (1) start at once, but not while the smart bomb is still sounding
    ld a, [aSfxOn]
    or a
    jr z, .go
    ld a, [aSfxId]
    cp SFX_BOMB
    jr z, .out
    jr .go
.notfb:
    ld a, [aSfxOn]
    or a
    jr nz, .out
    jr .go
.force:                             ; stop the tune's channels, then play the effect
    xor a
    ld [aPlay], a
    ld [aGateCt], a
    ldh [rNR30], a
.go:
    ld a, b
    ld [aSfxId], a
    add a
    ld e, a
    ld d, 0
    ld hl, SfxTable
    add hl, de
    ld a, [hli]
    ld [aSfxPtr], a
    ld a, [hl]
    ld [aSfxPtr + 1], a
    ld a, 1
    ld [aSfxOn], a
    ld a, b
    cp SFX_LAST
    jr nz, .nolock
    ld a, 1
    ld [aSfxLock], a
.nolock:
    xor a
    ld [aSfxCt], a
    call SfxStep
.out:
    pop hl
    pop de
    pop bc
    ret

SfxStep:
    ld a, [aSfxCt]
    or a
    jr z, .run
    dec a
    ld [aSfxCt], a
    ret nz
.run:
    ld a, [aSfxPtr]
    ld l, a
    ld a, [aSfxPtr + 1]
    ld h, a
.ev:
    ld a, [hli]
    cp $FF
    jr z, .end
    or a
    jr z, .t0
    dec a
    jr z, .t1
    ld de, rNR41
    ld b, 4
    jr .cp
.t0:
    ld de, rNR10
    ld b, 5
    jr .cp
.t1:
    ld de, rNR21
    ld b, 4
.cp:
    ld a, [hli]
    ld [de], a
    inc de
    dec b
    jr nz, .cp
    ld a, [hli]
    or a
    jr z, .ev
    ld [aSfxCt], a
    ld a, l
    ld [aSfxPtr], a
    ld a, h
    ld [aSfxPtr + 1], a
    ret
.end:
    xor a
    ld [aSfxOn], a
    ld [aSfxLock], a
    ret

INCLUDE "music.inc"
