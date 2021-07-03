SECTION "thunked stop music", ROMX[$7ff3], BANK[1]

StopMusic2:
	ld a, BANK(PATCH_StopMusic)
	ld hl, PATCH_StopMusic
	jp FarCall_hl
