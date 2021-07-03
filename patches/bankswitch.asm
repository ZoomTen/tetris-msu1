INCLUDE "constants.asm"

SECTION "bank 2 switch", ROM0[$38]

FarCall::
	jp FarCall_hl

SECTION "bank 1 switch", ROM0[$10]

Bankswitch::
	ldh [hROMBank], a
	ld [MBC1RomBank], a
	ret
