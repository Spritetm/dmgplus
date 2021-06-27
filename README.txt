These are various files for the DMGPlus project. Note that I did this over the time span
of about three years, so there's no plug-and-play recipe to build your own available;
I'd need to reverse my own work to provide that. As such, these files are only provided
as a reference, to plunder if you want to build something similar. For more information
about the DMGPlus project, refer to https://spritesmods.com/?art=dmgplus

The various subdirectories:

* kicad-pcb
This contains the PCB layout. Look at dmgplus-schematic.pdf in that directory if you only want
to look at the schematic without opening Kicad.

* fpga
This contains the Verilog sources for the Ice40 FPGA configuration. You need a proper 
Yosys/nextpnr/icestorm setup to build this.

* linux
This contains the gpio-matrix patch I had to apply to get multiple buttonpresses to work, as
well as the config I use to get the kernel startup to be fast.

* devicetree
The Linux kernel requires a custom device tree to get sound output, DPI RGB on the correct 
pins, and the mapping for the GPIO keyboard matrix; this generates that. Note that you need 
a device tree compiler (e.g. Debian package device-tree-compiler) to build this.

* spi-flash-reader
This compiles and runs under Raspbian. It allows you to read a GameBoy cartridge through the 
Ice40 FPGA via the SPI port. It also allows you to write the reproduction cartridges that are 
around, if you happen to have a similar model to mine.

This directory also contains an initial_init.sh script, which acts as a replacement init
script. It checks the cart inserted and starts up whatever's applicable.

* gnuboy
This is Gnuboy, modified to use the same SPI cart reading method to execute from the actual
cart that is inserted in the DMGPlus unit.

* conv_startupscreen
This is a tool to generate the binary ROM images that can be flashed into a cartridge to 
create a DMGPlus cart. The tool takes a png image that is used as a startup screen, a 
delay, and a game name. The FPGA will display the startup screen for the indicated delay,
the Raspberry Pi can use the game name to start up whatever is required.


