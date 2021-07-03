SECTION "do pause", ROMX[$6524], BANK[1]

Pause:
	ld a, BANK(MSU1_Pause)	; 2
	ld hl, MSU1_Pause		; 3
	rst FarCall				; 1
	jr Pause_Continue
Unpause_Redirect:
	ld a, BANK(MSU1_Unpause); 2
	ld hl, MSU1_Unpause		; 3
	rst FarCall				; 1
	ret
	nop

Pause_Continue::

SECTION "do unpause", ROMX[$655d], BANK[1]

Unpause:
	call Unpause_Redirect
	jr $64e8
