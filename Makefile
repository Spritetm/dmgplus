# Project setup
PROJ      = dmgplus
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = tq144:4k
PCFFILE   = dmgplus.pcf

# Files
FILES = dmgplus.v ice40_pll.v dmg_lcd_ctl.v vram.v vidsampler.v startupscreen_gen.v cart_iface.v sndgen.v

.PHONY: all clean burn

all:
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	yosys -p "synth_ice40 -top dmgplus_top -blif $(BUILD)/$(PROJ).blif" $(FILES)
	# Place and route using arachne
	arachne-pnr -d $(DEVICE) -P $(FOOTPRINT) -o $(BUILD)/$(PROJ).asc -p $(PCFFILE) $(BUILD)/$(PROJ).blif
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

burn:
	iceprog $(BUILD)/$(PROJ).bin

spislave_testbench:
	iverilog -o spislave_testbench.vvp spislave_testbench.v spislave.v
	vvp spislave_testbench.vvp


clean:
	rm build/*
