# RGBDS programs
RGBDS ?= 
ASM   ?= $(RGBDS)rgbasm
LINK  ?= $(RGBDS)rgblink
FIX   ?= $(RGBDS)rgbfix

# FLIPS location
FLIPS ?= tools/flips/flips

# ROM expansion, make sure we're using some particular MBC
FIX_ARGS ?= -m 1 -l 0x33 -s

# object files one subdirectory deep
objs := $(patsubst patches/%.asm, %.o, $(shell find patches -maxdepth 1 -type f -name "*.asm"))

all: tetris_msu1.bps

.PRECIOUS: %.gb

clean:
	rm -f *.o
	rm -f tetris_msu1.gb tetris_msu1.bps tetris_msu1.ips
	rm -f *.sym
	rm -f *.map

# build individual object files
%.o: patches/%.asm patches/msu1/_bootstrap.asm
	$(ASM) $(ASM_FLAGS) -o $@ $<

%.gb: $(objs)
	$(LINK) -m $*.map -n $*.sym -O baserom.gb -o $@ $^
	$(FIX) $(FIX_ARGS) -v $@

%.bps: %.gb
	$(FLIPS) --create --bps-delta baserom.gb $^ $@

%.ips: %.gb
	$(FLIPS) --create --ips baserom.gb $^ $@

patches/msu1/_bootstrap.asm: patches/msu1/snes/bootstrap.asm
# Build using Asar, set its location there
	$(MAKE) -C patches/msu1/
