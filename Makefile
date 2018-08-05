#Sources and top module
SRC := dmgplus.v dmg_lcd_ctl.v vram.v vidsampler.v
LPF := dmgplus.lpf
VERILOGTOP := dmgplus_top

#Compilation options
BUILD_DIR := build
IMPL_NAME := fpga_impl
SYNTYPE := synplify

#Select part
PART_FAM := MachXO3LF
PART_TYPE := LCMXO3LF-6900C
PART_PACKAGE := CABGA256
PART_SPEED := 5
PART_GRADE := Commercial

CURRENT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
VERILOGSEARCHPATH="$(DIAMOND_DIR)/ispfpga/xo3c00/data"  "$(CURRENT_DIR)/fpga_impl" "$(CURRENT_DIR)"
MAP_OPTS=-a "$(PART_FAM)" -p $(PART_TYPE) -t $(PART_PACKAGE) -s $(PART_SPEED) -oc $(PART_GRADE)
PAR_OPTS=-w -l 5 -i 6 -n 1 -t 1 -s 1 -c 0 -e 0 -exp parUseNBR=1:parCDP=0:parCDR=0:parPathBased=OFF

SYN_OPTS=-a ${PART_FAM} -d ${PART_TYPE} -t ${PART_PACKAGE} -s ${PART_SPEED} -oc ${PART_GRADE} -frequency 200 -optimization_goal Balanced \
	-bram_utilization 100 -ramstyle Auto -romstyle auto -dsp_utilization 100 -use_dsp 1 \
	-use_carry_chain 1 -carry_chain_length 0 -force_gsr Auto -resource_sharing 1 -propagate_constants 1 \
	-remove_duplicate_regs 1 -mux_style Auto -max_fanout 1000 -fsm_encoding_style Auto -twr_paths 3 \
	-fix_gated_clocks 1 -loop_limit 1950 -use_io_insertion 1 -resolve_mixed_drivers 0 -use_io_reg auto \
	-lpf 1 -lib "work"

ifndef LSC_DIAMOND
$(error LSC_DIAMOND is not set. Please make sure diamond_env is sourced (source xenv file?))
endif
ifndef DIAMOND_DIR
$(error DIAMOND_DIR is not set. Please make sure it is set (source xenv file?))
endif


VERILOG_SRC:=$(addprefix $(CURRENT_DIR)/,$(SRC))
BUILD_DIR:=$(addprefix $(CURRENT_DIR)/,$(BUILD_DIR))
LPF:=$(addprefix $(CURRENT_DIR)/, $(LPF))

all: prog_sram

ifeq ($(SYNTYPE),diamond)
$(BUILD_DIR)/$(IMPL_NAME).ngd: $(SRC)
	cd $(BUILD_DIR) && synthesis $(SYN_OPTS) -ver $(VERILOG) -top $(VERILOGTOP) -p $(VERILOGSEARCHPATH) -ngd $@
else
$(BUILD_DIR)/$(IMPL_NAME)_synplify.tcl: $(VERILOG_SRC) Makefile
	./gensyntcl.sh -t $(VERILOGTOP) -f $(PART_FAM) -p $(PART_TYPE) -k $(PART_PACKAGE) -s $(PART_SPEED) -o $(BUILD_DIR)/$(IMPL_NAME).edif -l $(BUILD_DIR)/$(IMPL_NAME).log $(VERILOG_SRC) > $@

$(BUILD_DIR)/$(IMPL_NAME).edif: $(BUILD_DIR)/$(IMPL_NAME)_synplify.tcl
	cd $(BUILD_DIR) && synpwrap -msg -prj "$(BUILD_DIR)/$(IMPL_NAME)_synplify.tcl" -log "$(IMPL_NAME).srf" || ( cat $(IMPL_NAME).srr && false )

$(BUILD_DIR)/$(IMPL_NAME).ngo: $(BUILD_DIR)/$(IMPL_NAME).edif
	cd $(BUILD_DIR) && edif2ngd -l "$(PART_FAM)" -d $(PART_TYPE) -path "./$(IMPL_NAME)" -path "." "$(IMPL_NAME).edif" "$(IMPL_NAME).ngo"

$(BUILD_DIR)/$(IMPL_NAME).ngd: $(BUILD_DIR)/$(IMPL_NAME).ngo
	cd $(BUILD_DIR) && ngdbuild  -a "$(PART_FAM)" -d $(PART_TYPE)  $(VERILOGSEARCHPATH:%=-p %) \
		"$(IMPL_NAME).ngo" "$(IMPL_NAME).ngd"
endif

$(BUILD_DIR)/$(IMPL_NAME)_map.ncd: $(BUILD_DIR)/$(IMPL_NAME).ngd $(LPF)
	cd $(BUILD_DIR) && map $(MAP_OPTS) $(BUILD_DIR)/$(IMPL_NAME).ngd -o $(BUILD_DIR)/$(IMPL_NAME)_map.ncd -pr $(BUILD_DIR)/$(IMPL_NAME).prf \
		-mp $(BUILD_DIR)/$(IMPL_NAME).mrp -lpf $(LPF) -c 0

$(BUILD_DIR)/$(IMPL_NAME).ncd: $(BUILD_DIR)/$(IMPL_NAME)_map.ncd
	mkdir -p $(BUILD_DIR)/$(IMPL_NAME).dir
	par $(PAR_OPTS) $^ $(BUILD_DIR)/$(IMPL_NAME).dir $(BUILD_DIR)/$(IMPL_NAME).prf
	cp -f $(BUILD_DIR)/$(IMPL_NAME).dir/*.ncd $@

$(BUILD_DIR)/$(IMPL_NAME).prf: $(BUILD_DIR)/$(IMPL_NAME).ncd
	trce -v 10 -gt -sethld -sp 4 -sphld m -o $(BUILD_DIR)/$(IMPL_NAME).csv -pr $(BUILD_DIR)/$(IMPL_NAME).ncd

$(BUILD_DIR)/$(IMPL_NAME).jed: $(BUILD_DIR)/$(IMPL_NAME).ncd
	bitgen -jedec -g RamCfg:Reset -w $(BUILD_DIR)/$(IMPL_NAME).ncd $@ $(BUILD_DIR)/$(IMPL_NAME).prf

$(BUILD_DIR)/$(IMPL_NAME).bit: $(BUILD_DIR)/$(IMPL_NAME).ncd
	bitgen -f $(BUILD_DIR)/$(IMPL_NAME).t2b -w $(BUILD_DIR)/$(IMPL_NAME).ncd $(BUILD_DIR)/$(IMPL_NAME).prf || true

#$(BUILD_DIR)/$(IMPL_NAME).svf: $(BUILD_DIR)/$(IMPL_NAME).jed
#	ddtcmd -oft -svfsingle -if $(BUILD_DIR)/$(IMPL_NAME).jed -dev $(PART_TYPE) -op "FLASH Erase,Program,Verify" -of $(BUILD_DIR)/$(IMPL_NAME).svf
#
#program: $(BUILD_DIR)/$(IMPL_NAME).svf
#	jtag urjtag.cmd

prog_sram: $(BUILD_DIR)/$(IMPL_NAME).bit
	pgrcmd -TCK 0 -infile prog_sram.xcf

program: $(BUILD_DIR)/$(IMPL_NAME).bit
	b=$$(stat --printf=%s $(BUILD_DIR)/$(IMPL_NAME).bit); sed 's/<DataSize>[0-9]*</<DataSize>'$${b}'</' -i programmer.xcf
	pgrcmd -TCK 0 -infile programmer.xcf

clean:
	rm -rf $(BUILD_DIR)/*

vram.v:
	scuba -w -n vram -lang verilog -synth synplify -bus_exp 7 -bb -arch xo3c00f -type ramdps -device $(PART_TYPE) -raddr_width 16 -rwidth 2 -waddr_width 16 -wwidth 2 -rnum_words 65536 -wnum_words 65536 -cascade -1 -mem_init0


.PHONY: clean program