# Project setup
PROJ      = dmgplus
BUILD     = ./build
DEVICE    = 8k
FOOTPRINT = tq144:4k
PCFFILE   = dmgplus.pcf

# Files
FILES = dmgplus.v ice40_pll.v dmg_lcd_ctl.v vram.v vidsampler.v startupscreen_gen.v cart_iface.v sndgen.v \
	spicart.v spislave.v dmgplus_splash.v

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

test:
	iverilog -o test.vvp $(FILES)

burn:
	iceprog $(BUILD)/$(PROJ).bin

spislave_testbench:
	iverilog -o spislave_testbench.vvp spislave_testbench.v spislave.v
	vvp spislave_testbench.vvp

cart_iface_testbench:
	iverilog -o cart_iface_testbench.vvp cart_iface_testbench.v cart_iface.v sb_io_model.v
	vvp cart_iface_testbench.vvp

spicart_testbench:
	iverilog -o spicart_testbench.vvp spicart_testbench.v spislave.v cart_iface.v sb_io_model.v spicart.v
	vvp spicart_testbench.vvp

dmgplus_splash_testbench:
	iverilog -o dmgplus_splash_testbench.vvp dmgplus_splash_testbench.v dmgplus_splash.v
	vvp dmgplus_splash_testbench.vvp

clean:
	rm build/*
