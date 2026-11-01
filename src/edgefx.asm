SECTION "edgefx", ROMX, BANK[1]

; Edge (path-end) explosions. This code lives in ROM bank 1 to free space in bank 0.
; Bank 1 is selected at boot and the game never writes the MBC1 bank register ($2000-$3FFF),
; so a plain call from bank 0 reaches this code. Add bank switching only with a matching change here.
;
; EdgeExplode: c = alien slot offset that has just reached the end of its path (state $81 -> $83).
; Only one edge explosion is shown at a time: the previous one (wEdgeSlot) is removed first.
; Player-kill explosions ($81, set in game.asm) are not touched. Preserves c.
EdgeExplode:
    ld a, [wEdgeSlot]
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [hl]
    cp $83
    jr nz, .keep
    xor a
    ld [hl], a
.keep:
    ld a, c
    ld [wEdgeSlot], a
    ld l, c
    ld a, $83                   ; edge explosion: still dying (bit 0 set), so every dying check applies
    ld [hl], a
    ret

; KillCap: called from AlienHit just before slot c becomes a player-kill explosion ($81).
; At most KILL_CAP player-kill explosions are live. If the cap is already reached, the oldest
; one (largest AL_TMR, its age in frames) is removed now. The boss (type 5) is never capped or removed,
; and smart bomb kills (AL_BOMB set from wBombKill) are neither counted nor removed.
; Preserves c.
DEF KILL_CAP EQU 3

KillCap:                        ; wrapper: keeps bc, de and hl for the caller
    push bc
    push de
    push hl
    call KillCapBody
    pop hl
    pop de
    pop bc
    ret

; BombHit: c = alien slot. UseBomb calls this in place of AlienHit, so a kill made by the smart bomb is
; tagged as a bomb kill (wBombKill = 1) and is not counted or capped. Preserves bc (AlienHit does).
BombHit:
    ld a, 1
    ld [wBombKill], a
    call AlienHit
    xor a
    ld [wBombKill], a
    ret

; BombTagClear: c = slot of a player-death explosion ($81 set in PlayerDie). Tags it exempt (AL_BOMB = 1)
; so the death animation is not counted or capped, as before. Preserves c.
BombTagClear:
    ld a, c
    or AL_BOMB
    ld l, a
    ld h, HIGH(wAliens)
    ld a, 1
    ld [hl], a
    ret

KillCapBody:
    ld a, c
    or AL_BOMB
    ld l, a
    ld h, HIGH(wAliens)
    ld a, [wBombKill]
    ld [hl], a                  ; tag this kill: 1 = smart bomb kill (set by UseBomb), 0 = player kill
    or a
    ret nz                      ; smart bomb kill: not capped and not counted
    ld a, c
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    ret z                       ; the boss is not capped
    ld b, 0                     ; b = live non-boss kill explosions
    ld d, 0                     ; d = oldest age found
    ld e, 0
.c1:
    ld h, HIGH(wAliens)
    ld l, e
    ld a, [hl]
    cp $81
    jr nz, .c1n
    ld a, e
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr z, .c1n
    ld a, e
    or AL_BOMB
    ld l, a
    ld a, [hl]
    or a
    jr nz, .c1n                 ; smart bomb kill: not counted
    inc b
    ld a, e
    or AL_TMR
    ld l, a
    ld a, [hl]
    cp d
    jr c, .c1n
    ld d, a
.c1n:
    ld a, e
    add 16
    ld e, a
    cp MAXAL * 16
    jr c, .c1
    ld a, b
    cp KILL_CAP
    ret c                       ; below the cap: nothing to remove
    ld e, 0
.c2:
    ld h, HIGH(wAliens)
    ld l, e
    ld a, [hl]
    cp $81
    jr nz, .c2n
    ld a, e
    or AL_TYPE
    ld l, a
    ld a, [hl]
    cp 5
    jr z, .c2n
    ld a, e
    or AL_BOMB
    ld l, a
    ld a, [hl]
    or a
    jr nz, .c2n                 ; smart bomb kill: never removed by the cap
    ld a, e
    or AL_TMR
    ld l, a
    ld a, [hl]
    cp d
    jr nz, .c2n
    ld a, e
    or AL_ST
    ld l, a
    xor a
    ld [hl], a                  ; remove the oldest kill explosion
    ret
.c2n:
    ld a, e
    add 16
    ld e, a
    cp MAXAL * 16
    jr c, .c2
    ret
