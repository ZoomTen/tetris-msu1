SECTION "check new music", ROMX[$6a1d], BANK[1]

StopMusic:
	jp redir_StopMusic
	ret

CheckNewMusic:
	ld a, BANK(PATCH_CheckNewMusic)
	ld hl, PATCH_CheckNewMusic
	rst FarCall
	ret

redir_StopMusic:
	ld a, BANK(PATCH_StopMusic)
	ld hl, PATCH_StopMusic
	rst FarCall
	ret

redir_PlayMusic::
	ld a, b
	ld hl, $64b0
	and $1f
	call $697c
	call $6b13
	call $6a3c
	ret
