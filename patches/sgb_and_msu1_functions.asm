INCLUDE "constants.asm"
SECTION "bank 1", ROMX[$4000], BANK[2]

; we have to setup BOTH Super Game Boy AND MSU-1

; Taken from pokered
; hl = SGB packet to transfer
SendSGBPacket:
	ld a, [hl]
	and %00000111
	ret z

	ld b, a
.loop2
	push bc
	xor a
	ldh [rJOYP], a
	ld a, $30
	ldh [rJOYP], a
	ld b, $10
.nextByte
	ld e, $08
	ld a, [hli]
	ld d, a
.nextBit0
	bit 0, d
	ld a, $10
	jr nz, .next0
	ld a, $20
.next0
	ldh [rJOYP], a
	ld a, $30
	ldh [rJOYP], a
	rr d
	dec e
	jr nz, .nextBit0
	dec b
	jr nz, .nextByte
	ld a, $20
	ldh [rJOYP], a
	ld a, $30
	ldh [rJOYP], a
	call Wait7000
	pop bc
	dec b
	ret z
	jr .loop2

; waits about 7000 cycles before sending the next command
Wait7000:
	ld de, 7000/9
.loop
	nop
	nop
	nop
	dec de
	ld a, d
	or e
	jr nz, .loop
	ret

; checks and sets the Super Game Boy flag
; allows for GB / SGB music switching
SGB_Init::
	xor a
	ldh [hSGB], a
	call .TestSGB
	jr nc, .noSGB
	ld a, 1
	ldh [hSGB],a
	call .PushPalette
	call .PushBootstrap
.noSGB
	ret

; from pokegold
; Checks if SGB is present
.TestSGB:
	ld hl, MltReq2Packet
	call SendSGBPacket
	call Wait7000
	ldh a, [rJOYP]
	and %11
	cp %11
	jr nz, .has_sgb

	ld a, $20
	ldh [rJOYP], a
	ldh a, [rJOYP]
	ldh a, [rJOYP]
	call Wait7000
	call Wait7000
	ld a, $30
	ldh [rJOYP], a
	call Wait7000
	call Wait7000
	ld a, $10
	ldh [rJOYP], a
rept 6
	ldh a, [rJOYP]
endr
	call Wait7000
	call Wait7000
	ld a, $30
	ldh [rJOYP], a
	ldh a, [rJOYP]
	ldh a, [rJOYP]
	ldh a, [rJOYP]
	call Wait7000
	call Wait7000

	ldh a, [rJOYP]
	and %11
	cp %11
	jr nz, .has_sgb

	call .done
	and a
	ret

.has_sgb
	call .done
	scf
	ret

.done
	ld hl, MltReq1Packet
	call SendSGBPacket
	jp Wait7000

; push the MSU-1 bootstrap  code
.PushBootstrap:
	ld hl, Packets_bootstrap
	ld c, [hl]	; amount of packets to send
	inc hl
.push_bootstrap
	call SendSGBPacket
	dec c
	ret z
	jr .push_bootstrap

.PushPalette:
; manually push the predefined tetris palette
	ld hl, InitTetrisPalette
	jp SendSGBPacket

MSU1_Init::
	ld a, [hSGB]
	and a
	ret z
	ld hl, JumpToMSU1EntryPoint	; execute MSU1 init
	jp SendSGBPacket

MltReq1Packet: MLT_REQ 1
MltReq2Packet: MLT_REQ 2
JumpToMSU1EntryPoint:: JUMP $1810, 0, 0, 0

InitTetrisPalette:
	PAL01_def
	RGB 31, 26, 19
	RGB 14, 24, 24
	RGB 31, 12, 05
	RGB 06, 09, 12
rept 3
	RGB 00, 00, 00
endr
	db 0

; ----------- patched Tetris routines ------------------------------------------

PATCH_StopMusic::
	ld a, [hSGB]
	and a
	jr z, .non_sgb
	ld hl, StopMusicPacket
	jp SendSGBPacket
.non_sgb
	ld a, 1
	ld hl, $69a5
	rst FarCall
	ret

PATCH_CheckNewMusic::
; check if there should be new music to play
	ld hl, $dfe8
	ld a, [hli]
	and a
; done
	ret z
	cp -1
	jr z, PATCH_StopMusic

; set current music
	ld [hl], a

	push af
	ld a, [hSGB]
	and a
	jr z, .non_sgb
	pop af

	jp MSU1_EntryPoint

.non_sgb
	pop af
	ld b, a
	ld a, BANK(redir_PlayMusic)
	ld hl, redir_PlayMusic
	rst FarCall
	ret

; Run Gameboy music if not on SGB
	ld a, e
	jp $2643

MSU1_EntryPoint:
; @a = Music ID to play
	ld b, a
	ld c,  SGB_PACKET_SIZE
	ld hl, MSU1SoundTemplate
	ld de, wMSU1PacketSend
.copy_template
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .copy_template

; Insert the song ID into the packet template
	ld a, b
	ld [wMSU1PacketSend + 6], a

; There's only a few non-looping music, so
; we can handle the lack of LUTs
	cp 2
	jr z, .no_loop
	cp 3
	jr z, .no_loop
	cp 4
	jr z, .no_loop
	cp 9
	jr z, .no_loop
	cp 10
	jr z, .no_loop
	cp 11
	jr z, .no_loop
	cp 12
	jr z, .no_loop
	cp 13
	jr z, .no_loop
	cp 14
	jr z, .no_loop
	cp 15
	jr z, .no_loop

.okay
; Send over the packet from RAM
	ld hl, wMSU1PacketSend
	call SendSGBPacket
	ret

.no_loop
	ld a, 1
	ld [wMSU1PacketSend + 9], a
	jr .okay

MSU1SoundTemplate::
	DATA_SND $1800, $0, 5 ; 5 bytes
	db   1 ; restart flag
	dw   0 ; track number
	db $FF ; volume
	db   3 ; play mode
	ds 6,0 ; padding

StopMusicPacket::
	DATA_SND $1800, $0, 1
	db  %00100000
	ds 10, 0

PauseMusicPacket::
	DATA_SND $1800, $0, 1
	db  %00000100
	ds 10, 0

UnpauseMusicPacket::
	DATA_SND $1800, $0, 1
	db  %00001000
	ds 10, 0

INCLUDE "patches/msu1/_bootstrap.asm"

MSU1_Pause::
	ld a, [hSGB]
	and a
	jr z, .no_sgb

	ld hl, PauseMusicPacket
	call SendSGBPacket

; the pause also handles the GB SFX
.no_sgb
	ld a, 1
	ld hl, $69c7
	rst FarCall
	xor a
	ld [$dfe1], a
	ld [$dff1], a
	ld [$dff9], a
	ld hl, $dfbf
	ret

MSU1_Unpause::
	ld a, [hSGB]
	and a
	jr z, .no_sgb

	ld hl, UnpauseMusicPacket
	call SendSGBPacket

.no_sgb
	xor a
	ld [$df7e], a
	ld a, 1
	ld hl, $64e8
	jp FarCall_hl
