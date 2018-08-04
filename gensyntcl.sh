#!/bin/bash

FAM=MACHXO2
PART=LCMXO2_7000HE
PACKAGE=TG144C
SPEED=4
OUT=""
LOG=""
VERILOGTOP=

while [ -n "$1" ]; do
	if [ "$1" = "-f" ]; then
		FAM="$2"
		shift 2
	elif [ "$1" = "-p" ]; then
		PART="$2"
		shift 2
	elif [ "$1" = "-k" ]; then
		PACKAGE="$2"
		shift 2
	elif [ "$1" = "-s" ]; then
		SPEED="$2"
		shift 2
	elif [ "$1" = "-o" ]; then
		OUT="$2"
		shift 2
	elif [ "$1" = "-l" ]; then
		LOG="$2"
		shift 2
	elif [ "$1" = "-t" ]; then
		VERILOGTOP="$2"
		shift 2
	else
		break;
	fi
done

if [ -z "$LOG" ] || [ -z "$OUT" ]; then
	echo "Usage: $0 [-f family] [-p part] [-k package] [-s speed] -o out.edif -l log file1.v [file2.v [...]] > generated.tcl"
	exit 1
fi


cat  <<EOF
#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology $FAM
set_option -part $PART
set_option -package $PACKAGE
set_option -speed_grade -SPEED

#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog 2001 standard option
set_option -vlog_std v2001

#map options
set_option -frequency auto
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -disable_io_insertion false
set_option -retiming false; set_option -pipe true
set_option -force_gsr true
set_option -compiler_compatible 0
set_option -dup false
set_option -frequency 1
set_option -default_enum_encoding default

#simulation options


#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 1
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0


#-- add_file options
add_file -verilog {$DIAMOND_DIR/cae_library/synthesis/verilog/machxo2.v}
EOF

while [ -n "$1" ]; do
	echo 'add_file -verilog {'"$1"'}'
	shift
done

cat  << EOF
#-- top module name
set_option -top_module $VERILOGTOP

#-- set result format/file last
project -result_file {$OUT}

#-- error message log file
project -log_file {$LOG}

#-- set any command lines input by customer


#-- run Synplify with 'arrange HDL file'
#project -run hdl_info_gen -fileorder
project -run
EOF