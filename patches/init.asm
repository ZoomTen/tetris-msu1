INCLUDE "constants.asm"

SECTION "super gameboy startup", ROM0[$150]

Start:
	jp $20c

InitSGB:
	ldh [rWY], a
	ldh [rWX], a
	ldh [rTMA], a

	ld a, 1
	rst Bankswitch

	ld a, BANK(SGB_Init)
	ld hl, SGB_Init
	rst FarCall
	jp $2c4

SECTION "end init early", ROM0[$2be]

EndInit:
	jp InitSGB

SECTION "init msu1 after copyright", ROM0[$39b]

JumpToMSU1Init:
	jp InitMSU1

SECTION "init msu1 call", ROM0[$17]

InitMSU1:
	ld a, BANK(MSU1_Init)
	ld hl, MSU1_Init
	rst FarCall
; set title screen mode
	ld a, $35
	ldh [$FFE1], a
	ret
