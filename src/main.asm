; GALAFORCE for Game Boy (DMG) - port of Kevin Edwards' BBC Micro game
INCLUDE "hw.inc"
INCLUDE "gfx.inc"

DEF MAXAL EQU 14           ; alien slots (2 objects each)
DEF MAXINIT EQU 4
DEF ALSTEP EQU 1            ; OAM draw-order stride over alien slots
DEF ROTSTEP EQU 7           ; first-drawn slot advances by half the pool per frame: overflow alternates two halves at 30 Hz
DEF IDLE_HI EQU 3          ; title idle time before the demo: 768 frames (~13 s)
DEF DEMO_FRAMES_HI EQU 7   ; demo length: 1792 frames (~30 s)

; ---- field offsets of an alien slot (16 bytes) ----
DEF AL_ST    EQU 0         ; 0 free, $80 alive, $81 dying
DEF AL_X     EQU 1         ; pixel x 0..159 (wraps)
DEF AL_Y     EQU 2         ; original 8-bit y (field y = y>>1)
DEF AL_TYPE  EQU 3
DEF AL_FRAME EQU 4         ; explosion frame
DEF AL_HITS  EQU 5
DEF AL_PATL  EQU 6
DEF AL_PATH  EQU 7
DEF AL_OFF   EQU 8
DEF AL_STEPS EQU 9
DEF AL_DIR   EQU 10
DEF AL_LCNT  EQU 11
DEF AL_LSTART EQU 12
DEF AL_REFL  EQU 13
DEF AL_TMR   EQU 14

; ---- field offsets of a spawn record (16 bytes) ----
DEF IN_ACT   EQU 0
DEF IN_XU    EQU 1         ; x in original units (0..79)
DEF IN_Y     EQU 2
DEF IN_CNT   EQU 3
DEF IN_DELAY EQU 4
DEF IN_NUM   EQU 5
DEF IN_RELX  EQU 6
DEF IN_RELY  EQU 7
DEF IN_TYPE  EQU 8
DEF IN_PNUM  EQU 9         ; path id | $80 = mirrored

; ---- game states ----
DEF ST_TITLE    EQU 0
DEF ST_WAVEMSG  EQU 1
DEF ST_PLAY     EQU 2
DEF ST_PDEAD    EQU 3
DEF ST_GAMEOVER EQU 4
DEF ST_OPTIONS  EQU 5

; ---- sound effect ids ----
DEF SFX_FIRE    EQU 0
DEF SFX_BOOM    EQU 1
DEF SFX_PDEATH  EQU 2
DEF SFX_1UP     EQU 3
DEF SFX_HIT     EQU 4
DEF SFX_LAST    EQU 5

; ---- music ids ----
DEF MUS_START   EQU 0
DEF MUS_BETW    EQU 1
DEF MUS_LOST    EQU 2
DEF MUS_OVER    EQU 3
DEF MUS_ZONE    EQU 4
DEF MUS_DEMO    EQU 5

DEF PX_MAX EQU 144
DEF PY_MIN EQU 82
DEF PY_MAX EQU 112

; font charmap: text strings become BG tile numbers
NEWCHARMAP gfchars
SETCHARMAP gfchars
DEF FONTSTR EQUS " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-.:!'/?,=<>"
FOR i, CHARLEN("{FONTSTR}")
  CHARMAP STRSLICE("{FONTSTR}", i, i + 1), T_FONT0 + i
ENDR

; ===================================================== RAM
SECTION "oam", WRAM0[$C000]
wOAM: ds 160

SECTION "aliensram", WRAM0, ALIGN[8]
wAliens: ds 16 * MAXAL

SECTION "initsram", WRAM0, ALIGN[8]
wInits: ds 16 * MAXINIT

SECTION "vars", WRAM0
wKeys:      db
wKeysNew:   db
wRng:       dw
wFrame:     db
wState:     db
wTimer:     dw
wOamLo:     db
wScore:     ds 7
wHi:        ds 7
wLives:     db
wWave:      db
wExtra:     db
wPX:        db
wPY:        db
wPAlive:    db
wPExp:      db
wPExpT:     db
wStill:     db
wLastPX:    db
wFireCD:    db
wBul:       ds 12          ; 3 x (active, x, y, -)
wBomb:      ds 24          ; 6 x (kind 0/1 slow/2 fast, x, y, -)
wWavePtr:   dw
wWaveOff:   db
wTmp:       ds 8
wRot:       db
wPause:     db
wMusic:     ds 16
wFade:      db            ; 0 normal .. 3 black
wDemo:      db            ; 1 while the attract-mode demo runs
wIdle:      dw            ; title idle frames
wDemoT:     dw            ; demo frames
wHiBak:     ds 7          ; hi-score saved while the demo runs
wOptLives:  db            ; options: starting spare lives 1..5
wOptBg:     db            ; options: 0 black background, 1 white
wMenuSel:   db
wTwk:       dw            ; title logo shine cycle counter
wCheat:      db            ; 1 once the options cheat code has been entered
wCheatPos:  db
wStartLvl:  db            ; cheat: starting level 1..16
wOptCont:   db            ; options: continues per game 0..3
wConts:     db            ; continues left in this game
wAsk:       db            ; 1 while the game-over screen asks CONTINUE?
wContSel:   db            ; 0 = yes, 1 = no
wDirty:     db            ; menu needs its dynamic tiles redrawn in VBlank

SECTION "hram", HRAM
hDma:       ds 10
hVBlank:    db
hSplit:     db
hStarY:     db
hTitle:     db            ; 1 while the title screen (split star background) is shown
hSeg:       db            ; title split segment index

; ===================================================== vectors
SECTION "vec_vbl", ROM0[$40]
    jp VBlankISR
SECTION "vec_stat", ROM0[$48]
    jp StatISR

SECTION "entry", ROM0[$100]
    nop
    jp Start
    ds $150 - @, 0

SECTION "main", ROM0

VBlankISR:
    push af
    ld a, 1
    ldh [hVBlank], a
    ldh a, [hTitle]
    or a
    jr z, .game
    xor a
    ldh [hSeg], a
    ldh [rSCY], a
    ld a, LCDC_FULL
    ldh [rLCDC], a
    ld a, 7
    ldh [rLYC], a
    pop af
    reti
.game:
    ldh a, [hSplit]
    or a
    jr z, .full
    ld a, LCDC_TOP
    ldh [rLCDC], a
    ld a, 8
    ldh [rSCY], a
    ldh [rLYC], a
    pop af
    reti
.full:
    ld a, LCDC_FULL
    ldh [rLCDC], a
    xor a
    ldh [rSCY], a
    ld a, 200
    ldh [rLYC], a
    pop af
    reti

StatISR:
    push af
    ldh a, [hTitle]
    or a
    jp nz, TitleStat
    ldh a, [rLYC]
    cp 8
    jr nz, .bottom
    ldh a, [hStarY]
    ldh [rSCY], a
    ld a, LCDC_STAR
    ldh [rLCDC], a
    ld a, BOT_LINE
    ldh [rLYC], a
    pop af
    reti
.bottom:
    ld a, LCDC_BOT
    ldh [rLCDC], a
    pop af
    reti

DmaRoutine:
    ld a, HIGH(wOAM)
    ldh [rDMA], a
    ld a, 40
.w: dec a
    jr nz, .w
    ret
DmaRoutineEnd:

; ===================================================== boot
Start:
    di
    ld sp, $FFFE
    call LcdOff
    ; clear WRAM
    ld hl, $C000
    ld bc, $2000
    xor a
    call MemFill
    ; HRAM routine
    ld hl, DmaRoutine
    ld de, hDma
    ld bc, DmaRoutineEnd - DmaRoutine
    call MemCopy
    ; graphics
    ld hl, gfx_obj
    ld de, _VRAM
    ld bc, GFX_OBJ_SIZE
    call MemCopy
    ld hl, gfx_bg
    ld de, _VRAM_BG
    ld bc, GFX_BG_SIZE
    call MemCopy
    ; star map in $9C00 (16 rows, repeated)
    ld hl, starmap
    ld de, _SCRN1
    ld bc, 512
    call MemCopy
    ld hl, starmap
    ld de, _SCRN1 + 512
    ld bc, 512
    call MemCopy
    call ApplyPalettes
    ld a, BOT_LINE
    ldh [rWY], a
    ld a, 7
    ldh [rWX], a
    ld a, %01000000
    ldh [rSTAT], a
    ld a, $E1
    ld [wRng], a
    ld a, $AC
    ld [wRng + 1], a
    ld a, 3
    ld [wOptLives], a
    xor a
    ld [wCheat], a
    ld [wCheatPos], a
    ld [wAsk], a
    ld a, 1
    ld [wOptCont], a
    ld [wStartLvl], a
    ld a, 1                     ; white background by default
    ld [wOptBg], a
    call InitHiScore
    call LoadHi
    call LoadOptions
    call AudioInit
    xor a
    ldh [rIF], a
    ld a, %00000011
    ldh [rIE], a
    call ShowTitle

; ===================================================== main loop
MainLoop:
.wait:
    halt
    nop
    ldh a, [hVBlank]
    or a
    jr z, .wait
    xor a
    ldh [hVBlank], a
    call hDma
    call HudUpdate
    call MenuRefresh
    call TitleShine
    ld hl, wFrame
    inc [hl]
    call ReadKeys
    ld a, [wKeys]
    and $0F
    cp $0F
    jp z, Start                 ; A+B+Select+Start soft reset
    call DemoInput
    call AudioUpdate
    call GameUpdate
    call BuildOAM
    jr MainLoop

; ===================================================== utilities
LcdOff:
    ldh a, [rLCDC]
    bit 7, a
    ret z
.w: ldh a, [rLY]
    cp 144
    jr nz, .w
    xor a
    ldh [rLCDC], a
    ret

MemCopy:
    ld a, [hli]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, MemCopy
    ret

MemFill:                    ; hl = dest, bc = length, a = value
    ld d, a
.l: ld a, d
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .l
    ret

; Rand: returns A (clobbers flags only)
Rand:
    push bc
    push hl
    ld a, [wRng + 1]
    ld h, a
    ld a, [wRng]
    ld l, a
    ld b, 8
.l: srl h
    rr l
    jr nc, .n
    ld a, h
    xor $B4
    ld h, a
.n: dec b
    jr nz, .l
    ld a, l
    ld [wRng], a
    ld a, h
    ld [wRng + 1], a
    xor l
    pop hl
    pop bc
    ret

ReadKeys:
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    swap a
    ld b, a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0F
    or b
    ld b, a
    ld a, $30
    ldh [rP1], a
    ld a, [wKeys]
    xor b
    and b
    ld [wKeysNew], a
    ld a, b
    ld [wKeys], a
    ret

; PutObj: b=Y c=X d=tile e=attr -> appends to shadow OAM
PutObj:
    ld a, [wOamLo]
    cp 160
    ret nc
    ld l, a
    ld h, HIGH(wOAM)
    ld a, b
    ld [hli], a
    ld a, c
    ld [hli], a
    ld a, d
    ld [hli], a
    ld a, e
    ld [hli], a
    ld a, l
    ld [wOamLo], a
    ret

; Put16: 16x16 sprite from two 8x16 objects. b=Y c=X d=first tile e=attr
Put16:
    call PutObj
    ld a, c
    add 8
    ld c, a
    inc d
    inc d
    jp PutObj

INCLUDE "render.asm"
INCLUDE "player.asm"
INCLUDE "aliens.asm"
INCLUDE "bombs.asm"
INCLUDE "game.asm"
INCLUDE "hud.asm"
INCLUDE "screens.asm"
INCLUDE "audio.asm"
INCLUDE "save.asm"
INCLUDE "fx.asm"
INCLUDE "options.asm"
INCLUDE "data.inc"
