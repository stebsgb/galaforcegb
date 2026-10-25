SECTION "game", ROM0

GameUpdate:
    ld a, [wState]
    or a
    jp z, StateTitle
    ; pause toggle
    cp ST_GAMEOVER
    jr z, .nopause
    ld a, [wKeysNew]
    and PAD_START
    jr z, .nopause
    ld a, [wPause]
    xor 1
    ld [wPause], a
    call ApplyPalettes
    call AudioPause
.nopause:
    ld a, [wPause]
    or a
    ret nz
    ; scrolling starfield
    ld a, [wFrame]
    and 1
    jr nz, .nostar
    ldh a, [hStarY]
    dec a
    ldh [hStarY], a
.nostar:
    ld a, [wState]
    cp ST_WAVEMSG
    jp z, StateWaveMsg
    cp ST_PLAY
    jp z, StatePlay
    cp ST_PDEAD
    jp z, StatePDead
    jp StateGameOver

StateTitle:
    ld a, [wKeysNew]
    and PAD_START
    jr nz, .go
    ld hl, wIdle
    inc [hl]
    jr nz, .nc
    inc hl
    inc [hl]
.nc:
    ld a, [wIdle + 1]
    cp IDLE_HI                  ; IDLE_HI * 256 frames of idling starts the demo
    ret c
    jp StartDemo
.go:
    ldh a, [rDIV]
    ld hl, wRng
    xor [hl]
    ld [hl], a
    ld a, [wFrame]
    ld hl, wRng + 1
    xor [hl]
    ld [hl], a
    xor a
    ld [wDemo], a
    call FadeOut
    jp StartGame

StateWaveMsg:
    call PlayerUpdate
    call UpdateBullets
    ld hl, wTimer
    ld a, [hl]
    sub 1
    ld [hl], a
    inc hl
    ld a, [hl]
    sbc 0
    ld [hl], a
    ld hl, wTimer
    ld a, [hli]
    or [hl]
    ret nz
    ld a, ST_PLAY
    ld [wState], a
    ret

StatePlay:
    call PlayerUpdate
    call UpdateBullets
    call UpdateAliens
    call UpdateInits
    call UpdateBombs
    call RandomBombs
    call CollideBullets
    call CollidePlayer
    ld a, [wState]
    cp ST_PLAY
    ret nz
    jp WaveControl

StatePDead:
    call UpdateBullets
    call UpdateAliens
    ld a, [wPExpT]
    inc a
    ld [wPExpT], a
    ld b, %00011011
    cp 12
    jr nc, .fl
    and 2
    jr z, .fl
    ld b, %00011001             ; brief background flash on death
.fl:
    ld a, b
    ldh [rBGP], a
    ld a, [wPExpT]
    and 3
    jr nz, .s
    ld a, [wPExp]
    cp 6
    jr nc, .s
    inc a
    ld [wPExp], a
.s: ld a, [wPExp]
    cp 6
    ret c
    call AliensClear
    ret nz
    ld hl, wTimer
    inc [hl]
    ld a, [hl]
    cp 40
    ret c
    ld a, [wLives]
    or a
    jr z, .over
    dec a
    ld [wLives], a
    jr nz, .more
    ld a, SFX_LAST
    call Sfx
.more:
    ld hl, wWaveOff
    dec [hl]                    ; replay the pattern that was in progress
    call PlayerReset
    ld a, ST_WAVEMSG
    ld [wState], a
    ld a, 90
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ret
.over:
    ld a, [wDemo]
    or a
    call z, SaveHi
    ld a, ST_GAMEOVER
    ld [wState], a
    ld a, LOW(240)
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, MUS_OVER
    jp MusicPlay

StateGameOver:
    ld a, [wKeysNew]
    and PAD_START
    jr nz, .done
    ld hl, wTimer
    dec [hl]
    ret nz
    call MusicBusy              ; let the game-over tune finish, as the original does
    jr z, .done
    ld hl, wTimer
    ld [hl], 1
    ret
.done:
    jp ReturnToTitle

; ---------------------------------------------------------------- start / reset
StartGame:
    di
    call LcdOff
    call BuildGameMap
    ld hl, wScore
    ld bc, 7
    xor a
    call MemFill
    ld a, 3
    ld [wLives], a
    xor a
    ld [wWave], a
    ld [wExtra], a
    ld [wPause], a
    ld a, 1
    ld [wWaveOff], a
    call LoadWavePtr
    call ClearField
    call PlayerReset
    ld a, 1
    ldh [hSplit], a
    xor a
    ldh [hStarY], a
    ld a, ST_WAVEMSG
    ld [wState], a
    ld a, LOW(150)
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, LCDC_TOP
    ldh [rLCDC], a
    xor a
    ldh [rIF], a
    ei
    ld a, 3
    ld [wFade], a
    call ApplyPalettes
    ld a, MUS_START
    call MusicPlay
    jp FadeIn

PlayerReset:
    ld a, 76
    ld [wPX], a
    ld a, 110
    ld [wPY], a
    ld a, 1
    ld [wPAlive], a
    xor a
    ld [wPExp], a
    ld [wPExpT], a
    ld [wFireCD], a
    ld [wTimer], a
    ld hl, wBul
    ld bc, 12
    jp MemFill

ClearField:
    ld hl, wAliens
    ld bc, 16 * MAXAL
    xor a
    call MemFill
    ld hl, wInits
    ld bc, 16 * MAXINIT
    xor a
    call MemFill
    ld hl, wBomb
    ld bc, 24
    xor a
    call MemFill
    ld hl, wBul
    ld bc, 12
    xor a
    jp MemFill

LoadWavePtr:
    ld a, [wWave]
    and 15
    add a
    ld e, a
    ld d, 0
    ld hl, wave_ptrs
    add hl, de
    ld a, [hli]
    ld [wWavePtr], a
    ld a, [hl]
    ld [wWavePtr + 1], a
    ret

; ---------------------------------------------------------------- wave flow
; Z set when no alien slot is in use
AliensClear:
    ld hl, wAliens
    ld b, MAXAL
    ld de, 16
.l: ld a, [hl]
    or a
    ret nz
    add hl, de
    dec b
    jr nz, .l
    xor a
    ret

WaveControl:
    call AliensClear
    ret nz
    ld hl, wInits
    ld b, MAXINIT
    ld de, 16
.i: ld a, [hl]
    or a
    ret nz
    add hl, de
    dec b
    jr nz, .i
    ld hl, wBomb
    ld b, 6
.b: ld a, [hl]
    or a
    ret nz
    inc hl
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .b
    ld a, [wWavePtr]
    ld l, a
    ld a, [wWavePtr + 1]
    ld h, a
    ld a, [wWaveOff]
    ld e, a
    ld d, 0
    add hl, de
    ld a, [hl]
    cp $FF
    jr z, .end
    ld hl, wWaveOff
    inc [hl]
    jp StartPattern
.end:
    ld hl, wWave
    inc [hl]
    ld a, 1
    ld [wWaveOff], a
    call LoadWavePtr
    ld a, ST_WAVEMSG
    ld [wState], a
    ld a, LOW(150)
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, [wWave]
    and 15
    ld a, MUS_BETW
    jr nz, .m
    ld a, MUS_ZONE
.m: jp MusicPlay

; ---------------------------------------------------------------- collisions
AlienHit:                       ; c = alien slot
    push bc
    ld h, HIGH(wAliens)
    ld a, c
    or AL_HITS
    ld l, a
    dec [hl]
    jr z, .dead
    ld a, SFX_HIT
    call Sfx
    pop bc
    ret
.dead:
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    ld e, a
    ld d, 0
    ld hl, alien_score
    add hl, de
    ld a, [hl]
    call AddScore
    ld h, HIGH(wAliens)
    ld l, c
    ld a, $81
    ld [hl], a
    ld a, c
    or AL_FRAME
    ld l, a
    xor a
    ld [hl], a
    ld a, c
    or AL_TMR
    ld l, a
    xor a
    ld [hl], a
    ld a, SFX_BOOM
    call Sfx
    pop bc
    ret

CollideBullets:
    ld b, 0
.bl:
    ld hl, wBul
    ld e, b
    ld d, 0
    add hl, de
    ld a, [hl]
    or a
    jr z, .bn
    inc hl
    ld a, [hli]
    ld [wTmp], a                ; bullet x
    ld a, [hl]
    ld [wTmp + 1], a            ; bullet y
    ld c, 0
.al:
    ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80
    jr nz, .an
    inc l
    ld a, [wTmp]
    sub [hl]
    add 2
    cp 13
    jr nc, .an
    inc l
    ld a, [hl]
    call FieldY
    ld d, a
    ld a, [wTmp + 1]
    sub d
    add 5
    cp 19
    jr nc, .an
    call AlienHit
    ld hl, wBul
    ld e, b
    ld d, 0
    add hl, de
    xor a
    ld [hl], a
    jr .bn
.an:
    ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .al
.bn:
    ld a, b
    add 4
    ld b, a
    cp 12
    jr c, .bl
    ret

CollidePlayer:
IF DEF(GOD)
    ret
ENDC
    ld a, [wDemo]
    or a
    ret nz                      ; the demo ship is invulnerable
    ld a, [wPAlive]
    or a
    ret z
    ld a, [wPX]
    ld d, a
    ld a, [wPY]
    ld e, a
    ld c, 0
.l: ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80
    jr nz, .n
    inc l
    ld a, d
    sub [hl]
    add 9
    cp 19
    jr nc, .n
    inc l
    ld a, [hl]
    call FieldY
    ld b, a
    ld a, e
    sub b
    add 10
    cp 21
    jr nc, .n
    jp PlayerDie
.n: ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .l
    ld hl, wBomb
    ld b, 6
.bl:
    ld a, [hli]
    or a
    jr z, .skip3
    ld a, [hli]
    ld c, a
    ld a, [hli]
    sub e
    add 2
    cp 15
    jr nc, .skip1
    ld a, c
    sub d
    inc a
    cp 11
    jr nc, .skip1
    jp PlayerDie
.skip3:
    inc hl
    inc hl
.skip1:
    inc hl
    dec b
    jr nz, .bl
    ret

PlayerDie:
    xor a
    ld [wPAlive], a
    ld [wPExp], a
    ld [wPExpT], a
    ld [wTimer], a
    ld a, ST_PDEAD
    ld [wState], a
    ld c, 0
.l: ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80
    jr nz, .n
    ld a, $81
    ld [hl], a
    ld a, c
    or AL_FRAME
    ld l, a
    xor a
    ld [hl], a
    ld a, c
    or AL_TMR
    ld l, a
    xor a
    ld [hl], a
.n: ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .l
    ld hl, wInits
    ld bc, 16 * MAXINIT
    xor a
    call MemFill
    ld hl, wBomb
    ld bc, 24
    xor a
    call MemFill
    ld a, SFX_PDEATH
    jp Sfx

; ---------------------------------------------------------------- score
; AddScore: a = value (x10 points) added at the tens digit
AddScore:
    push bc
    call AddScoreInner
    pop bc
    ret

AddScoreInner:
    ld hl, wScore + 5
    add [hl]
.c: cp 10
    jr c, .done
    sub 10
    ld [hl], a
    dec hl
    ld a, [hl]
    inc a
    jr .c
.done:
    ld [hl], a
    ; hi-score
    ld hl, wScore
    ld de, wHi
    ld b, 7
.cmp:
    ld a, [de]
    ld c, a
    ld a, [hli]
    cp c
    jr c, .extra
    jr nz, .copy
    inc de
    dec b
    jr nz, .cmp
    jr .extra
.copy:
    ld hl, wScore
    ld de, wHi
    ld bc, 7
    call MemCopy
.extra:
    ld a, [wExtra]
    or a
    ret nz
    ld a, [wScore]
    ld b, a
    ld a, [wScore + 1]
    or b
    jr nz, .give
    ld a, [wScore + 2]
    cp 2
    ret c
.give:
    ld a, 1
    ld [wExtra], a
    ld a, [wLives]
    cp 5
    jr nc, .nl
    inc a
    ld [wLives], a
.nl:
    ld a, SFX_1UP
    jp Sfx

InitHiScore:
    ld hl, wHi
    ld a, 3
    ld [wHi + 2], a
    ret
