SECTION "render", ROM0

; Builds the shadow OAM for this frame.
; Order: messages, player, bullets, bombs, aliens (rotated start slot for fair flicker).
BuildOAM:
    ld hl, wOAM
    ld b, 40
    ld de, 4
    xor a
.clr:
    ld [hl], a
    add hl, de
    dec b
    jr nz, .clr
    ld [wOamLo], a

    ld a, [wState]
    or a
    ret z                       ; title: no objects
    cp ST_OPTIONS
    jp z, BuildOptionsOAM
    cp ST_SECRET
    jp z, DrawSecretFX              ; the secret screen: sparkles only (BG for the rest)
    call DrawMessages

    ; --- player / player explosion
    ld a, [wPY]
    add 24
    ld b, a
    ld a, [wPX]
    add 8
    ld c, a
    ld a, [wPAlive]
    or a
    jr z, .pdead
    ld d, SPR_PLAYER
    ld e, 0
    call Put16
    jr .bullets
.pdead:
    ld a, [wState]
    cp ST_PDEAD
    jr nz, .bullets
    ld a, [wPExp]
    cp 6
    jr nc, .bullets
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld e, 0
    call Put16

.bullets:
    ld hl, wBul
    ld a, 3
    ld [wTmp + 6], a
.bl:
    ld a, [hli]
    or a
    jr z, .bskip
    ld a, [hli]
    add 8
    ld c, a
    ld a, [hli]
    add 24
    ld b, a
    inc hl
    push hl
    ld d, SPR_BULLET
    ld e, 0
    call PutObj
    pop hl
    jr .bnext
.bskip:
    inc hl
    inc hl
    inc hl
.bnext:
    ld a, [wTmp + 6]
    dec a
    ld [wTmp + 6], a
    jr nz, .bl

    ld hl, wBomb
    ld a, 6
    ld [wTmp + 6], a
.ml:
    ld a, [hli]
    or a
    jr z, .mskip
    ld a, [hli]
    add 8
    ld c, a
    ld a, [hli]
    add 24
    ld b, a
    inc hl
    push hl
    ld d, SPR_BOMB
    ld e, 0
    call PutObj
    pop hl
    jr .mnext
.mskip:
    inc hl
    inc hl
    inc hl
.mnext:
    ld a, [wTmp + 6]
    dec a
    ld [wTmp + 6], a
    jr nz, .ml

    ; --- boss hit explosion (cosmetic): frame = wHfxT / 4 (0..5), hidden when wHfxT == wHfxN
    ld a, [wHfxT]
    ld b, a
    ld a, [wHfxN]
    cp b
    jr z, .nohfx
    ld a, b
    and $FC                         ; 4 tiles per frame, as the dying aliens
    add SPR_EXPL0
    ld d, a
    ld a, [wHfxY]                   ; same screen origin as the bullets (y+24, x+8)
    add 24
    ld b, a
    ld a, [wHfxX]
    add 8
    ld c, a
    ld e, 0
    call Put16
.nohfx:

    ; --- aliens
    ld a, [wRot]
    add ROTSTEP * 16
    cp MAXAL * 16
    jr c, .rot
    xor a
.rot:
    ld [wRot], a
    ld [wTmp + 1], a
    ld a, MAXAL
    ld [wTmp + 2], a
.al:
    ld a, [wTmp + 1]
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [hli]
    or a
    jr z, .alnext
    ld [wTmp + 3], a            ; state
    ld a, [hli]
    cp 8
    jr nc, .xn
    add a                       ; x < 8: slide in from behind the left edge instead of popping in
    jr .xs
.xn:
    add 8
.xs:
    ld c, a
    ld a, [hli]
    call FieldY
    bit 7, a
    jr nz, .alnext              ; above the top edge (waiting at y 255 etc.): not drawn, so nothing sits in the corners
    cp 8
    jr c, .alnext               ; paths that wrap off the top (hoop end) stay hidden until they die quietly
.yok:
    add 24
    ld b, a
    ld a, [hli]                 ; type
    ld d, a
    ld a, [wTmp + 3]
    bit 0, a
    jr nz, .dying
    ld a, d
    cp 10
    jr c, .art
    ld a, 9
.art:
    ld e, a
    ld hl, alien_pal
    ld d, 0
    add hl, de
    ld a, [hl]
    swap a
    ld [wTmp + 3], a
    ld a, e
    add a
    add a
    add SPR_ALIEN0
    ld d, a
    ld a, [wTmp + 3]
    ld e, a
    call Put16
    jr .alnext
.dying:
    ld a, d
    cp 5
    jr nz, .smalldie
    ld a, [wState]
    cp ST_PDEAD
    jr z, .smalldie
    call BossBoom
    jr .alnext
.smalldie:
    ld a, [hl]                  ; frame
    cp 6
    jr nc, .alnext
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld e, 0
    call Put16
.alnext:
    ld a, [wTmp + 1]
    add ALSTEP * 16
    jr c, .wrap
    cp MAXAL * 16
    jr c, .s
.wrap:
    sub MAXAL * 16
.s: ld [wTmp + 1], a
    ld hl, wTmp + 2
    dec [hl]
    jp nz, .al
    ret

; DrawText: hl = string (charmap bytes, 0-terminated), b = OAM Y, c = OAM X
DrawText:
.l: ld a, [hli]
    or a
    ret z
    cp T_FONT0
    jr z, .sp
    sub T_FONT0
    add a
    add T_OFONT0
    ld d, a
    ld e, 0
    push hl
    call PutObj
    pop hl
.sp:
    ld a, c
    add 8
    ld c, a
    jr .l

DrawMessages:
    ld a, [wState]
    cp ST_WAVEMSG
    jr z, .wave
    cp ST_GAMEOVER
    ret nz
    ld a, [wAsk]
    or a
    jr nz, .ask
    ld hl, txtGameOver
    ld b, 80
    ld c, 53
    jp DrawText
.ask:
    ld hl, txtContinue
    ld b, 72
    ld c, 48
    call DrawText
    ld hl, txtYesSel
    ld a, [wContSel]
    or a
    jr z, .y
    ld hl, txtYes
.y: ld b, 88
    ld c, 44
    call DrawText
    ld hl, txtNoSel
    ld a, [wContSel]
    or a
    jr nz, .n
    ld hl, txtNo
.n: ld b, 88
    ld c, 92
    jp DrawText
.wave:
    ld hl, txtEntering
    ld b, 72
    ld c, 56
    call DrawText
    ld hl, txtZone
    ld b, 88
    ld c, 60
    call DrawText               ; c = x after "ZONE "
    ld a, [wWave]
    inc a
    cp 100
    jr c, .ok
    ld a, 99
.ok:
    ld d, 0
.t: cp 10
    jr c, .u
    sub 10
    inc d
    jr .t
.u: ld e, a
    ld a, d
    inc a
    add a
    add T_OFONT0
    push de
    ld d, a
    ld e, 0
    call PutObj
    pop de
    ld a, c
    add 8
    ld c, a
.ones:
    ld a, e
    inc a
    add a
    add T_OFONT0
    ld d, a
    ld e, 0
    jp PutObj

txtEntering: db "ENTERING", 0
txtZone:     db "ZONE ", 0
txtGameOver: db "GAME OVER", 0
txtContinue: db "CONTINUE?", 0
txtYesSel:   db ">YES", 0
txtYes:      db " YES", 0
txtNoSel:    db ">NO", 0
txtNo:       db " NO", 0

; BossBoom: grand death of the boss. b = Y, c = X, hl = its AL_FRAME (0..35). A cluster of explosions
; with staggered phases bursts over and around it for 30 steps, then one big final blast (last 6 steps).
BossBoom:
    ld a, [hl]
    ld [wTmp + 4], a
    ld a, b
    ld [wTmp + 5], a
    ld a, c
    ld [wTmp + 6], a
    ld a, [wTmp + 4]
    cp 30
    jr c, .cluster
    sub 30                      ; final blast: one explosion over the boss position
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld e, 0
    jp Put16
.cluster:
    ld hl, bossBoomOfs
    ld a, 6
    ld [wTmp + 7], a
.l: ld a, [wTmp + 4]
    inc hl
    inc hl
    add [hl]                    ; + phase
    dec hl
    dec hl
    and 7
    cp 6
    jr nc, .skip
    add a
    add a
    add SPR_EXPL0
    ld d, a
    ld a, [wTmp + 5]
    add [hl]
    ld b, a
    inc hl
    ld a, [wTmp + 6]
    add [hl]
    ld c, a
    dec hl
    ld e, 0
    push hl
    call Put16
    pop hl
.skip:
    inc hl
    inc hl
    inc hl
    ld a, [wTmp + 7]
    dec a
    ld [wTmp + 7], a
    jr nz, .l
    ret

; dy, dx, phase
bossBoomOfs:
    db 0, 0, 0
    db -10, -14, 2
    db -10, 14, 4
    db 8, -14, 5
    db 8, 14, 1
    db 4, -4, 3
