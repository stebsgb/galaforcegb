SECTION "game", ROM0

GameUpdate:
    ld a, [wState]
    or a
    jp z, StateTitle
    cp ST_OPTIONS
    jp z, StateOptions
    cp ST_SECRET
    jp z, StateSecret
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
    ld a, [wFrame]
    and 1
    jr nz, .nos
    ldh a, [hStarY]
    dec a
    ldh [hStarY], a
.nos:
    call TitleMenuKeys
    ld a, [wKeysNew]
    or a
    jr z, .idle
    xor a
    ld [wIdle], a
    ld [wIdle + 1], a
    ld a, [wKeysNew]
    and PAD_START | PAD_A
    jr nz, .pick
.idle:
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
.pick:
    ld a, [wMenuSel]
    or a
    jr z, .go
    call FadeOut
    jp ShowOptions
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
    ld a, [wLastSfx]            ; last life pending: wait until the Lost a Life tune has finished
    or a
    jr z, .nosfx
    call MusicBusy              ; Z once every channel has ended
    jr nz, .nosfx
    xor a
    ld [wLastSfx], a
    ld a, SFX_LAST
    call Sfx
.nosfx:
    ld a, [wLastSfx]
    or a
    ret nz                      ; hold the wave message (timer frozen) until the last-life sound has played
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
    ; smart-bomb screen flash: alternate the background palette like the life-lost flash
    ld a, [wBombFlash]
    or a
    jr z, .noflash
    dec a
    ld [wBombFlash], a
    ld a, [wOptBg]
    or a
    ld b, %00011011                 ; black background, normal
    ld c, %00011001                 ; black background, flash
    jr z, .flpal
    ld b, %11100100                 ; white background, normal
    ld c, %11100110                 ; white background, flash
.flpal:
    ld a, [wBombFlash]
    and 2
    jr z, .flset
    ld b, c
.flset:
    ld a, b
    ldh [rBGP], a
    jr .afterflash
.noflash:
    ld a, [wOptBg]
    or a
    ld a, %00011011
    jr z, .restore
    ld a, %11100100
.restore:
    ldh [rBGP], a
.afterflash:
    ; Smart bomb: SELECT, or A and B pressed together this frame. Hits every live alien.
    ld a, [wKeysNew]
    ld b, a
    and PAD_SELECT
    jr nz, .bombkey
    ld a, b
    and PAD_A | PAD_B
    cp PAD_A | PAD_B                ; A alone or B alone does not trigger it
    jr nz, .nobomb
.bombkey:
    call UseBomb
.nobomb:
    ld a, [wPX]
    ld hl, wLastPX
    cp [hl]
    ld [hl], a
    ld hl, wStill
    jr z, .still
    ld [hl], 0
    jr .idled
.still:
    ld a, [hl]
    inc a
    jr z, .idled                ; saturate at 255 frames
    ld [hl], a
.idled:
    ld a, [wHfxT]                   ; boss hit explosion: count up to its length
    ld b, a
    ld a, [wHfxN]
    cp b
    jr z, .nohfx
    inc b
    ld a, b
    ld [wHfxT], a
.nohfx:
    call BossAuto
    call UpdateBullets
    call UpdateAliens
    call UpdateInits
    call UpdateBombs
    call RandomBombs
    call AimedBomb
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
    ld d, a
    ld a, [wOptBg]
    or a
    ld b, %00011011
    ld c, %00011001
    jr z, .m
    ld b, %11100100
    ld c, %11100110
.m: ld a, d
    cp 12
    jr nc, .fl
    and 2
    jr z, .fl
    ld b, c                     ; brief background flash on death
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
    jr z, .out
    dec a
    ld [wLives], a
    jr nz, .more
    ld a, 1                     ; last life: play SFX_LAST once the Lost a Life tune has finished
    ld [wLastSfx], a
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
.out:
    ld a, [wConts]
    or a
    jr z, .over
    ld a, 1                     ; ask CONTINUE? on the game-over screen
    ld [wAsk], a
    xor a
    ld [wContSel], a
    ld a, ST_GAMEOVER
    ld [wState], a
    ret
.over:
    xor a
    ld [wAsk], a
    ld a, [wDemo]
    or a
    jr nz, .nohi
    ld a, [wHiOK]               ; hi-score only if no continue was used this game
    or a
    call nz, SaveHi
.nohi:
    ld a, ST_GAMEOVER
    ld [wState], a
    ld a, LOW(240)
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, MUS_OVER
    jp MusicPlay

StateGameOver:
    ld a, [wAsk]
    or a
    jr z, .go
    ld a, [wKeysNew]
    ld b, a
    and PAD_LEFT | PAD_RIGHT | PAD_UP | PAD_DOWN
    jr z, .nt
    ld hl, wContSel
    ld a, [hl]
    xor 1
    ld [hl], a
.nt:
    ld a, b
    and PAD_START | PAD_A
    ret z
    ld a, [wContSel]
    or a
    jr nz, .no
    xor a
    ld [wHiOK], a               ; a continue was used: this game cannot record a hi-score
    ld hl, wConts               ; yes: refill the lives and replay this wave
    dec [hl]
    ld a, [wOptLives]           ; the option is total lives; wLives counts spares (the ship in play is extra)
    dec a
    ld [wLives], a
    xor a
    ld [wAsk], a
    ld hl, wWaveOff
    dec [hl]
    ld a, [wBombs]                  ; a continue starts with one smart bomb if none are held
    or a
    jr nz, .hasbomb
    inc a
    ld [wBombs], a
.hasbomb:
    call PlayerReset
    ld a, ST_WAVEMSG
    ld [wState], a
    ld a, 90
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, SFX_1UP
    jp Sfx
.no:
    xor a
    ld [wConts], a
    ld [wAsk], a
    ld a, [wDemo]
    or a
    jr nz, .nohi2
    ld a, [wHiOK]               ; hi-score only if no continue was used this game
    or a
    call nz, SaveHi
.nohi2:
    ld a, LOW(240)
    ld [wTimer], a
    xor a
    ld [wTimer + 1], a
    ld a, MUS_OVER
    jp MusicPlay
.go:
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
    ld a, [wOptLives]
    dec a                           ; option = total lives; wLives = spares (the ship in play is extra)
    ld [wLives], a
    ld a, 1
    ld [wBombs], a                  ; a new game starts with one smart bomb (more come only from killing the boss)
    xor a
    ld [wWave], a
    ld a, [wDemo]
    or a
    jr nz, .w0
IF DEF(BOSSTEST)
    ld a, 4                     ; temp boss build: start on ZONE 04 (wave 3, boss pattern 45)
    ld [wStartLvl], a
ENDC
    ld a, [wStartLvl]
    dec a
    ld [wWave], a
    xor a
    ld [wMultFlash], a
    call ResetWaveStats
.w0:
    xor a
    ld [wExtra], a
    ld [wPause], a
    ld a, 1
    ld [wWaveOff], a
    xor a
    ld [wAsk], a
    ld [wContSel], a
    ld a, [wStartLvl]           ; a fresh game may record a hi-score until a continue is taken...
    cp 2
    jr c, .hiok                 ; ...but only when starting on ZONE 01 (no cheat level select)
    xor a
    jr .sethi
.hiok:
    ld a, 1
.sethi:
    ld [wHiOK], a
    ld a, [wDemo]
    or a
    ld a, 0
    jr nz, .nc
    ld a, [wOptCont]
.nc:
    ld [wConts], a
    call LoadWavePtr
    call ClearField
    call PlayerReset
    ld a, 1
    ldh [hSplit], a
    xor a
    ldh [hTitle], a
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
    ld a, MUS_START                 ; a real game plays the start tune (the demo is silenced in MusicPlay)
    call MusicPlay
    jp FadeIn

PlayerReset:
    xor a
    ld [wStill], a
    ld [wHfxT], a                   ; no boss hit explosion at the start of a life
    ld [wHfxN], a
    ; smart bombs are kept across lost lives: only a boss kill adds one (max 2)
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
    call SetBossHits
    ret

SetBossHits:
    ld a, [wWave]
    and 15
    cp 3
    jr z, .firstBoss
    ld a, 25
    jr .store
.firstBoss:
    ld a, 20
.store:
    ld [wBossHits], a
    ret
ResetWaveStats:
    xor a
    ld [wWaveKills], a
    ld [wWaveKills+1], a
    ld [wWaveTotalAliens], a
    ld [wWaveTotalAliens+1], a
    ld [wWavePoints], a
    ld [wWavePoints+1], a
    ; NOTE: wDebugMultiplier NOT cleared here so we can see it after wave end
    ; ld [wDebugMultiplier], a
    ret

ApplyWaveBonus:
    push bc
    push de
    push hl
    ; every pattern, including the boss pattern, is paid the standard wave multiplier
    ; load kills and total
    ld hl, wWaveKills
    ld a, [hli]
    ld e, a
    ld d, [hl] ; DE = kills
    ld hl, wWaveTotalAliens
    ld a, [hli]
    ld h, [hl]
    ld l, a ; HL = total aliens
    ; check total != 0
    ld a, h
    or l
    jr z, .done
    ; compare kills == total
    ld a, e
    sub l
    ld a, d
    sbc h
    jr nz, .not100
    ; 100% kills
    ld a, 5
    jr .apply
.not100:
    ; compute kills * 5 and total * 4
    ; kills * 5 = kills * 4 + kills
    push hl ; save total
    push de ; save kills
    ; DE * 4
    sla e
    rl d
    sla e
    rl d ; DE = kills * 4
    ; add original kills (still on stack)
    pop bc ; BC = original kills
    ld h, d
    ld l, e
    add hl, bc ; HL = kills * 5
    ; compute total * 4
    pop bc ; BC = total aliens
    sla c
    rl b
    sla c
    rl b ; BC = total * 4
    ; compare HL > BC (kills * 5 > total * 4)
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b
    ld h, a   ; HL = HL - BC
    jr c, .done ; HL < BC (less than 80%)
    ; HL >= 0
    ld a, h
    or l
    jr z, .done ; HL == 0 (exactly 80%, no bonus)
    ; HL > 0 (over 80%)
    ; >80%
    ld a, 2
.apply:
    ; a = multiplier (2 or 5)
    ld [wDebugMultiplier], a
    ld [wMultKind], a
    ld a, 120                       ; flash on the HUD for 120 frames
    ld [wMultFlash], a
    ; extra points = wWavePoints * (multiplier-1): x2 adds 1x, x5 adds 4x
    ld a, [wMultKind]
    cp 2
    jr z, .mult1
    ; multiplier 5: extra = wavePoints * 4
    ld hl, wWavePoints
    ld a, [hli]
    ld h, [hl]
    ld l, a ; HL = wavePoints
    add hl, hl ; *2
    add hl, hl ; *4
    jr .addExtra
.mult1:
    ld hl, wWavePoints
    ld a, [hli]
    ld h, [hl]
    ld l, a ; HL = wavePoints
.addExtra:
    ; HL = extraPoints (value x10)
    call AddScoreHL
.done:
    pop hl
    pop de
    pop bc
    ret

AddScoreHL:
    ; HL = value in score units (x10 points), may be > 9. Split it into decimal digits and add
    ; each digit at its own score column, so the score always stays valid BCD.
    ld a, h
    ld [wMultRem], a
    ld a, l
    ld [wMultRem + 1], a
    xor a
    ld [wTmp], a                    ; place index 0..4 (10000, 1000, 100, 10, 1)
.place:
    ld a, [wTmp]
    cp 5
    ret nc
    add a                           ; word table offset
    ld e, a
    ld d, 0
    ld hl, decDivs
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]                      ; DE = divisor
    ld a, [wMultRem]
    ld h, a
    ld a, [wMultRem + 1]
    ld l, a                         ; HL = remainder
    ld b, 0                         ; b = digit
.sub:
    ld a, l
    sub e
    ld c, a
    ld a, h
    sbc d
    jr c, .subdone                  ; remainder < divisor
    ld h, a
    ld l, c
    inc b
    jr .sub
.subdone:
    ld a, h
    ld [wMultRem], a
    ld a, l
    ld [wMultRem + 1], a
    ld a, b
    or a
    jr z, .next
    ld c, a                         ; c = digit 1..9
    ld a, [wTmp]
    inc a                           ; score column: place 0 (10000 units) -> wScore+1 ... place 4 -> wScore+5
    ld b, a
    ld a, c
    call AddDigitCol
.next:
    ld a, [wTmp]
    inc a
    ld [wTmp], a
    jr .place

; AddDigitCol: a = digit 0-9, b = score byte index (0-6, wScore+b), BCD add with carry
AddDigitCol:
    push bc
    push de
    push hl
    ld c, a
    ld hl, wScore
    ld d, 0
    ld e, b
    add hl, de
    ld a, [hl]
    add c
.c:
    cp 10
    jr c, .store
    sub 10
    ld [hl], a
    dec hl
    ld a, [hl]
    inc a
    jr .c
.store:
    ld [hl], a
    pop hl
    pop de
    pop bc
    ret

decDivs: dw 10000, 1000, 100, 10, 1
; ---------------------------------------------------------------- wave flow
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
    ; pattern finished, more patterns follow in this zone: pay this pattern's bonus, then start a fresh count.
    ; The next pattern id is in A and must survive the calls (StartPattern reads A).
    push af
    call ApplyWaveBonus
    call ResetWaveStats
    pop af
    ld hl, wWaveOff
    inc [hl]
    jp StartPattern
.end:
    call ApplyWaveBonus
    ld hl, wWave
    inc [hl]
    call ResetWaveStats
    ld a, [wWave]               ; best wave reached since power-on (for the title flags)
    ld hl, wBest
    cp [hl]
    jr c, .nobest
    jr z, .nobest
    ld [hl], a
.nobest:
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
    call AddKillScore
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

; UseBomb: SELECT pressed in play. Uses one smart bomb if held and the ship is alive.
; Every live alien takes two hits; the boss (type 5) takes one. Dying aliens are skipped.
UseBomb:
    ld a, [wBombs]
    or a
    ret z
    ld a, [wPAlive]
    or a
    ret z
    ; no bomb while a tune is still playing (Z from MusicBusy = every channel has finished)
    ld a, [aPlay]
    or a
    jr z, .musicdone
    call MusicBusy
    ret nz
.musicdone:
    ld a, [wBombs]
    dec a
    ld [wBombs], a
    ld a, SFX_BOMB
    call Sfx
    ld a, 12
    ld [wBombFlash], a             ; screen flash for 12 frames, same length as the life-lost flash
    ld c, 0
.ub:
    ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80                          ; live alien only
    jr nz, .ubn
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5                            ; boss: one hit
    jr z, .ubboss
    call AlienHit                   ; first hit for every other alien
IF BOMB_HITS == 2                   ; original two-hit bomb: switch BOMB_HITS to 2 in main.asm to use it
    ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80                          ; only if the first hit did not kill it
    jr nz, .ubn
    call AlienHit
ENDC
    jr .ubn
.ubboss:
    call AlienHit
.ubn:
    ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .ub
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
    add 32
    cp 64
    jr c, .an                   ; entry/exit band (y < 32 or above the top): not hittable
    sub 32
    call FieldY
    bit 7, a
    jr nz, .an                  ; still above the top edge: not hittable (no phantom explosions in the corners)
    ld d, a
    ld a, [wTmp + 1]
    sub d
    add 5
    cp 19
    jr nc, .an
    ld h, HIGH(wAliens)             ; boss hit: cosmetic explosion near the bullet (the 20-hit count is unchanged)
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    call z, BossHitFx
    ld h, HIGH(wAliens)
    ld l, c
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

; BossHitFx: called on a bullet hit on the boss. c = boss slot, wTmp = bullet x, wTmp+1 = bullet y.
; Plays the kill explosion sound and starts an explosion at a random offset of -4..+3 px from the hit.
; Every boss hit uses the standard kill animation (24 ticks, 6 frames). Preserves bc.
BossHitFx:
    push bc
    ld a, SFX_BOOM
    call Sfx
    ld a, 24
    ld [wHfxN], a
    xor a
    ld [wHfxT], a
    call Rand
    and 7
    add 252                         ; -4
    ld hl, wTmp
    add [hl]
    ld [wHfxX], a
    call Rand
    and 7
    add 252
    ld hl, wTmp + 1
    add [hl]
    ld [wHfxY], a
    pop bc
    ret

; BossAuto: while the boss has 5 or fewer hits left (absolute count, not percentage), keep one cosmetic explosion going on it.
; When the current one has finished, the next starts at a random spot over the boss (one at a time).
; Works for both 20-hit first boss and 25-hit later bosses.
BossAuto:
    ld c, 0
.l: ld h, HIGH(wAliens)
    ld l, c
    ld a, [hl]
    cp $80
    jr nz, .n
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr z, .found
.n: ld a, c
    add 16
    ld c, a
    cp MAXAL * 16
    jr c, .l
    ret
.found:
    ld h, HIGH(wAliens)
    ld a, c
    or AL_HITS
    ld l, a
    ld a, [hl]                      ; hits left
    cp 6
    ret nc                          ; more than 5 left: only the hit explosions
    ld a, [wHfxT]
    ld b, a
    ld a, [wHfxN]
    cp b
    ret nz                          ; the current explosion is still playing
    call Rand
    and 15
    add 252                         ; -4..+11 px
    ld d, a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_X
    ld l, a
    ld a, [hl]
    add d
    ld [wHfxX], a
    call Rand
    and 15
    add 252
    ld d, a
    ld h, HIGH(wAliens)
    ld a, c
    or AL_Y
    ld l, a
    ld a, [hl]
    call FieldY
    add d
    ld [wHfxY], a
    xor a
    ld [wHfxT], a
    ld a, 24
    ld [wHfxN], a
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
    ld [wHfxT], a                   ; no boss hit explosion survives a death
    ld [wHfxN], a
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
    ld a, SFX_PDEATH                ; the explosion starts first...
    call Sfx
    ld a, [wLives]                  ; fatal hit (no lives left) with no continues: straight to GAME OVER
    or a
    jr nz, .tune
    ld a, [wConts]
    or a
    ret z                           ; game over: no Lost a Life tune, MUS_OVER starts at .over
.tune:
    ld a, MUS_LOST                  ; ...then Lost a Life (as in INIT.asm die_loop) cuts it off
    jp MusicPlay

; ---------------------------------------------------------------- score
; AddScore: a = value (x10 points) added at the tens digit
AddScore:
    push bc
    call AddScoreInner
    pop bc
    ret
AddKillScore: ; e = alien type
    push bc
    push hl
    push de
    ; load base score
    ld hl, alien_score
    ld d, 0
    add hl, de
    ld a, [hl]
    ; add base score to wave points (16-bit)
    ld c, a
    ld b, 0
    ld hl, wWavePoints
    ld a, [hl]
    add c
    ld [hli], a
    ld a, [hl]
    adc b
    ld [hl], a
    ; add base score to total score
    ld a, c
    call AddScore

    ; increment wave kills
    ld hl, wWaveKills
    inc [hl]
    jr nz, .nocarry
    inc hl
    inc [hl]
.nocarry:
    pop de
    pop hl
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
